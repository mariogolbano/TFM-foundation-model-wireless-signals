import h5py
import numpy as np
import os

def adjust_signal_length(interf_signal, target_length):
    """
    Adjust the length of an interference signal to match a target length.

    Parameters:
    ----------
    interf_signal : np.ndarray
        The interference signal to be adjusted (1D or 2D array).
    target_length : int
        The desired length of the signal.

    Returns:
    -------
    np.ndarray
        Signal with adjusted length: either trimmed or repeated to reach the target length.
    """
    current_length = interf_signal.shape[-1]  # Get the current length of the signal
    if current_length > target_length:
        # If the signal is longer than desired, crop it
        return interf_signal[..., :target_length]
    elif current_length < target_length:
        # If the signal is shorter, repeat it enough times and then trim
        repeat_factor = target_length // current_length + 1
        extended = np.concatenate([interf_signal] * repeat_factor, axis=-1)
        return extended[..., :target_length]
    else:
        # If already the correct length, return as is
        return interf_signal

def create_interference_dataset(clean_h5_path, interf_h5_path, attenuation_factor, new_name=None):
    """
    Create a new dataset by adding interference signals to clean signals.

    Parameters:
    ----------
    clean_h5_path : str
        Path to the HDF5 file containing clean signals under the 'dataset' key.
    interf_h5_path : str
        Path to the HDF5 file containing interference signals under the 'dataset' key.
    attenuation_factor : float
        Scaling factor to apply to the interference signals before adding them.
    new_name : str, optional
        Optional name for the output HDF5 file (without extension). If None, auto-generated from input.

    Returns:
    -------
    None
        Saves the resulting dataset with interference into a new HDF5 file.
    """
    
    # Load clean signals from HDF5 file
    with h5py.File(clean_h5_path, 'r') as f_clean:
        clean_data = f_clean['dataset'][:]  # Load the actual dataset
        attrs = dict(f_clean['dataset'].attrs)  # Copy metadata attributes

    # Load interference signals from HDF5 file
    with h5py.File(interf_h5_path, 'r') as f_interf:
        interf_data = f_interf['dataset'][:]  # Load the actual dataset

    # Determine number of channels (if multidimensional)
    clean_channels = clean_data.shape[1] if clean_data.ndim > 1 else 1
    interf_channels = interf_data.shape[1] if interf_data.ndim > 1 else 1

    # Warn if number of channels don't match
    if clean_channels != interf_channels:
        print(f"Mismatch in channel dimensions:")
        print(f"  → Clean file ({os.path.basename(clean_h5_path)}): {clean_channels} channels")
        print(f"  → Interf file ({os.path.basename(interf_h5_path)}): {interf_channels} channels")

    # Adjust each interference signal to match the length of its corresponding clean signal
    interf_data_adjusted = np.array([
        adjust_signal_length(interf, clean.shape[-1])
        for interf, clean in zip(interf_data, clean_data)
    ])

    # Validate that shapes match (excluding time axis)
    assert clean_data.shape[1:] == interf_data_adjusted.shape[1:], \
        "Signals must have the same number of channels and structure."

    # Combine clean and interference signals, applying attenuation
    result_data = clean_data + attenuation_factor * interf_data_adjusted

    # Determine output filename
    base_name = new_name if new_name else os.path.splitext(os.path.basename(clean_h5_path))[0] + '_interf'
    output_path = base_name + '.h5'

    # Save the resulting dataset to a new HDF5 file, preserving metadata
    with h5py.File(output_path, 'w') as f_out:
        dset = f_out.create_dataset('dataset', data=result_data.astype('float32'))  # Store as float32
        for key, val in attrs.items():
            dset.attrs[key] = val  # Copy over original metadata

    print(f"Interference dataset saved at: {output_path}")
