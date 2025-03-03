from os import scandir, getcwd
import json
import h5py
import numpy as np
import matplotlib.pyplot as plt
import torch
import scipy.signal as signal
from torch.utils.data import DataLoader, Dataset
import ipywidgets as widgets
from IPython.display import display, clear_output

# List objects from current folder into a list
def ls(ruta = getcwd()):
    return [arch.name for arch in scandir(ruta) if arch.is_file()]

# List the modulations available in the datasets from current folder
def get_mods(ruta = getcwd()):
    list = ls(ruta)
    mods = []
    for object in list:
        if object.endswith('.json'):
          mods.append(object.replace('.json', ''))
    return sorted(mods)

def load_metadata(json_file):
    with open(json_file, 'r') as file:
        metadata = json.load(file)
    return metadata

# Print available modulations and main metadata about them in current folder
def print_mods(ruta = getcwd()):
    mods = get_mods(ruta)
    for mod in mods:
        metadata = load_metadata(mod + '.json')

        print(mod, ':')
        type_mod = metadata['type']
        if type_mod in metadata:
            print('  Modulation', type_mod, metadata[type_mod], '\n')
        else:
            print('  Modulation', type_mod, '\n')

def print_mods_full(mod):
    metadata = load_metadata(mod + '.json')

    type_mod = metadata['type']
    if type_mod in metadata:
        print(mod, ':' ' Modulation', type_mod, metadata[type_mod])
    else:
        print(mod, ':' ' Modulation', type_mod)

    for key in metadata:
        if key not in  ['type', 'mod', type_mod]:
            print('   ', key,':', metadata[key])
    print('\n')

# Function to be executed each time the user changes selection at Dropdown
def update_output(change):
    with output:
        clear_output(wait=True)  # Cleans previous output
        print_mods_full(change['new'])  # Displays the info from new selection




# Class for reading the datasets into dataloaders
class HDF5Dataset(Dataset):
    def __init__(self, hdf5_file):
        with h5py.File(hdf5_file, 'r') as f:
            self.data = f['dataset'][:]
        self.data = torch.tensor(self.data, dtype=torch.float32)

    def __len__(self):
        return self.data.shape[0]

    def __getitem__(self, idx):
        signal = self.data[idx]
        return signal

class HDF5Dataset_mixed(Dataset):
    def __init__(self, hdf5_file1, hdf5_file2, mix_factor=0.5):
        with h5py.File(hdf5_file1, 'r') as f:
            self.signal_soi = f['dataset'][:]

        with h5py.File(hdf5_file2, 'r') as f:
            self.signal_interf = f['dataset'][:]

        self.signal_soi = torch.tensor(self.signal_soi, dtype=torch.float32)
        self.signal_interf = torch.tensor(self.signal_interf, dtype=torch.float32)
        self.mix_factor = mix_factor

    def __len__(self):
        return self.signal_soi.shape[0]

    def __getitem__(self, idx):
        soi = self.signal_soi[idx]
        interf = self.signal_interf[idx]

        if interf.shape[1] > soi.shape[1]:
            interf = interf[:, :soi.shape[1]]

        elif interf.shape[1] < soi.shape[1]:
            # if the interference signal is shorter than the soi, the interference signal will be concatenated several times
            n_interf = -(-soi.shape[1] // interf.shape[1])

            interf = interf.repeat(1,n_interf)[:,:soi.shape[1]]

        mix = soi + self.mix_factor * interf

        return mix, soi


def to_complex_signal(signal_tensor):
    real_part = signal_tensor[:, 0]  # Real part
    imag_part = signal_tensor[:, 1]  # Imaginary part
    return real_part.numpy() + 1j * imag_part.numpy()

def plot_time_domain(signal, fs, title="Waveform", num_samples=20000):
    plt.figure(figsize=(20, 4))
    plt.plot(np.arange(num_samples) / fs, signal[:num_samples].real, label="Real")
    plt.plot(np.arange(num_samples) / fs, signal[:num_samples].imag, label="Imaginary", linestyle='dashed')
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.title(title)
    plt.legend()
    plt.grid()
    plt.show()

# Get constellation from OFDM waveform
def extract_ofdm_constellation(waveform, fft_size=64, cp_length=16, num_symbols=10, dc_null=True, guard_bands=(6,5)):
    ofdm_symbols = []

    for i in range(num_symbols):
        start_idx = i * (fft_size + cp_length) + cp_length  # Skip prefix length
        end_idx = start_idx + fft_size
        if end_idx > len(waveform):
            break

        ofdm_symbol = np.fft.fft(waveform[start_idx:end_idx], fft_size)

        # Get only useful subcarriers
        start_guard, end_guard = guard_bands
        if dc_null:
            ofdm_symbol = np.concatenate((ofdm_symbol[start_guard:fft_size//2],
                                          ofdm_symbol[fft_size//2 + 1:fft_size-end_guard]))
        else:
            ofdm_symbol = (ofdm_symbol[start_guard:fft_size-end_guard])

        ofdm_symbols.append(ofdm_symbol)

    symbols = np.concatenate(ofdm_symbols)
    return symbols[(np.abs(symbols.real) > 0.0000001) | (np.abs(symbols.imag) > 0.0000001)]

# Get constellation from Bluetooth waveform
def extract_bluetooth_constellation(waveform, samples_per_symbol):
    """

    Get constellation from Bluetooth waveform.

    Inputs:
    - waveform: Bluetooth waveform.
    - samples_per_symbol: Samples per symbol (metadata)

    Returns:
    - symbols: Bluetooth symbols.
    """

    symbols = waveform[::samples_per_symbol]

    symbols /= np.max(np.abs(symbols))  # Normalize

    return symbols

def despread_dsss(waveform, spreading_code):
    """
    Despreads DSSS signal from the expansion code

    Inputs:
    - waveform: DSSS waveform.
    - spreading_code: Expansion code (NumPy array: 1s and -1s).

    Returns:
    - symbols: DSSS symbols.
    """
    spreading_length = len(spreading_code)
    num_symbols = len(waveform) // spreading_length
    symbols = []

    for i in range(num_symbols):
        symbol_chunk = waveform[i * spreading_length : (i + 1) * spreading_length]
        despread_symbol = np.dot(symbol_chunk, spreading_code)
        symbols.append(despread_symbol)

    return np.array(symbols)

def extract_dsss_symbols(waveform, data_rate):
    """
    Get DSSS symbols according to datarate and documentation.

    Inputs:
    - waveform: DSSS waveform.
    - data_rate: Data rate in Mbps ('1Mbps', '2Mbps', '5.5Mbps', '11Mbps') (Metadata).

    Returns:
    - symbols: DSSS symbols.
    """
    if data_rate == '1Mbps':  # DBPSK with 11 chip Barker code
        spreading_code = np.array([1, 1, 1, -1, -1, -1, 1, -1, -1, 1, -1])  # Barker Code for 11 chips
        symbols = despread_dsss(waveform, spreading_code)

    elif data_rate == '2Mbps': # DQPSK with 11 chip Barker code
        spreading_code = np.array([1, 1, 1, -1, -1, -1, 1, -1, -1, 1, -1])
        symbols = despread_dsss(waveform, spreading_code)

    elif data_rate in ['5.5Mbps', '11Mbps']:  # CCK (CCK-4 and CCK-8)
        # For CCK symbols are collected without direct despread
        symbols = waveform[::11]  # Each symbol takes up 11 chips in CCK

    else:
        raise ValueError(f"Data rate '{data_rate}' not recognized. Please use '1Mbps', '2Mbps', '5.5Mbps' or '11Mbps'.")

    return symbols


def plot_constellation(symbols, title="Constelation"):
    """

    Inputs:
    - symbols: OFDM symbols.
    """
    plt.figure(figsize=(6, 6))
    plt.scatter(symbols.real, symbols.imag, alpha=0.6, s=10, color='blue')

    # Líneas de referencia en los ejes
    plt.axhline(0, color='gray', linestyle='--', linewidth=0.5)
    plt.axvline(0, color='gray', linestyle='--', linewidth=0.5)

    plt.xlim([-2, 2])
    plt.ylim([-2, 2])

    plt.xlabel("Real part")
    plt.ylabel("Imaginary part")
    plt.title(title)
    plt.grid()
    plt.show()

def plot_spectrum_analyzer(waveform, fs, title="Spectrum Analyzer"):
    """
    Plots signals spectrum using power spectral density (PSD)

    Inputs:
    - waveform: Waveform in time domain.
    - fs: Sample frequency in Hz.
    - title: Title.
    """
    f, Pxx = signal.welch(waveform, fs=fs, nperseg=4096, noverlap=2048, nfft=8192, return_onesided=False)

    Pxx_dB = 10 * np.log10(Pxx) # to dB

    center_idx = len(Pxx_dB) // 2  # Índice central del espectro
    Pxx_dB[center_idx] = np.nan  # Insertar un NaN en el centro para romper la línea

    plt.figure(figsize=(20, 4))
    plt.plot(f / 1e6, Pxx_dB, color='blue')  # to MHz
    plt.xlabel("Frequency (MHz)")
    plt.ylabel("Power (dB/Hz)")
    plt.title(title)
    plt.grid()
    plt.show()

def generate_5g_resource_grid(metadata):
    """
    5G resource grid representation from metadata

    Inputs:
    - metadata: json file with signal metadata.

    Returns:
    - resource_grid: Resource Grid matrix.
    """
    n_size_grid = metadata["nSizeGrid"]
    fft_size = n_size_grid * 12  # FFTLength = nSizeGrid * 12
    num_symbols = metadata["symAllocaition"][1]
    prb_set = metadata["PRBSet"]

    resource_grid = np.zeros((fft_size, num_symbols), dtype=float)

    # Simulate power for an empty Resource Gird
    for prb in prb_set:
        start_subcarrier = prb * 12
        end_subcarrier = start_subcarrier + 12
        resource_grid[start_subcarrier:end_subcarrier, :] = np.random.uniform(-30, 0, (12, num_symbols))

    return resource_grid

def plot_5g_resource_grid(resource_grid, title="Resource Grid 5G NR"):
    """
    Plots 5g Resource Grid.

    Inputs:
    - resource_grid: Matrix (subcarriers x OFDM symbols).
    """
    plt.figure(figsize=(10, 6))
    plt.imshow(20 * np.log10(np.abs(resource_grid + 1e-10)), aspect='auto', cmap='jet', interpolation='none')
    plt.colorbar(label="Power (dB)")
    plt.xlabel("OFDM symbols")
    plt.ylabel("Subcarriers")
    plt.title(title)
    plt.show()


def visualize_signal(hdf5_file, json_file, batch_size=1, plot_time = True, plot_constel = True, plot_spec = True):
    metadata = load_metadata(json_file)
    fs = metadata.get("fs", 20e6)  # If not exists, 20MHz by default

    dataset = HDF5Dataset(hdf5_file)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    signal_tensor = next(iter(dataloader))

    for i in range(batch_size):
        sig_tensor = signal_tensor[i].unsqueeze(0)
        sig_tensor = torch.transpose(sig_tensor.resize_(2, sig_tensor.shape[2]), 0, 1)

        complex_signal = to_complex_signal(sig_tensor.squeeze(0))

        if plot_time:
            plot_time_domain(complex_signal, fs, title="Time domain waveform")

        if plot_constel:
            if metadata['type'] == 'OFDM':
                plot_constellation(extract_ofdm_constellation(complex_signal,
                                                              fft_size = metadata['FFTLength'],
                                                              cp_length = metadata['cyclicPrefixLength'],
                                                              num_symbols = metadata['numSymbols'],
                                                              dc_null = metadata.get('DCnull', True)))

            if metadata['type'] == 'Bluetooth':
                plot_constellation(extract_bluetooth_constellation(complex_signal,
                                                                   samples_per_symbol = metadata['oversamplingFactor']))

            if metadata['type'] == 'WiFi' and metadata['WiFi'] == 'NonHT':
                plot_constellation(extract_dsss_symbols(complex_signal,
                                                        data_rate = metadata['dataRate']))

            if metadata['type'] == '5G - New Radio':
                plot_5g_resource_grid(generate_5g_resource_grid(metadata), title="Resource Grid 5G NR")


        if plot_spec:
            # Graficar el espectrograma
            plot_spectrum_analyzer(complex_signal, fs, title="Singal's Spectogram")


def visualize_signal_mixed(hdf5_file1, json_file1, hdf5_file2=None, json_file2=None, batch_size=1, plot_time=True, plot_constel=True, plot_spec=True, mix_factor=0.5):
    """
    Visualize pair or single signals (inteference + soi or soi).

    Inputs:
    - hdf5_file1, json_file1: HDF5 and json (metadata) files from SoI.
    - hdf5_file2, json_file2: (Optional) HDF5 and json (metadata) files from interferring signal.
    - batch_size: Number of signals to visualize.
    - plot_time, plot_constel, plot_spec: Visualization control.
    - mix_factor: Level of itnerference.
    """

    # Metadata
    metadata1 = load_metadata(json_file1)
    fs = metadata1.get("fs", 20e6)  # If not exist, 20MHz by default

    if hdf5_file2 and json_file2:
        dataset = HDF5Dataset_mixed(hdf5_file1, hdf5_file2, mix_factor)
        dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
        mixed_mode = True
    else:
        dataset = HDF5Dataset(hdf5_file1)
        dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
        mixed_mode = False

    # Sample from dataloader
    signal_batch = next(iter(dataloader))

    for i in range(batch_size):
        if mixed_mode:
            mixed_signal, soi_signal = signal_batch

            # To complex form
            mixed_signal = torch.transpose(mixed_signal.resize_(2, mixed_signal.shape[2]), 0, 1)
            soi_signal = torch.transpose(soi_signal.resize_(2, soi_signal.shape[2]), 0, 1)

            print(f"SOI shape: {soi_signal.shape}, Interference shape: {mixed_signal.shape}")

            mixed_complex = to_complex_signal(mixed_signal.squeeze(0))
            soi_complex = to_complex_signal(soi_signal.squeeze(0))
            print(f"SOI shape: {soi_complex.shape}, Interference shape: {mixed_complex.shape}")

        else:
            soi_signal = signal_batch[i].unsqueeze(0)
            soi_signal = torch.transpose(soi_signal.resize_(2, soi_signal.shape[2]), 0, 1)

            soi_complex = to_complex_signal(soi_signal.squeeze(0))

        # Plots
        if plot_time:
            if mixed_mode:
                plot_time_domain(mixed_complex, fs, title="Interference Signal (SOI + Interference)")

            plot_time_domain(soi_complex, fs, title="Signal of Interest (SOI)")

        if plot_constel:
            if metadata1['type'] == 'OFDM':
                if mixed_mode:
                    plot_constellation(extract_ofdm_constellation(mixed_complex,
                                                                fft_size=metadata1['FFTLength'],
                                                                cp_length=metadata1['cyclicPrefixLength'],
                                                                num_symbols=metadata1['numSymbols'],
                                                                dc_null = metadata1.get('DCnull', True)),
                                    title="Interference constellation")

                plot_constellation(extract_ofdm_constellation(soi_complex,
                                                                fft_size=metadata1['FFTLength'],
                                                                cp_length=metadata1['cyclicPrefixLength'],
                                                                num_symbols=metadata1['numSymbols']),
                                    title="SoI constellation")

            if metadata1['type'] == 'Bluetooth':
                if mixed_mode:
                    plot_constellation(extract_bluetooth_constellation(mixed_complex,
                                                                    samples_per_symbol=metadata1['oversamplingFactor']),
                                    title="Interference constellation")

                plot_constellation(extract_bluetooth_constellation(soi_complex,
                                                                samples_per_symbol=metadata1['oversamplingFactor']),
                                title="SoI constellation")

            if metadata1['type'] == 'WiFi' and metadata1['WiFi'] == 'NonHT':
                if mixed_mode:
                    plot_constellation(extract_dsss_symbols(mixed_complex, data_rate=metadata1['dataRate']),
                                    title="Interference constellation")

                plot_constellation(extract_dsss_symbols(soi_complex, data_rate=metadata1['dataRate']),
                                   title="SoI constellation")

            if metadata1['type'] == '5G - New Radio':
                plot_5g_resource_grid(generate_5g_resource_grid(metadata1), title="Resource Grid 5G NR")

        if plot_spec:
            if mixed_mode:
                plot_spectrum_analyzer(mixed_complex, fs, title="Interference Spectogram")

            plot_spectrum_analyzer(soi_complex, fs, title="SoI Spectogram")



def execute_visualization(b):
    with output:
        clear_output(wait=True)

        # Ensure at least one visualization option is selected
        if not (plot_time_checkbox.value or plot_spectrogram_checkbox.value or plot_constellation_checkbox.value):
            print("ERROR: You must select at least one visualization option.")
            return

        if dropdown_mod1.value == '---':
            print("ERROR: You must select at least one modulation option.")
            return

        if (signal_type_selector.value == "Interference") and (dropdown_mod2.value == '---'):
            print("ERROR: You must select at least one modulation option for the interference. Otherwise, you can change to 'Single Signal'")
            return

        print("It may take a while for the visualizations to load...")

        batch_size = numSignals.value

        plot_time = plot_time_checkbox.value
        plot_spec = plot_spectrogram_checkbox.value
        plot_constel = plot_constellation_checkbox.value

        if signal_type_selector.value == "Single Signal":
            mod = dropdown_mod1.value
            h5file = mod + '.h5'
            jsonfile = mod + '.json'
            visualize_signal(h5file, jsonfile, batch_size,
                             plot_time=plot_time,
                             plot_spec=plot_spec,
                             plot_constel=plot_constel)

        elif signal_type_selector.value == "Interference":
            mod1 = dropdown_mod1.value
            mod2 = dropdown_mod2.value
            h5file1 = mod1 + '.h5'
            jsonfile1 = mod1 + '.json'
            h5file2 = mod2 + '.h5'
            jsonfile2 = mod2 + '.json'
            visualize_signal_mixed(h5file1, jsonfile1, h5file2, jsonfile2, batch_size,
                                   plot_time=plot_time,
                                   plot_spec=plot_spec,
                                   plot_constel=plot_constel,
                                   mix_factor=mix_factor.value)

