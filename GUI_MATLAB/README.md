# **MATLAB GUI for Wireless Signal Dataset Generation**

## **Overview**
This folder contains a MATLAB-based **Graphical User Interface (GUI)** designed for generating wireless signal datasets. The system supports various modulation schemes, video-based encoding, and signal processing functions to create realistic datasets for machine learning and signal recovery research. 

The GUI allows users to:
- Select different modulation types, including WiFi (multiple variants), 5G, Bluetooth, DSSS, and OFDM.
- Process and integrate video data as part of the signal encoding.
- Apply transformations and impairments to simulate real-world communication scenarios.
- Store generated signals in structured datasets for further analysis.

The functions in this folder are specifically designed to generate signals **from video inputs**, encoding the video information into wireless signals. This approach allows for a diverse and complex dataset, useful for training machine learning models in signal processing and wireless communication tasks.

## **Components and Functionality**

### **Dataset Generation System**
- **`DatasetGeneration.m`**: The main script that orchestrates the dataset generation process. It calls the necessary modulation and processing functions, integrates video inputs, and stores the resulting datasets.
- **`ModulationProcessingGUI.m`**: Handles additional signal processing steps after modulation, allowing users to apply transformations or analyze the modulated signals.
- **`ModulationSelectionGUI.m`**: A GUI component that allows users to select the modulation scheme to apply to the signals.
- **`VideoSelectionGUI.m`**: Provides an interface for selecting video files that can be used as input for signal encoding.
- **`PreprocessedVideosGUI.m`**: Manages preprocessed videos, ensuring they are in the correct format and properly integrated into the dataset generation pipeline.

### **Modulation Functions**
The system supports multiple modulation schemes, each implemented in a separate function:
- **WiFi (802.11ax, 802.11ac, Non-HT)**: `WifiHESU_mod.m`, `WifiVHT.m`, `WifiNonHT_mod.m`
- **5G Modulation**: `5G_mod.m`
- **Bluetooth Modulation**: `Bluetooth_mod.m`
- **DSSS (Direct Sequence Spread Spectrum)**: `DSSS_mod.m`
- **OFDM (Orthogonal Frequency Division Multiplexing)**: `OFDM_mod.m`

These functions, located in the `funcs/mods/` directory, generate baseband modulated signals based on user-selected parameters.

### **Video Processing**
- **`processVideo.m`**: Handles video preprocessing, extracting necessary features or converting video data into a format suitable for modulation.
- **`cck_chips.m`**: Assists in Complementary Code Keying (CCK) processing, relevant for some modulation types.

## **Generating a Dataset**
### **1. Setup**
Ensure MATLAB is installed with the required toolboxes, including:
- Signal Processing Toolbox
- Communications Toolbox
- Computer Vision Toolbox (if using video input)

### **2. Running the GUI**
Open MATLAB and navigate to the `GUI_MATLAB` directory. Run:

```matlab
DatasetGeneration
```

This launches the main GUI, allowing the user to configure dataset parameters.

### **3. Selecting Modulation and Input Data**
1. Choose a **modulation scheme** via `ModulationSelectionGUI.m`.
2. Upload a **video input** through `VideoSelectionGUI.m`. The video will be processed using `processVideo.m` before being integrated into the signal generation.

### **4. Signal Processing and Storage**
Once modulation is applied:
- The system processes the signals, applying optional transformations or impairments.
- The generated signals are saved into a structured dataset, which includes both clean and impaired versions.

## **Video Input and Availability**
The signal generation process relies on **video-based encoding**, where video frames are modulated into wireless signals. However, the videos used during development **are not included in this repository** due to storage limitations.

A set of preprocessed videos can be accessed through the following link:  
**[Google Drive Link]** *(To be added by the user)*  

Alternatively, users can use **any other video or set of videos** in **MP4 format**. The `processVideo.m` function handles preprocessing, ensuring compatibility with different video sources.

To use custom videos:
1. Place the `.mp4` files in the appropriate directory.
2. Select them in `VideoSelectionGUI.m`.
3. The system will process them before modulation.

## **Additional Notes**
- **Datasets are not included in the repository** due to storage limitations. Users must manually generate them using the GUI.
- If any modulation functions are missing or producing errors, verify their presence in the `funcs/mods/` directory.
- The system is modular, allowing users to extend functionality by adding new modulation schemes or processing steps.

## **Support and Contributions**
For any issues, suggestions, or improvements, refer to the main repository for documentation or submit an issue.
