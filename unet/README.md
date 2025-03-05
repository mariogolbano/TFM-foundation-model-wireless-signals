# **Deep Learning-Based Signal Recovery: UNet1D Model**

## **Overview**
This folder contains the implementation of a **1D U-Net model (UNet1D)** designed for **signal recovery and interference suppression in the wireless spectrum**. The model is specifically tailored for processing **wireless signals represented in the time domain** and aims to **separate the signal of interest (SoI) from interfering components**.

The project leverages **deep learning techniques** to improve **signal separation and denoising**, making it suitable for applications in **wireless communication, spectrum sensing, and cognitive radio networks**.

---

## **About this Repository**
This repository contains:
- **A modified U-Net architecture (`UNet1D`)** implemented in PyTorch for **1D signal processing**.
- **A dataset loader (`HDF5Dataset`)** to read and preprocess wireless signals stored in **HDF5 format**.
- **Training and validation scripts** with support for **early stopping** and **automatic checkpointing**.
- **Loss visualization** and **performance evaluation** tools.

The model is trained on **wireless signal datasets** that contain **modulated signals with varying levels of interference**. The goal is to **estimate the clean signal of interest (SoI)** from the provided mixture of signals.

---

## **Model Architecture: UNet1D**
The **UNet1D** model follows a **fully convolutional encoder-decoder structure**, adapted for **1D time-series signals**.

### **Key Features**
- **Multi-scale feature extraction** using **downsampling (encoder) and upsampling (decoder) layers**.
- **Skip connections** to preserve fine-grained signal details during reconstruction.
- **Customizable kernel sizes** for better frequency domain representation.
- **Residual blocks** to enhance gradient flow and stability.
- **Dropout layers** to improve generalization.

### **Network Structure**
- **Encoder**:
  - Five convolutional blocks (`Conv1d` + `ReLU`).
  - **Max-pooling** for downsampling.
  - **Dropout layers** to prevent overfitting.
- **Middle layer**:
  - Two convolutional layers for **bottleneck feature extraction**.
- **Decoder**:
  - Five transposed convolutional layers (`ConvTranspose1d`) for upsampling.
  - Skip connections between corresponding encoder and decoder layers.
- **Output layer**:
  - A `1x1 Conv1d` layer to generate the recovered signal.

### **Input and Output**
- **Input**: Noisy/interfered wireless signals (complex-valued, represented as real + imaginary channels).
- **Output**: Estimated clean signal of interest (SoI).

---

## **Dataset Format**
The model is trained using **datasets stored in HDF5 format**. The dataset consists of:
- **Complex-valued wireless signals** stored as separate real and imaginary parts.
- **Modulated signals with interference** at varying Signal-to-Interference Ratios (SINR).
- **Ground-truth clean signals** for supervised learning.

Each dataset file contains:
- `dataset/`: A NumPy array with the modulated signals.
- `metadata.json`: A file storing dataset parameters (modulation type, signal properties, etc.).

---

## **Training Pipeline**
### **1. Data Preparation**
The dataset is loaded using the `HDF5Dataset` class, which:
- Reads the HDF5 files.
- Extracts real and imaginary components as separate input channels.
- Normalizes signals before feeding them into the model.

### **2. Model Training**
The training is managed by `train_unet_pytorch.py`, which:
- Loads the dataset.
- Splits data into **training (90%)** and **validation (10%)** sets.
- Uses **Mean Squared Error (MSE) loss** for training.
- Implements **Adam optimizer** with a learning rate of **0.0003**.
- Utilizes **gradient scaling (`GradScaler`)** for mixed precision training.
- Applies **early stopping** if validation loss does not improve for **10 epochs**.

#### **Command to Train the Model**
```bash
python train_unet_pytorch.py /path/to/dataset /path/to/output_directory
```
Example:
```bash
python train_unet_pytorch.py ./datasets ./results
```

### **3. Checkpointing**
- The best model is **automatically saved** as `unet_best_model.pth` in the output directory.
- **Training metrics (loss curves) are logged** in `training_metrics.json`.

### **4. Loss Curve Visualization**
After training, the script generates a **loss curve plot**:
```bash
python plot_loss.py /path/to/output_directory
```

---

## **Testing and Evaluation**
Once trained, the model can be used for **inference** on new signal datasets.

### **1. Running Inference**
To apply the trained model to new signals:
```bash
python test_unet.py /path/to/test_dataset /path/to/saved_model
```

### **2. Evaluation Metrics**
The model's performance is evaluated using:
- **Mean Squared Error (MSE)**
- **Signal-to-Noise Ratio (SNR) improvement**
- **Bit Error Rate (BER) (for demodulated signals)**

---

## **Dataset Storage and Availability**
- The datasets used in this project **are not stored in the repository** due to size limitations.
- A link to the preprocessed datasets is available here:  
  **[Google Drive Link]** *(To be added by the user)*
- Users can also generate datasets using the **MATLAB dataset generation GUI**.

---

## **Environment Setup**
### **1. Install Dependencies**
To set up the environment, install the required packages:
```bash
pip install numpy matplotlib h5py torch scipy json
```

### **2. Check GPU Availability**
To ensure PyTorch detects the GPU, run:
```python
import torch
print(torch.cuda.is_available())
```
If it returns `True`, the model will automatically use the **GPU**.

---

## **Modifications from Original ICASSP 2024 Challenge Baseline**
This model is based on a **modified version of the original UNet** used in the **ICASSP 2024 SP Grand Challenge**, but with the following improvements:
- **1D architecture** optimized for **wireless signals**.
- **Expanded encoder-decoder depth** for better feature extraction.
- **Dynamic kernel size selection** to enhance frequency response.
- **Dropout and batch normalization** for improved generalization.
- **Optimized data pipeline** using HDF5 storage.

Unlike the ICASSP baseline, this implementation focuses **exclusively on single-channel time-domain signal recovery**, without relying on multi-channel processing.

---

## **Support and Contributions**
If you encounter issues or have suggestions for improvements, please submit an **issue** or a **pull request** in this repository.