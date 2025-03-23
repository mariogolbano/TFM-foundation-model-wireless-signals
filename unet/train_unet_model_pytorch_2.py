import os
import glob
import sys
import matplotlib.pyplot as plt
import json
import torch
from torch.amp import autocast, GradScaler
import gc
import numpy as np
import h5py
from torch.utils.data import DataLoader, Dataset
from torch import nn, optim
from unet_model_pytorch_2 import UNet1D  # Asegúrate de que estás usando UNet1D
from torch.utils.data.dataset import random_split

# Configuración de dispositivos
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

scaler = GradScaler("cuda")  # 🔹 Inicializa el escalador de gradientes

# Dataset personalizado para leer los datos de HDF5
class HDF5Dataset(Dataset):
    def __init__(self, hdf5_file):
        with h5py.File(hdf5_file, 'r') as f:
            self.data = f['dataset'][:]
        self.data = torch.tensor(self.data, dtype=torch.float32)

    def __len__(self):
        return self.data.shape[0]

    def __getitem__(self, idx):
        signal = self.data[idx]
        target = signal.clone()  # Se asume que la señal objetivo es la misma
        return signal, target

# Función de entrenamiento
def train_model(model, dataloader, optimizer, criterion, device):
    model.train()
    total_loss = 0.0
    for inputs, targets in dataloader:
        torch.cuda.empty_cache()

        inputs, targets = inputs.to(device), targets.to(device)

        optimizer.zero_grad()
        with autocast("cuda"):  # 🔹 Habilita Mixed Precision
            outputs = model(inputs)
            loss = criterion(outputs, targets)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        total_loss += loss.item()
    return total_loss / len(dataloader)

# Función de validación
def validate_model(model, dataloader, criterion, device):
    model.eval()
    total_loss = 0.0
    with torch.no_grad():
        for inputs, targets in dataloader:
            inputs, targets = inputs.to(device), targets.to(device)

            outputs = model(inputs)
            loss = criterion(outputs, targets)
            total_loss += loss.item()
    return total_loss / len(dataloader)

# Entrenamiento con Early Stopping
def train_unet_pytorch(hdf5_file, output_dir, prev_model_path=None, batch_size=16, num_epochs=500, lr=0.0003, patience=10):
    
    # 🔹 Obtener memoria antes del entrenamiento
    mem_before_allocated = torch.cuda.memory_allocated(device) / 1e6
    mem_before_reserved = torch.cuda.memory_reserved(device) / 1e6

    # Crear dataset y dividirlo en entrenamiento/validación
    dataset = HDF5Dataset(hdf5_file)
    train_size = int(0.9 * len(dataset))
    val_size = len(dataset) - train_size
    train_dataset, val_dataset = random_split(dataset, [train_size, val_size])
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, num_workers=4)

    # Cargar modelo
    model = UNet1D(input_channels=2, output_channels=2).to(device)
    if prev_model_path is not None:
        model.load_state_dict(torch.load(prev_model_path, map_location=device))

    
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.MSELoss()
    
    os.makedirs(output_dir, exist_ok=True)
    best_model_path = os.path.join(output_dir, "unet_best_model.pth")

    best_val_loss = float('inf')
    epochs_without_improvement = 0
    train_losses, val_losses = [], []

    for epoch in range(num_epochs):
        train_loss = train_model(model, train_loader, optimizer, criterion, device)
        val_loss = validate_model(model, val_loader, criterion, device)

        train_losses.append(train_loss)
        val_losses.append(val_loss)


        # Guardar el mejor modelo
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(model.state_dict(), best_model_path)  #whole model saved instead of only weights (including architecture)
            print(f"Epoch {epoch+1}/{num_epochs}: Train Loss = {train_loss:.2e}, Val Loss = {val_loss:.2e}")
            print(f"Saved best model at epoch {epoch+1}")
            epochs_without_improvement = 0
        else:
            epochs_without_improvement += 1

        save_training_metrics(train_losses, val_losses, output_dir)

        if epochs_without_improvement >= patience:
            print(f"Early stopping at epoch {epoch+1}. No improvement in {patience} epochs.")
            break

    # 🔹 Liberar memoria después del entrenamiento
    del model
    del optimizer
    torch.cuda.empty_cache()
    gc.collect()

    #mem_after_allocated = torch.cuda.memory_allocated(device) / 1e6
    #mem_after_reserved = torch.cuda.memory_reserved(device) / 1e6

    #print(f"\n🔹 Memory Usage Before Training (Allocated): {mem_before_allocated:.2f} MB")
    #print(f"🔹 Memory Usage After Training  (Allocated): {mem_after_allocated:.2f} MB")
    #print(f"🔹 Memory Freed (Allocated): {mem_before_allocated - mem_after_allocated:.2f} MB\n")
    
    #print(f"🔹 Memory Usage Before Training (Reserved): {mem_before_reserved:.2f} MB")
    #print(f"🔹 Memory Usage After Training  (Reserved): {mem_after_reserved:.2f} MB")
    #print(f"🔹 Memory Freed (Reserved): {mem_before_reserved - mem_after_reserved:.2f} MB\n")

    print(f"Training complete. Best model saved at {best_model_path}")
    return best_model_path, best_val_loss

# Función para guardar métricas
def save_training_metrics(train_losses, val_losses, output_dir):
    metrics = {
        "train_losses": train_losses,
        "val_losses": val_losses
    }
    with open(os.path.join(output_dir, "training_metrics.json"), "w") as f:
        json.dump(metrics, f)

def plot_training_history(train_losses, val_losses, output_dir):
    plt.figure(figsize=(8, 5))
    plt.plot(train_losses, label="Train Loss")
    plt.plot(val_losses, label="Validation Loss")
    plt.xlabel("Epochs")
    plt.ylabel("Loss")
    plt.title("Training & Validation Loss")
    plt.legend()
    plt.grid()
    plt.savefig(os.path.join(output_dir, "loss_curve.png"))
    plt.show()



if __name__ == "__main__":
    dataset_dir = sys.argv[1]       # Carpeta con datasets HDF5
    output_dir = sys.argv[2]       # Carpeta para guardar modelos

    # Obtener todos los archivos HDF5 que no empiecen por "bits_"
    hdf5_files = [f for f in glob.glob(os.path.join(dataset_dir, '*.h5'))
                  if not os.path.basename(f).startswith('bits_')]

    if not hdf5_files:
        print(f"No HDF5 files found in {dataset_dir}. Exiting.")
        sys.exit(1)

    previous_model_path = None  
    global_best_model = None
    global_best_val_loss = float('inf')

    # Entrenar modelo para cada dataset encontrado
    for idx, hdf5_file in enumerate(hdf5_files):
        dataset_name = os.path.splitext(os.path.basename(hdf5_file))[0]
        model_output_dir = os.path.join(output_dir, dataset_name)
        # Crear directorio para salida del modelo específico
        os.makedirs(model_output_dir, exist_ok=True)

        print(f"Training model for dataset: {dataset_name}")

        # Entrenar el modelo
        best_model_path, best_val_loss = train_unet_pytorch(hdf5_file, model_output_dir, previous_model_path)

        # Guardar el mejor modelo global
        if best_val_loss < global_best_val_loss:
            global_best_val_loss = best_val_loss
            global_best_model = best_model_path

        previous_model_path = best_model_path

        # Cargar métricas de entrenamiento para graficar
        metrics_file = os.path.join(model_output_dir, "training_metrics.json")
        if os.path.exists(metrics_file):
            with open(metrics_file, "r") as f:
                metrics = json.load(f)
                train_losses = metrics["train_losses"]
                val_losses = metrics["val_losses"]

            # Mostrar gráfica al final del entrenamiento
            plot_training_history(train_losses, val_losses, model_output_dir)
        else:
            print(f"No metrics file found in {metrics_file}, skipping plotting.")

        print(f"Finished training for {dataset_name}\n")

    if global_best_model:
        final_model_path = os.path.join(output_dir, "final_best_model.pth")

        # Copiar el archivo del mejor modelo global a la ubicación final
        shutil.copy(global_best_model, final_model_path)

        print(f"Final best model saved at {final_model_path}, from dataset {os.path.basename(global_best_model)}")

