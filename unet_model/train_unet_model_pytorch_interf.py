import os
import glob
import sys
import json
import torch
from torch.amp import autocast, GradScaler
import h5py
import shutil
from torch.utils.data import DataLoader
from torch import nn, optim
from unet_model_pytorch import UNet1D  # Custom 1D U-Net model
from torch.utils.data.dataset import random_split
from utils import *

# ==============================
# Device Configuration
# ==============================

# Select CUDA if available, otherwise fallback to CPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Initialize gradient scaler for mixed precision training (only effective with CUDA)
scaler = GradScaler("cuda")


# ==============================
# Training, Validation, and Inference Functions
# ==============================

def train_model(model, dataloader, optimizer, criterion, device):
    """
    Train the model for one epoch using mixed precision (if CUDA is available).

    Parameters:
    -----------
    model : torch.nn.Module
        The model to be trained.
    dataloader : DataLoader
        Dataloader providing (input, target) pairs.
    optimizer : torch.optim.Optimizer
        Optimizer used for weight updates.
    criterion : callable
        Loss function to be minimized.
    device : torch.device
        The device to run training on (CPU or GPU).

    Returns:
    --------
    float
        Average training loss over the entire dataset.
    """
    model.train()
    total_loss = 0.0

    for inputs, targets in dataloader:
        torch.cuda.empty_cache()  # Clear unused GPU memory (optional)

        inputs, targets = inputs.to(device), targets.to(device)

        optimizer.zero_grad()

        # Use autocast for mixed precision training (only with CUDA)
        with autocast("cuda"):
            outputs = model(inputs)
            loss = criterion(outputs, targets)

        # Backward pass and optimizer step using gradient scaler
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        total_loss += loss.item()

    return total_loss / len(dataloader)


def infer_on_test(model, test_loader, output_dir):
    """
    Run inference on a test set and save the outputs as .h5 files.

    Parameters:
    -----------
    model : torch.nn.Module
        Trained model to use for inference.
    test_loader : DataLoader
        DataLoader containing test input signals.
    output_dir : str
        Directory where output .h5 files will be saved.

    Returns:
    --------
    None
    """
    os.makedirs(output_dir, exist_ok=True)
    model.eval()

    for inputs, _ in test_loader:
        inputs = inputs.to(device)

        # Disable gradients and use mixed precision for inference
        with torch.no_grad():
            with autocast(device_type='cuda'):
                outputs = model(inputs)

        # Move outputs back to CPU and save each sample
        outputs = outputs.cpu().numpy()
        for i, output in enumerate(outputs):
            output_file = os.path.join(output_dir, f'inference_{i}.h5')
            with h5py.File(output_file, 'w') as f_out:
                f_out.create_dataset('dataset', data=output)

    print(f"Inference completed. Results saved in: {output_dir}")


def validate_model(model, dataloader, criterion, device):
    """
    Validate the model on a validation dataset.

    Parameters:
    -----------
    model : torch.nn.Module
        The model to evaluate.
    dataloader : DataLoader
        Dataloader with validation data.
    criterion : callable
        Loss function used to evaluate performance.
    device : torch.device
        The device to run validation on.

    Returns:
    --------
    float
        Average validation loss over the dataset.
    """
    model.eval()
    total_loss = 0.0

    with torch.no_grad():
        for inputs, targets in dataloader:
            inputs, targets = inputs.to(device), targets.to(device)

            outputs = model(inputs)
            loss = criterion(outputs, targets)
            total_loss += loss.item()

    return total_loss / len(dataloader)

# ==============================
# U-Net Training Function with Early Stopping
# ==============================

def train_unet_pytorch(dataset, output_dir, prev_model_path=None, batch_size=16, num_epochs=500, lr=0.0003, patience=10, inference=1):
    """
    Train a 1D U-Net model on a given dataset with early stopping and optional inference.

    Parameters:
    -----------
    dataset : torch.utils.data.Dataset
        Complete dataset to be split into training, validation, and test sets.
    output_dir : str
        Directory where model checkpoints and results will be saved.
    prev_model_path : str or None
        Optional path to a pretrained model checkpoint to resume training from.
    batch_size : int
        Batch size used for training and evaluation.
    num_epochs : int
        Maximum number of training epochs.
    lr : float
        Learning rate for the optimizer.
    patience : int
        Number of epochs to wait before early stopping if no improvement.
    inference : bool
        Whether to run inference on the test set after training.

    Returns:
    --------
    best_model_path : str
        Path where the best model (based on validation loss) is saved.
    best_val_loss : float
        Best validation loss achieved during training.
    """

    # 🔹 Check and print GPU memory usage before training
    mem_before_allocated = torch.cuda.memory_allocated(device) / 1e6
    mem_before_reserved = torch.cuda.memory_reserved(device) / 1e6

    # Split dataset: 90% train, 5% validation, 5% test
    train_size = int(0.9 * len(dataset))
    val_size = int(0.05 * len(dataset))
    test_size = len(dataset) - train_size - val_size

    train_dataset, val_dataset, test_dataset = random_split(dataset, [train_size, val_size, test_size])

    # Create dataloaders for each split
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, num_workers=4)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, num_workers=4)

    # Initialize or load model
    model = UNet1D(input_channels=2, output_channels=2).to(device)
    if prev_model_path is not None:
        model.load_state_dict(torch.load(prev_model_path, map_location=device))

    # Define optimizer and loss function
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.MSELoss()

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    best_model_path = os.path.join(output_dir, "unet_best_model.pth")

    best_val_loss = float('inf')
    epochs_without_improvement = 0
    train_losses, val_losses = [], []

    # Training loop with early stopping
    for epoch in range(num_epochs):
        train_loss = train_model(model, train_loader, optimizer, criterion, device)
        val_loss = validate_model(model, val_loader, criterion, device)

        train_losses.append(train_loss)
        val_losses.append(val_loss)

        # Save model if validation improves significantly (0.5%)
        if best_val_loss == float('inf') or (best_val_loss - val_loss) > (best_val_loss * 0.5e-2):
            best_val_loss = val_loss
            torch.save(model.state_dict(), best_model_path)
            print(f"Epoch {epoch+1}/{num_epochs}: Train Loss = {train_loss:.2e}, Val Loss = {val_loss:.2e}")
            print(f"Saved best model at epoch {epoch+1}")
            epochs_without_improvement = 0
        else:
            epochs_without_improvement += 1

        # Save training metrics to disk
        save_training_metrics(train_losses, val_losses, output_dir)

        # Early stopping if no improvement after `patience` epochs
        if epochs_without_improvement >= patience:
            print(f"Early stopping at epoch {epoch+1}. No improvement in {patience} epochs.")
            break

    # Optionally run inference on the test set
    if inference:
        test_inference_dir = os.path.join(output_dir, 'inference')
        infer_on_test(model, test_loader, test_inference_dir)

    print(f"Training complete. Best model saved at {best_model_path}")
    return best_model_path, best_val_loss


# ==============================
# Main Entry Point for Training Script
# ==============================

if __name__ == "__main__":
    args = sys.argv

    # ==========================
    # Classic Autoencoder Mode
    # ==========================
    if len(args) == 3:
        # Usage: python train.py <clean_dataset_dir> <output_dir>
        print("Training Classic Autoencoder")

        dataset_dir = args[1]
        output_dir = args[2]

        # Get all .h5 files in dataset_dir, ignoring those starting with 'bits_'
        hdf5_files = [f for f in glob.glob(os.path.join(dataset_dir, '*.h5'))
                      if not os.path.basename(f).startswith('bits_')]
        if not hdf5_files:
            print(f"No HDF5 files found in {dataset_dir}. Exiting.")
            sys.exit(1)

        prev_model_path = None  # Start training from scratch

        for hdf5_file in hdf5_files:
            dataset_name = os.path.splitext(os.path.basename(hdf5_file))[0]
            model_output_dir = os.path.join(output_dir, dataset_name)
            os.makedirs(model_output_dir, exist_ok=True)

            print(f"Training model for dataset: {dataset_name}")

            dataset = HDF5Dataset(hdf5_file)
            best_model_path, best_val_loss = train_unet_pytorch(dataset, model_output_dir, prev_model_path)

            prev_model_path = best_model_path  # Optionally use best model as starting point for next

            # Load and plot training metrics if available
            metrics_file = os.path.join(model_output_dir, "training_metrics.json")
            if os.path.exists(metrics_file):
                with open(metrics_file, "r") as f:
                    metrics = json.load(f)
                    train_losses = metrics["train_losses"]
                    val_losses = metrics["val_losses"]
                plot_training_history(train_losses, val_losses, model_output_dir)
            else:
                print(f"No metrics file found in {metrics_file}, skipping plotting.")

            print(f"Finished training for {dataset_name}\n")

        # Save final best model
        final_model_path = os.path.join(output_dir, "classical_best_model.pth")
        shutil.copy(best_model_path, final_model_path)
        print(f"Final best model saved at {final_model_path}")

    # ==========================
    # Denoising Autoencoder Mode
    # ==========================
    elif len(args) >= 5:
        # Usage: python train.py <clean_dataset_dir> <interf_dataset_dir> <output_dir> <trained_model_path> <final model? (optional)>
        print("Training Denoising Autoencoder")

        clean_dir = args[1]
        interf_dir = args[2]
        output_dir = args[3]
        prev_model_path = args[4]
        final_version = (len(args) == 6 and args[5].lower() in ['true', 'yes', 'final'])

        matched_pairs = get_matching_pairs(clean_dir, interf_dir)

        for clean_file, interf_file in matched_pairs:
            dataset_name = os.path.splitext(os.path.basename(interf_file))[0]
            model_output_dir = os.path.join(output_dir, dataset_name)
            os.makedirs(model_output_dir, exist_ok=True)

            print(f"Training denoising model for dataset: {dataset_name}")

            dataset = HDF5DenoisingDataset(interf_file, clean_file)
            best_model_path, best_val_loss = train_unet_pytorch(dataset, model_output_dir, prev_model_path)

            previous_model_path = best_model_path  # Update model for potential reuse

            # Load and plot training metrics
            metrics_file = os.path.join(model_output_dir, "training_metrics.json")
            if os.path.exists(metrics_file):
                with open(metrics_file, "r") as f:
                    metrics = json.load(f)
                    train_losses = metrics["train_losses"]
                    val_losses = metrics["val_losses"]
                plot_training_history(train_losses, val_losses, model_output_dir)
            else:
                print(f"No metrics file found in {metrics_file}, skipping plotting.")

            print(f"Finished training for {dataset_name}\n")

        # Save final best model
        final_model_path = os.path.join(output_dir, "final_best_model.pth")
        shutil.copy(best_model_path, final_model_path)
        print(f"Final best model saved at {final_model_path}")

        # Optional final version copy
        if final_version:
            parent_dir = os.path.dirname(output_dir.rstrip('/'))
            denoising_model_path = os.path.join(parent_dir, "denoising_best_model.pth")
            shutil.copy(best_model_path, denoising_model_path)
            print(f"Final denoising model saved at {denoising_model_path}")

    # ==========================
    # Invalid Usage
    # ==========================
    else:
        print("Usage (classic autoencoder): python train.py <clean_dataset_dir> <output_dir>")
        print("Usage (denoising autoencoder): python train.py <clean_dataset_dir> <interf_dataset_dir> <output_dir> <trained_model_path> <final model? (optional)>")
        sys.exit(1)
