import os
import sys
import torch
import h5py
import numpy as np
import shutil
import gc
import json
from torch.amp import autocast
from unet_model_pytorch_2 import UNet1D

# Configurar dispositivo
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def load_model(model_path):
    model = UNet1D(input_channels=2, output_channels=2).to(device)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()
    return model

def predict_signal(model, signal):
    signal_tensor = torch.tensor(signal, dtype=torch.float32).unsqueeze(0).to(device)  # [1, 2, L]
    with torch.no_grad():
        with autocast(device_type='cuda'):
            cleaned_tensor = model(signal_tensor)
    return cleaned_tensor.squeeze(0).cpu().numpy()  # [2, L]

def process_dataset(model, input_file, output_file):
    with h5py.File(input_file, 'r') as f:
        noisy_signals = f['dataset'][:]
        frame_size = f['dataset'].attrs.get('FrameSize', None)

    print(f"  → Inference on {os.path.basename(input_file)} | Signals: {noisy_signals.shape[0]}")

    noisy_tensor = torch.tensor(noisy_signals, dtype=torch.float32).to(device)

    with torch.no_grad():
        with autocast(device_type='cuda'):
            cleaned_tensor = model(noisy_tensor)

    cleaned_signals = cleaned_tensor.cpu().numpy()

    with h5py.File(output_file, 'w') as out_f:
        dset = out_f.create_dataset('dataset', data=cleaned_signals, dtype='float32')
        if frame_size is not None:
            dset.attrs['FrameSize'] = frame_size

    del noisy_tensor, cleaned_tensor, cleaned_signals
    torch.cuda.empty_cache()
    gc.collect()

def copy_metadata_files(src_dir, dst_dir, base_name):
    for ext in ['.json', '.mat', '.h5']:
        if ext == '.h5':
            fname = f"bits_{base_name}{ext}"
        else:
            fname = f"{base_name}{ext}"
        src_path = os.path.join(src_dir, fname)
        dst_path = os.path.join(dst_dir, fname)
        if os.path.exists(src_path):
            shutil.copy(src_path, dst_path)

def main(model_path, datasets_dir):
    # Crear carpeta de salida
    parent_dir = os.path.dirname(os.path.abspath(datasets_dir))
    base_name = os.path.basename(datasets_dir)
    output_dir = os.path.join(parent_dir, base_name + '_inference')
    os.makedirs(output_dir, exist_ok=True)

    # Cargar el modelo
    model = load_model(model_path)

    # Procesar todos los archivos .h5 que no son de bits
    for file in sorted(os.listdir(datasets_dir)):
        if file.endswith('.h5') and not file.startswith('bits_'):
            input_path = os.path.join(datasets_dir, file)
            output_path = os.path.join(output_dir, file)

            print(f"Processing: {file}")
            process_dataset(model, input_path, output_path)

            # Copiar archivos asociados: .json, .mat, bits_*.h5
            base_key = os.path.splitext(file)[0]  # e.g., OFDM_1
            copy_metadata_files(datasets_dir, output_dir, base_key)

    print(f"\nInference completed. Cleaned files saved in: {output_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python unet_inference_batch.py <model_path> <datasets_dir>")
        sys.exit(1)

    model_path = sys.argv[1]
    datasets_dir = sys.argv[2]

    main(model_path, datasets_dir)
