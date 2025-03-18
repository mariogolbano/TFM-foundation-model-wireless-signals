# **MATLAB GUI for Wireless Signal Demodulation and Visualization**

## **Overview**  
This directory contains a **MATLAB-based Graphical User Interface (GUI)** for **demodulation and visualization of wireless signals**. The system allows users to analyze received signals, inspect impairments, and compare original vs. recovered signals.

The GUI enables users to:  
- **Demodulate signals** from various wireless communication standards (WiFi, Bluetooth, DSSS, OFDM, 5G).  
- **Visualize signals** in the time and frequency domains (waveforms, spectrograms, constellation diagrams).  
- **Inspect datasets** stored in HDF5 format, compare interference effects, and evaluate demodulation accuracy.

---

## **Components and Functionality**

### **Demodulation and Visualization System**
- **`DemodulateDatasets.m`** → **Main script** that launches the GUI, allowing users to select and process datasets for demodulation and visualization.
- **`DemodulationGUI.m`** → Handles the actual **demodulation process**, extracting transmitted bit sequences and reconstructing signals.
- **`DemodulationOrVisualizationGUI.m`** → Interface for selecting whether to **demodulate signals** or **visualize dataset properties**.
- **`SelectSignalsGUI.m`** → GUI component for **selecting specific signals** for analysis and comparison.
- **`VisualizeSignalsGUI.m`** → GUI tool for **visualizing wireless signals**, supporting **waveforms, spectrograms, and constellations**.

---

## **Demodulation Features**
- Supports **WiFi (802.11ax, 802.11ac, Non-HT), Bluetooth, DSSS, OFDM, and 5G** demodulation.
- Extracts **transmitted bit sequences** from received signals.
- Evaluates **bit error rate (BER)** and other **performance metrics**.
- Handles **interference scenarios** to assess signal separation capabilities.

---

## **Visualization Features**
- **Time-Domain Waveforms** → Inspect modulation quality and impairments.
- **Spectrograms** → Analyze frequency content over time.
- **Constellation Diagrams** → Evaluate modulation accuracy and symbol distribution.
- **Power Spectral Density (PSD) Plots** → Compare original vs. received signals.

---

## **How to Use**

### **1. Setup**
Ensure MATLAB is installed with the required toolboxes:  
- **Signal Processing Toolbox**  
- **Communications Toolbox**  

### **2. Running the GUI**
Open MATLAB and navigate to the `DatasetDemodulationVisualization_GUI_MATLAB` directory. Run:  
```matlab
DemodulateDatasets
```  
This will launch the **main GUI**, allowing you to load datasets, analyze signals, and generate plots.

### **3. Selecting a Signal for Demodulation**
1. **Select a dataset folder** containing `.mat` files with metadata.
2. Choose a **modulation type** (WiFi, DSSS, Bluetooth, OFDM, 5G).
3. Click **"Continue"** to proceed to the next step.
4. The system will load the selected modulation and display its parameters.

### **4. Running the Demodulation**
1. The `DemodulationGUI.m` tool will take the selected dataset and apply **demodulation algorithms**.
2. The extracted **bit sequences** will be displayed.
3. The tool calculates **BER (Bit Error Rate)** and compares the reconstructed signal with the original.

### **5. Signal Visualization**
- Open `VisualizeSignalsGUI.m` to inspect dataset properties.
- Select a signal and choose from different visualization options:
  - **Waveform**
  - **Spectrogram**
  - **Constellation Diagram**
  - **Power Spectrum**

---

## **Dataset Availability**
The datasets used in this project **are not stored in this repository** due to storage limitations. Instead, they can be accessed via a **Google Drive link**, which will be provided separately.

Users can also generate their own datasets using the **MATLAB dataset generation GUI**.

---

## **Support and Contributions**
For issues, questions, or contributions:  
- Open an **issue** in this repository.  
- Submit a **pull request** with improvements.  
- Contact the maintainers for collaboration.