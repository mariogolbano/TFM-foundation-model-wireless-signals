import os
import sys
import torch
import numpy as np
import shutil
import h5py
import gc
import json
from torch.amp import autocast
from unet_model_pytorch import UNet1D   # Custom 1D U-Net model
from utils import *
from sklearn.metrics import mean_squared_error

# ==============================
# Device Configuration
# ==============================

# Use CUDA if available, otherwise fallback to CPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ==============================
# Model Loading
# ==============================

def load_model(model_path):
    """
    Load a trained UNet1D model from a checkpoint.

    Parameters:
    -----------
    model_path : str
        Path to the model checkpoint (.pth file).

    Returns:
    --------
    model : torch.nn.Module
        Loaded model in evaluation mode.
    """
    model = UNet1D(input_channels=2, output_channels=2).to(device)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.eval()
    return model

# ==============================
# Inference
# ==============================

def predict_signal(model, signal):
    """
    Run inference on a single signal using the model.

    Parameters:
    -----------
    model : torch.nn.Module
        Trained model for inference.
    signal : np.ndarray
        Input signal of shape [2, L].

    Returns:
    --------
    np.ndarray
        Cleaned signal of shape [2, L].
    """
    signal_tensor = torch.tensor(signal, dtype=torch.float32).unsqueeze(0).to(device)  # Add batch dimension: [1, 2, L]
    with torch.no_grad():
        with autocast(device_type='cuda'):  # Mixed precision for faster inference on GPU
            cleaned_tensor = model(signal_tensor)
    return cleaned_tensor.squeeze(0).cpu().numpy()  # Remove batch dimension

def process_dataset(model, input_file, output_file, reference_file=None):
    """
    Run inference on an entire HDF5 dataset and optionally compute MSE against a reference file.

    Parameters:
    -----------
    model : torch.nn.Module
        Trained model for inference.
    input_file : str
        Path to the HDF5 file containing noisy signals.
    output_file : str
        Path where the cleaned signals will be saved.
    reference_file : str or None
        Optional path to a clean signal file to compute MSE.

    Returns:
    --------
    float or None
        MSE value if reference is provided and valid, otherwise None.
    """
    with h5py.File(input_file, 'r') as f:
        noisy_signals = f['dataset'][:]
        frame_size = f['dataset'].attrs.get('FrameSize', None)

    print(f"  → Inference on {os.path.basename(input_file)} | Signals: {noisy_signals.shape[0]}")

    noisy_tensor = torch.tensor(noisy_signals, dtype=torch.float32).to(device)

    with torch.no_grad():
        with autocast(device_type='cuda'):
            cleaned_tensor = model(noisy_tensor)

    cleaned_signals = cleaned_tensor.cpu().numpy()

    mse_value = None
    if reference_file and os.path.exists(reference_file):
        with h5py.File(reference_file, 'r') as ref_f:
            if 'dataset' in ref_f:
                reference_signals = ref_f['dataset'][:]
                if reference_signals.shape == cleaned_signals.shape:
                    mse_value = np.mean((cleaned_signals - reference_signals) ** 2)
                else:
                    print("  [!] Shapes don't match for MSE.")
            else:
                print("  [!] Reference file missing 'dataset' key.")

    with h5py.File(output_file, 'w') as out_f:
        dset = out_f.create_dataset('dataset', data=cleaned_signals, dtype='float32')
        if frame_size is not None:
            dset.attrs['FrameSize'] = frame_size

    # Free memory
    del noisy_tensor, cleaned_tensor, cleaned_signals
    torch.cuda.empty_cache()
    gc.collect()

    return mse_value


# ==============================
# Main Inference Function
# ==============================

def main(model_path, datasets_dir, reference_dir=None):
    """
    Perform inference using a trained U-Net model on a set of noisy datasets,
    optionally comparing against clean reference datasets to compute MSE.

    Parameters:
    -----------
    model_path : str
        Path to the trained model checkpoint (.pth).
    datasets_dir : str
        Directory containing noisy .h5 files or subfolders of .h5 files.
    reference_dir : str or None
        Optional directory containing reference clean .h5 files (same names).
    """
    
    # Prepare output directory
    parent_dir = os.path.dirname(os.path.abspath(datasets_dir))
    base_name = os.path.basename(datasets_dir.rstrip('/'))
    output_dir = os.path.join(parent_dir, base_name + '_inference')
    os.makedirs(output_dir, exist_ok=True)

    mse_log = {}  # Store MSE values grouped by folder

    # Load the trained model
    model = load_model(model_path)

    # Case 1: HDF5 files are directly inside the dataset folder
    h5_files = [f for f in os.listdir(datasets_dir) if f.endswith('.h5') and not f.startswith('bits_')]

    if h5_files:
        for file in sorted(h5_files):
            input_path = os.path.join(datasets_dir, file)
            output_path = os.path.join(output_dir, file)
            reference_path = os.path.join(reference_dir, file) if reference_dir else None

            print(f"Processing: {file}")
            mse = process_dataset(model, input_path, output_path, reference_path)
            if mse is not None:
                mse_log.setdefault('.', {})[file] = mse
                print(f"  → Average MSE: {mse:.6f}")

            base_key = os.path.splitext(file)[0]
            copy_metadata_files(datasets_dir, output_dir, base_key)

    # Case 2: Dataset directory contains subfolders with HDF5 files
    else:
        for root, dirs, files in os.walk(datasets_dir):
            rel_path = os.path.relpath(root, datasets_dir)
            target_dir = os.path.join(output_dir, rel_path)
            os.makedirs(target_dir, exist_ok=True)

            for file in sorted(files):
                if file.endswith('.h5') and not file.startswith('bits_'):
                    input_path = os.path.join(root, file)
                    output_path = os.path.join(target_dir, file)
                    reference_path = os.path.join(reference_dir, file) if reference_dir else None

                    print(f"Processing: {os.path.join(rel_path, file)}")
                    mse = process_dataset(model, input_path, output_path, reference_path)
                    if mse is not None:
                        mse_log.setdefault(rel_path, {})[file] = mse
                        print(f"  → Average MSE: {mse:.6f}")

                    base_key = os.path.splitext(file)[0]
                    copy_metadata_files(root, target_dir, base_key)

    # Save MSE summary if any MSE values were computed
    if mse_log:
        mse_summary = {}
        for group, files in mse_log.items():
            mean_mse = np.mean(list(files.values()))
            mse_summary[group] = {
                "per_file": {k: float(v) for k, v in files.items()},
                "mean_mse": float(mean_mse)
            }

        output_json = os.path.join(output_dir, 'mse_results.json')
        with open(output_json, 'w') as f:
            json.dump(mse_summary, f, indent=4)
        print(f"\n MSE results saved in: {output_json}")

    print(f"\nInference completed. Cleaned files saved in: {output_dir}")

# ==============================
# Script Entry Point
# ==============================

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python unet_inference_batch.py <model_path> <datasets_dir> [reference_dir]")
        sys.exit(1)

    model_path = sys.argv[1]
    datasets_dir = sys.argv[2]
    reference_dir = sys.argv[3] if len(sys.argv) > 3 else None

    main(model_path, datasets_dir, reference_dir)
