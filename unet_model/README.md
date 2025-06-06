# **Signal Recovery using UNet1D for Wireless Interference Mitigation**

## **Overview**
This project implements a deep learning-based **1D U-Net architecture (UNet1D)** in PyTorch to perform **signal denoising and interference rejection** in **wireless communications**. It focuses on **recovering signals of interest (SoI)** from corrupted or interfered inputs using **time-domain complex baseband data**.

The model supports **training**, **inference**, and **performance evaluation**, with features tailored for **RF signal separation** scenarios, particularly useful in spectrum sharing and cognitive radio systems.

---

## **Repository Structure**
- `train_unet_model_pytorch_interference.py`: Main training pipeline supporting classic and denoising autoencoder modes.
- `unet_inference_pytorch.py`: Batch inference script for evaluating trained models.
- `unet_model_pytorch.py`: 1D U-Net architecture implementation.
- `utils.py`: Dataset classes, plotting utilities, metadata handling, and file operations.
- `environment.yml`: Lists all dependencies for environment setup.

---

## **Model: UNet1D**
A fully convolutional encoder-decoder network for **1D signals** with:
- **5-layer encoder/decoder** with **skip connections**.
- **Long kernel** in the first layer to capture long-term dependencies.
- **Dropout** after pooling for regularization.
- **Reconstruction output** with two channels (I/Q).

---

## **Supported Datasets**
All datasets are in **HDF5** format with:
- `dataset`: shape [N, 2, L], with real and imaginary parts in separate channels.
- `bits_*.h5`: optionally used for BER calculations.
- `*.json`: metadata including modulation, SINR, etc.

---

## **Training Modes**

### **1. Classic Autoencoder**
Uses the same input/target signal (e.g., clean only).
```bash
python train_unet_model_pytorch_interference.py /path/to/clean_h5_files /output/dir
```

### **2. Denoising Autoencoder **
Trains on (interfered → clean) signal pairs using matched JSON metadata.

```bash
python train_unet_model_pytorch_interference.py /clean_h5_dir /interf_h5_dir /output/dir /path/to/model.pth [final]
```

Arguments:

- ```clean_h5_dir```: clean signals

- ```interf_h5_dir```: interfered signals

- ```model.pth```: pretrained model or "None"

- ```final```: optional; if ```"true"``` or ```"final"```, saves final copy

#### Features
- Automatic JSON matching (ignoring SNR).

- Early stopping based on validation loss.

- Saves:

  - ```unet_best_model.pth```: best checkpoint.

  - ```training_metrics.json```: training/validation loss.

  - ```loss_curve.png```: loss plot.

## Inference
Run batch inference on any folder of HDF5 files:

```bash
python unet_inference_pytorch.py /path/to/model.pth /datasets_dir [/reference_dir]
```
#### Outputs:

Denoised ```.h5``` files saved to ```/datasets_dir_inference/.```

```mse_results.json```: (optional) average MSE per file.

## Environment Setup
#### Using Conda
Create environment from ```environment.yml```:

```bash
conda env create -f environment.yml
conda activate unet_env
```

If you want to export:

```bash
conda env export > environment.yml
```

## Dependencies
Key packages:

- ```torch```, ```numpy```, ```h5py```, ```matplotlib```, ```scikit-learn```

- Mixed precision support: torch.amp

- Dataset format: .h5 + metadata .json

## Performance Metrics
- MSE between output and reference signals

- BER (optional, requires ```bits_*.h5``` and MATLAB demod tools)

- Loss curves for training/validation

## Credits
Built upon UNet-inspired architectures adapted for 1D time-domain signal recovery. Developed in the context of wireless signal separation challenges, with influence from the ICASSP 2024 RF Signal Separation Challenge.
