# **Foundation Model for Wireless Signal Recovery**

## **Overview**
This repository contains the complete pipeline for **wireless signal generation, visualization, and recovery using deep learning**. It integrates three key components:

1. **Signal Generation (MATLAB GUI)**: A MATLAB-based graphical interface to generate realistic wireless communication signals, including WiFi, Bluetooth, DSSS, and 5G signals with interference and impairments.
2. **Dataset Visualization (Python Notebooks)**: A set of Jupyter Notebooks for exploring and analyzing generated datasets, visualizing signals in the time and frequency domains, and comparing interference scenarios.
3. **Deep Learning Model (UNet1D for Signal Recovery)**: A PyTorch-based **1D U-Net model** designed to recover clean wireless signals from interference and noise, improving signal separation in the radio spectrum.

This work aims to develop a **foundation model for wireless signal processing**, leveraging deep learning techniques to reconstruct degraded signals and enhance communication performance.

---

## **Repository Structure**
The repository is divided into three main directories, each containing a dedicated README file with detailed explanations.

```
/
│── DatasetGeneration_GUI_MATLAB/                 # MATLAB-based signal generation system
│   ├── funcs/                   # Supporting functions for modulation and impairments
│   ├── DatasetGeneration.m       # Main GUI script for dataset creation
│   ├── ModulationSelectionGUI.m  # GUI for selecting modulation types
│   ├── VideoSelectionGUI.m       # GUI for video-based signal encoding
│   └── README.md                 # Documentation for signal generation
│
│── DatasetVisualization_Python/       # Jupyter Notebooks for dataset analysis
│   ├── dataset_visualization.ipynb  # Main notebook for dataset exploration
│   ├── aux_funcs_vis.py          # Helper functions for visualization
│   ├── README.md                 # Documentation for dataset visualization
│
│── unet/
|   │── dataset_utils/                   # Helper functions for dataset management
|   │── notebook/                         # Jupyter Notebooks for training analysis
|   │── outputs/                          # Directory for saving training logs and results
|   │── reference_models/                  # Pretrained models (handled via Git LFS)
|   │── rfcutils/                         # Additional utilities for model evaluation
|   │── src/                              # Source code for model training and inference
|   │── README.md                         # Documentation for this module
|   │── rfsionna_env.yml                  # Environment file for Sionna-based experiments
|   │── rftorch_env.yml                   # Environment file for PyTorch-based experiments
|   │── sampletest_evaluationscript.py    # Script to evaluate trained models on test datasets
|   │── sampletest_generatetestmixtures.sh # Shell script to generate test mixtures
|   │── sampletest_testmixture_generator.py # Script to generate test datasets
|   │── sampletest_tf_unet_inference.py   # TensorFlow-based U-Net inference script
|   │── sampletest_torch_wavenet_inference.py # PyTorch-based WaveNet inference script
|   │── sampletrain_gendataset_script.sh  # Shell script for generating training datasets
|   │── supervised_config.yml             # Configuration file for training parameters
|   │── train_torchwavenet.py             # PyTorch training script for WaveNet
|   │── train_unet_model_pytroch_2_mem.py # Optimized PyTorch training script for UNet1D
|   │── unet_model_pytorch_2.py           # UNet1D model implementation
│
└── README.md                     # General documentation (this file)
```

---

## **1. Wireless Signal Generation (MATLAB)**
The **GUI_MATLAB** directory contains a **MATLAB-based graphical user interface (GUI)** for generating synthetic wireless communication signals.

### **Features**
- Supports **multiple wireless communication standards**: WiFi (802.11ax, 802.11ac, Non-HT), Bluetooth, DSSS, and 5G.
- Allows **customizable signal impairments** such as **AWGN, IQ imbalance, phase noise, and nonlinear distortions**.
- Integrates **video-based signal encoding**, enabling users to generate signals from video content.
- Stores datasets in **HDF5 format** for seamless integration with deep learning models.

### **How to Use**
Run the following command in MATLAB:
```matlab
DatasetGeneration
```
This will launch the GUI for configuring signal generation parameters.

For more details, refer to **GUI_MATLAB/README.md**.

---

## **2. Dataset Visualization (Python Notebooks)**
The **dataset_visualization** directory contains Python-based **Jupyter Notebooks** for analyzing and exploring the generated wireless signal datasets.

### **Features**
- Loads datasets stored in **HDF5 format**.
- Provides interactive **modulation selection** and **signal analysis** tools.
- Visualizes:
  - **Time-domain waveforms** of wireless signals.
  - **Spectrograms** to analyze frequency content.
  - **Constellation diagrams** for modulation analysis.
- Supports **single-signal analysis** and **interference visualization**.

### **How to Use**
1. Install dependencies:
   ```bash
   pip install numpy matplotlib h5py torch ipywidgets
   ```
2. Run the Jupyter Notebook:
   ```bash
   jupyter notebook dataset_visualization.ipynb
   ```
For more details, refer to **dataset_visualization/README.md**.

---

## **3. UNet1D Model for Signal Recovery (PyTorch)**
The **unet** directory contains a **deep learning model (UNet1D)** implemented in PyTorch for **wireless signal recovery**.

### **Features**
- **1D U-Net architecture** optimized for wireless signal processing.
- Designed to **separate signals of interest (SoI) from interference**.
- Uses **skip connections** and **multi-scale feature extraction** for better reconstruction.
- Supports **custom training on HDF5 datasets**.

### **Training the Model**
1. Install dependencies:
   ```bash
   pip install torch numpy matplotlib h5py json scipy
   ```
2. Run training:
   ```bash
   python train_unet_pytorch.py /path/to/dataset /path/to/output_directory
   ```
3. View training loss curves:
   ```bash
   python plot_loss.py /path/to/output_directory
   ```

### **Running Inference**
To apply the trained model to new signals:
```bash
python test_unet.py /path/to/test_dataset /path/to/saved_model
```

For more details, refer to **unet/README.md**.

---

## **Dataset Availability**
- The datasets used in this project **are not stored in this repository** due to storage limitations.
- A set of preprocessed datasets can be accessed through the following link:  
  **[Google Drive Link]** *(To be added by the user)*
- Users can generate new datasets using the **MATLAB GUI**.

---

## **Support and Contributions**
For issues, questions, or contributions:
- Open an **issue** in this repository.
- Submit a **pull request** with improvements.
- Contact the maintainers for collaboration.