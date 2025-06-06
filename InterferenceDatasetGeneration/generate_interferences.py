import os
import glob
import shutil
from utils import *

def copy_related_files(source_dir, base_name, destination_dir):
    """
    Copy related auxiliary files (.json, .mat, and bits_*.h5) associated with a given base filename.

    Parameters:
    ----------
    source_dir : str
        Directory where the original files are located.
    base_name : str
        Base name of the signal file (without extension).
    destination_dir : str
        Directory where related files should be copied.
    """
    extensions = ['.json', '.mat', '.h5']
    for ext in extensions:
        if ext == '.h5':
            # Only copy .h5 files that are bit-related and start with 'bits_'
            filename = f"bits_{base_name}{ext}"
            if os.path.basename(filename).startswith('bits_'):
                src = os.path.join(source_dir, filename)
                dst = os.path.join(destination_dir, filename)
                if os.path.exists(src):
                    shutil.copy(src, dst)
        else:
            # Copy .json and .mat files directly if they exist
            filename = f"{base_name}{ext}"
            src = os.path.join(source_dir, filename)
            dst = os.path.join(destination_dir, filename)
            if os.path.exists(src):
                shutil.copy(src, dst)

def main():
    """
    Main procedure to create multiple interference datasets by combining clean and interfering signals
    at different attenuation levels. Auxiliary files are also copied alongside each result.

    Users can configure the directories and attenuation factors directly in the section below.
    """

    # === User Configuration ===
    # Directory containing clean signals
    clean_dir = './../datasets/comm_dataset/3_3mods_interf_2/test/clean'
    
    # Directory containing interference signals
    interf_dir = './../datasets/comm_dataset/3_3mods_interf_2/test/interfering'
    
    # Base directory where output with interference will be saved
    base_output_dir = './../datasets/comm_dataset/3_3mods_interf_2/test/interference'
    
    # List of attenuation factors to apply to the interference signals
    att_factors = [0.5, 0.75]
    # ===========================

    os.makedirs(base_output_dir, exist_ok=True)

    # Collect all valid .h5 clean files (excluding those starting with 'bits_')
    clean_files = sorted([
        f for f in glob.glob(os.path.join(clean_dir, '*.h5'))
        if not os.path.basename(f).startswith('bits_')
    ])
    # Collect all valid .h5 interference files (excluding those starting with 'bits_')
    interf_files = sorted([
        f for f in glob.glob(os.path.join(interf_dir, '*.h5'))
        if not os.path.basename(f).startswith('bits_')
    ])

    # Iterate through each combination of clean file, interference file, and attenuation level
    for clean_file in clean_files:
        clean_base = os.path.splitext(os.path.basename(clean_file))[0]

        for interf_file in interf_files:
            interf_base = os.path.splitext(os.path.basename(interf_file))[0]

            for att in att_factors:
                att_str = f"{int(att * 100):03d}"  # Format: 0.5 → '050', 0.75 → '075'
                output_subdir = os.path.join(base_output_dir, f"interference_{interf_base}_{att_str}")
                os.makedirs(output_subdir, exist_ok=True)

                # Output file name is based on clean file's base name
                output_file = os.path.join(output_subdir, f"{clean_base}")
                
                # Apply interference and save result
                create_interference_dataset(clean_file, interf_file, att, new_name=output_file)

                # Copy auxiliary files related to the clean signal
                copy_related_files(clean_dir, clean_base, output_subdir)

    print(f"\nInterference datasets successfully generated and saved in '{base_output_dir}'")
