# **Dataset Visualization Notebook**

## **Overview**
This folder contains a **Jupyter Notebook** designed for **visualizing wireless signal datasets** stored in **HDF5 format**. The notebook provides an interactive interface using `ipywidgets`, allowing users to explore and analyze different modulation schemes, visualize signal properties, and compare clean signals with interference.

The key functionalities include:
- Loading datasets and extracting metadata.
- Selecting different modulation types for visualization.
- Comparing **single signals** or **interference scenarios**.
- Displaying time-domain waveforms, spectrograms, and constellations.
- Providing interactive controls for flexible analysis.

## **Components and Functionality**

### **Main Notebook**
- **`dataset_visualization.ipynb`**: The primary notebook for interactive signal exploration.
- **`aux_funcs_vis.py`**: A helper script containing functions for data loading, signal processing, and visualization.

### **Interactive Widgets**
The notebook includes a set of interactive widgets that allow users to configure the visualization parameters:
- **Modulation selection**: Users can select a modulation type from the available dataset.
- **Visualization type**: Single signal or interference mode.
- **Number of signals**: Choose how many signals to visualize.
- **Mix factor**: Adjust the interference level.
- **Visualization options**: Enable or disable time-domain plots, spectrograms, or constellation diagrams.
- **Execution button**: Runs the selected visualization.

## **Supported Visualization Modes**
1. **Single Signal Analysis**
   - Visualize a single signal from the dataset.
   - Available modulation types include:
     - **WiFi (802.11ax, 802.11ac, Non-HT)**
     - **5G New Radio**
     - **Bluetooth**
     - **DSSS**
     - **OFDM**
   - Outputs:
     - Time-domain waveform.
     - Spectrogram.
     - Constellation diagram (if applicable).

2. **Interference Analysis**
   - Allows selecting two signals: a **signal of interest (SoI)** and an **interfering signal**.
   - Adjustable interference level using the **mix factor**.
   - Outputs:
     - Comparison of SoI and interference signal.
     - Mixed waveform visualization.
     - Spectrogram and constellation diagram.

## **Visualization Functions**
The dataset visualization relies on a set of helper functions from `aux_funcs_vis.py`:

- **Dataset Handling**
  - `ls()`: Lists available files in the dataset folder.
  - `get_mods()`: Retrieves available modulation types.
  - `load_metadata()`: Loads metadata from JSON files.
  - `print_mods()`: Displays a summary of available modulations.

- **Signal Processing**
  - `HDF5Dataset`: Class for reading HDF5 datasets.
  - `HDF5Dataset_mixed`: Class for loading mixed datasets (SoI + interference).
  - `to_complex_signal()`: Converts real-valued tensors into complex signals.

- **Visualization**
  - `plot_time_domain()`: Plots signal waveforms.
  - `plot_spectrum_analyzer()`: Computes and displays power spectral density.
  - `plot_constellation()`: Generates constellation diagrams.
  - `extract_ofdm_constellation()`: Extracts OFDM symbol constellations.
  - `extract_bluetooth_constellation()`: Extracts Bluetooth modulations.
  - `extract_dsss_symbols()`: Processes DSSS symbols.
  - `generate_5g_resource_grid()`: Generates a 5G resource grid.
  - `plot_5g_resource_grid()`: Visualizes the 5G resource grid.

- **Execution Functions**
  - `visualize_signal()`: Plots signals from a selected dataset.
  - `visualize_signal_mixed()`: Plots interference scenarios.

## **How to Use**
### **1. Setup**
Ensure the following dependencies are installed:
```bash
pip install numpy matplotlib h5py scipy torch ipywidgets
```
Additionally, ensure that Jupyter Notebook is installed and available.

### **2. Running the Notebook**
Launch Jupyter Notebook and open `dataset_visualization.ipynb`:
```bash
jupyter notebook dataset_visualization.ipynb
```
Alternatively, if using Google Colab, mount Google Drive and navigate to the dataset folder.

### **3. Selecting Parameters**
- Choose **modulation type** from the dropdown menu.
- Select whether to analyze a **single signal** or an **interference scenario**.
- Adjust the **number of signals** and **interference mix factor**.
- Enable or disable **time-domain plots, spectrograms, or constellations**.
- Click the **Visualize** button to generate the plots.

### **4. Interpreting the Results**
- **Time-domain waveform**: Shows the real and imaginary parts of the signal over time.
- **Spectrogram**: Displays the frequency content of the signal.
- **Constellation diagram**: Provides insights into the modulation properties (only for applicable modulations).

## **Dataset and Storage Notes**
- The dataset consists of **HDF5 files**, each corresponding to a different modulation type.
- Each modulation type is stored as an **HDF5 file** (`modulation.h5`) with accompanying **metadata in JSON format** (`modulation.json`).
- **The dataset files are not included in the repository** due to storage limitations.
- Users can generate their own datasets using the **MATLAB GUI** and save them in the appropriate format.

## **Additional Notes**
- If dataset files are missing, ensure they are properly placed in the dataset directory.
- The visualization supports only **MP4-based datasets** generated by the MATLAB signal encoding system.
- If errors occur while running the notebook, check for missing dependencies or dataset files.

## **Support and Contributions**
For any issues, suggestions, or improvements, refer to the main repository for documentation or submit an issue.