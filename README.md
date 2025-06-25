# **Foundation Model for Wireless Signal Recovery**

## **Overview**
This repository contains the complete pipeline for **wireless signal generation, interference simulation, visualization, and recovery using deep learning**. It integrates four key components:

1. **Signal Generation (MATLAB GUI)**: A GUI-based system for generating synthetic wireless signals with configurable modulation types and impairments.
2. **Interference Simulation (Python)**: A script-based pipeline to combine clean and interfering signals into realistic mixed datasets.
3. **Dataset Visualization and Demodulation (MATLAB & Python)**: Tools for inspecting and demodulating wireless signals, analyzing spectral and temporal characteristics.
4. **Deep Learning Model (UNet1D in PyTorch)**: A neural network for signal recovery that reconstructs clean signals from noisy or interfered inputs.

This work supports the development of a **foundation model for wireless signal processing**, capable of generalizing across diverse modulation schemes and interference scenarios.

---

## **Repository Structure**
```

/
│
├── DatasetGeneration\_GUI\_MATLAB/              # MATLAB GUI for wireless signal generation
│   ├── DatasetGeneration.m                    # Main script
│   ├── ModulationSelectionGUI.m               # GUI for selecting modulation types
│   ├── PreprocessedVideosGUI.m                # GUI for selecting videos for signal content
│   └── README.md                              # Details on GUI usage

├── InterferenceDatasetGeneration/             # Python scripts for interference creation
│   ├── generate\_interferences.py              # Main script to mix signals with interference
│   ├── utils.py                               # Signal processing utilities (length match, merging)
│   └── README.md                              # Documentation for this module

├── DatasetDemodulationVisualization\_GUI\_MATLAB/   # GUI for demodulation and visualization
│   ├── DemodulateDatasets.m                   # Entry point for signal demodulation
│   ├── Multiple GUIs:                         # VisualizeSignalsGUI.m, etc.
│   └── README.md                              # Full GUI documentation

├── DatasetVisualization\_Python/              # Jupyter Notebook for dataset inspection
│   ├── Dataset\_Visualization.ipynb           # Notebook for signal exploration
│   ├── aux\_funcs\_vis.py                      # Helper functions for plotting and loading
│   └── README.md                             # Visualization instructions

├── unet\_model/                               # PyTorch model for signal recovery
│   ├── train\_unet\_model\_pytorch\_interf.py    # UNet training with/without interference
│   ├── unet\_inference\_pytorch.py             # Apply trained model to new datasets
│   ├── unet\_model\_pytorch.py                 # UNet1D architecture
│   ├── utils.py                              # Dataloader, losses, helpers
│   ├── environment.yml                       # Conda environment file
│   └── README.md                             # Deep learning documentation

├── funcs/                                    # MATLAB helper scripts
│   ├── demods/                               # Demodulation functions
│   ├── mods/                                 # Modulation functions
│   ├── plots/                                # Signal plotting functions
│   ├── bitsToVideoFrames.m, loadDatasetSignals.m, etc.
│
└── README.md                                 # This file (project-wide overview)

```

---

## **1. Wireless Signal Generation (MATLAB GUI)**
Located in `DatasetGeneration_GUI_MATLAB/`, this component enables **interactive generation of RF signals** with:
- Modulation options: **WiFi, DSSS, Bluetooth, PSK, QAM**
- Impairments: **AWGN**
- Custom video sources: The signal generation uses videos stored at **[Zenodo](https://zenodo.org/records/15741102?token=eyJhbGciOiJIUzUxMiJ9.eyJpZCI6ImZmZjdkNTg0LTdjMjQtNDI2OC04Yzk0LTIwMmYwNWRjZjEzNiIsImRhdGEiOnt9LCJyYW5kb20iOiJjMTVjYTBiMzI2Njk5OWQ3NGVhN2ViOGRhZWEwNWIzMyJ9.ll6oiTY2N1ErL7FNhQ4_J_Gd5S5_3Z1nVGOUf-sgsmDcy_3GEC_uA1DWPNlzfv2x9VttBOMLUSNyUQk88Q7UHQ)**.
- Output in **HDF5 format** with metadata and bitstreams

Launch via:
```matlab
DatasetGeneration
```

See `DatasetGeneration_GUI_MATLAB/README.md` for details.

---

## **2. Interference Dataset Creation (Python)**

The `InterferenceDatasetGeneration/` module includes scripts to **combine clean and interfering signals** using variable attenuation levels.

* Inputs: `clean/`, `interfering/` `.h5` datasets
* Output: multiple `interference_<source>_<atten>.h5` versions
* Copies matching `.json`, `.mat`, and `bits_*.h5` files

Run via:

```bash
python generate_interferences.py
```

Details in `InterferenceDatasetGeneration/README.md`.

---

## **3. Dataset Visualization and Demodulation**

### **MATLAB GUIs**

The `DatasetDemodulationVisualization_GUI_MATLAB/` folder includes:

* GUIs for **visualizing** and **demodulating** signals
* Supports constellation diagrams, PSDs, spectrograms
* Select individual signals for in-depth inspection

Launch with:

```matlab
DemodulateDatasets
```

### **Python Notebook**

Located in `DatasetVisualization_Python/`, run:

```bash
jupyter notebook Dataset_Visualization.ipynb
```

Explore:

* Time-domain signals
* Frequency content (spectrograms)
* Constellation diagrams
* Compare clean vs. interfered signals

---

## **4. Deep Learning for Signal Recovery (PyTorch)**

The `unet_model/` directory implements a **1D U-Net** for RF signal denoising.

* Handles both **classic and denoising autoencoder** training
* HDF5 datasets: shape `[N, 2, L]` (I/Q channels)
* Outputs inference results with MSE metrics
* Visualizes training curves

Train model:

```bash
python train_unet_model_pytorch_interf.py clean_dir [interf_dir] output_dir
```

Run inference:

```bash
python unet_inference_pytorch.py model.pth input_dir
```

Environment setup:

```bash
conda env create -f environment.yml
conda activate unet_env
```

See `unet_model/README.md` for all options and examples.

---

## **Dependencies**

* MATLAB R2021a or newer (Signal Processing Toolbox recommended)
* Python 3.8+
* Required packages: `torch`, `h5py`, `numpy`, `matplotlib`, `scipy`, `ipywidgets`, `jupyter`, etc.
* Install via:

```bash
conda env create -f unet_model/environment.yml
```

---

## **Datasets**

Datasets are generated via the MATLAB GUI and may include:

* Clean signals
* Interference-only signals
* Mixed (attenuated) interference signals
* Corresponding `.json`, `.mat`, and `bits_*.h5` metadata

In this link an example of a dataset generated using this framework can be found. This dataset was used for the example described in my Master's Thesis: A data-driven framework for Wireless Communications: **[Dataset Example in Zenodo](https://zenodo.org/records/15740852?token=eyJhbGciOiJIUzUxMiJ9.eyJpZCI6IjhiY2M1YWQ1LWI4OTktNGRjNC04MzY5LTFhMDM2MmMyYmJlMCIsImRhdGEiOnt9LCJyYW5kb20iOiI4MTA4ZTdmNzlmNmY5NTkwMDNjYTYzNDc3YjIwYjQ4NCJ9.E6jWzyWlf57ixQSE9AK9fKkOG-yvnF8n65L5GCZXrv7T8JHnpEZL2-EWz3gljZGZZywYSoIYEnsqk-UczwzQpw)**

