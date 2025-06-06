import h5py
import os
import torch
from torch.utils.data import Dataset
import matplotlib.pyplot as plt
import json

# ==============================
# Custom Dataset Classes
# ==============================

class HDF5Dataset(Dataset):
    """
    Basic dataset class for loading 1D signals from an HDF5 file.
    The same signal is used as both input and target (e.g., for autoencoder-style training).

    Parameters:
    -----------
    hdf5_file : str
        Path to the HDF5 file containing a dataset under the key 'dataset'.
    """
    def __init__(self, hdf5_file):
        with h5py.File(hdf5_file, 'r') as f:
            self.data = f['dataset'][:]
        self.data = torch.tensor(self.data, dtype=torch.float32)

    def __len__(self):
        return self.data.shape[0]

    def __getitem__(self, idx):
        signal = self.data[idx]
        target = signal.clone()  # Target is identical to the input
        return signal, target

class HDF5DenoisingDataset(Dataset):
    """
    Dataset class for denoising tasks where the model learns to map noisy (interfered) signals
    to clean (ground truth) signals.

    Parameters:
    -----------
    interf_file : str
        Path to the HDF5 file containing interference-corrupted signals.
    clean_file : str
        Path to the HDF5 file containing clean reference signals.
    """
    def __init__(self, interf_file, clean_file):
        # Load clean signals
        with h5py.File(clean_file, 'r') as f:
            self.clean = f['dataset'][:]
        
        # Load interference signals
        with h5py.File(interf_file, 'r') as f:
            self.interf = f['dataset'][:]
        
        # Validate that shapes match
        assert self.interf.shape == self.clean.shape, "interf and clean datasets must have the same shape"
        
        # Convert to torch tensors
        self.interf = torch.tensor(self.interf, dtype=torch.float32)
        self.clean = torch.tensor(self.clean, dtype=torch.float32)

    def __len__(self):
        return self.clean.shape[0]

    def __getitem__(self, idx):
        # Return (input, target) pair: (interfered signal, clean signal)
        return self.interf[idx], self.clean[idx]


# ==============================
# Metric Saving and Plotting
# ==============================

def plot_training_history(train_losses, val_losses, output_dir):
    """
    Generate and save a plot of training and validation loss curves.

    Parameters:
    -----------
    train_losses : list of float
        Training loss values per epoch.
    val_losses : list of float
        Validation loss values per epoch.
    output_dir : str
        Directory where the plot will be saved as a PNG image.
    """
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

def save_training_metrics(train_losses, val_losses, output_dir):
    """
    Save training and validation loss history to a JSON file.

    Parameters:
    -----------
    train_losses : list of float
        Training loss values per epoch.
    val_losses : list of float
        Validation loss values per epoch.
    output_dir : str
        Directory where the JSON file will be saved.
    """
    metrics = {
        "train_losses": train_losses,
        "val_losses": val_losses
    }
    with open(os.path.join(output_dir, "training_metrics.json"), "w") as f:
        json.dump(metrics, f)

# ==============================
# JSON Metadata Utilities
# ==============================

def json_equal_except_snr(json1, json2):
    """
    Compare two JSON objects while ignoring the 'snr' field (case-insensitive).

    Parameters:
    -----------
    json1 : dict
    json2 : dict

    Returns:
    --------
    bool
        True if all keys/values match except for 'snr'; False otherwise.
    """
    dict1 = {k: v for k, v in json1.items() if k.lower() != 'snr'}
    dict2 = {k: v for k, v in json2.items() if k.lower() != 'snr'}
    return dict1 == dict2


def load_json_metadata(json_path):
    """
    Load metadata from a JSON file.

    Parameters:
    -----------
    json_path : str
        Path to the JSON file.

    Returns:
    --------
    dict
        Parsed JSON content.
    """
    with open(json_path, 'r') as f:
        return json.load(f)


def get_matching_pairs(clean_dir, interf_dir):
    """
    Match clean and interference files based on their JSON metadata,
    ignoring differences in the 'snr' field.

    Parameters:
    -----------
    clean_dir : str
        Directory containing clean .json and .h5 files.
    interf_dir : str
        Directory containing interfering .json and .h5 files.

    Returns:
    --------
    list of tuple
        List of matched pairs as (clean_file_path, interfered_file_path).
    
    Raises:
    -------
    ValueError
        If no .json files are found or no match exists for a clean file.
    """
    clean_jsons = [f for f in os.listdir(clean_dir) if f.endswith('.json')]
    interf_jsons = [f for f in os.listdir(interf_dir) if f.endswith('.json')]

    if not clean_jsons or not interf_jsons:
        raise ValueError("No .json files found in one or both directories")

    matched_pairs = []

    for clean_json_name in clean_jsons:
        clean_json_path = os.path.join(clean_dir, clean_json_name)
        clean_meta = load_json_metadata(clean_json_path)

        found_match = False
        for interf_json_name in interf_jsons:
            interf_json_path = os.path.join(interf_dir, interf_json_name)
            interf_meta = load_json_metadata(interf_json_path)

            if json_equal_except_snr(clean_meta, interf_meta):
                base_clean = clean_json_name.replace('.json', '.h5')
                base_interf = interf_json_name.replace('.json', '.h5')

                matched_pairs.append((
                    os.path.join(clean_dir, base_clean),
                    os.path.join(interf_dir, base_interf)
                ))
                found_match = True
                break

        if not found_match:
            raise ValueError(f"No matching interf file found for {clean_json_name}")

    return matched_pairs

# ==============================
# Metadata Copying Utility
# ==============================

def copy_metadata_files(src_dir, dst_dir, base_name):
    """
    Copy related metadata files (.json, .mat, bits_*.h5) based on base filename.

    Parameters:
    -----------
    src_dir : str
        Directory containing source metadata files.
    dst_dir : str
        Destination directory for copied files.
    base_name : str
        Base name of the dataset (without extension).
    """
    for ext in ['.json', '.mat', '.h5']:
        if ext == '.h5':
            fname = f"bits_{base_name}{ext}"
        else:
            fname = f"{base_name}{ext}"
        src_path = os.path.join(src_dir, fname)
        dst_path = os.path.join(dst_dir, fname)
        if os.path.exists(src_path):
            shutil.copy(src_path, dst_path)