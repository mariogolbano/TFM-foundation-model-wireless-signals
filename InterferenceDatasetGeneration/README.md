# **Wireless Interference Dataset Generator**

## **Overview**
This module allows for **automated creation of interference-corrupted wireless signal datasets** by combining clean signals with interference sources. It simulates realistic signal degradation by adjusting the **interference strength via attenuation factors** and outputs the result in **HDF5 format**, compatible with deep learning pipelines like UNet1D-based denoising.

---

## **Core Functionality**
The script `generate_interferences.py`:
- Iterates over all combinations of **clean and interference signals**.
- Applies **multiple attenuation factors**.
- Generates new `.h5` datasets representing interfered signals.
- **Preserves and copies metadata** (`.json`, `.mat`, `bits_*.h5`) for traceability.

---

## **Main Script**
### `generate_interferences.py`

#### **How It Works**
- For every clean file and interference source, a set of interference levels is applied.
- The new signals are stored in subdirectories like:
```

interference/interference\_\<interf\_file>\_\<att\_level>/

```

#### **Run Command**
Edit the top of the script with:
```python
clean_dir = './path/to/clean'
interf_dir = './path/to/interference'
base_output_dir = './path/to/output'
att_factors = [0.5, 0.75]  # Example attenuation levels
```

Then execute:

```bash
python generate_interferences.py
```

---

## **Key Function: create\_interference\_dataset**

### Inputs:

* `clean_h5_path`: Clean dataset file (`.h5`)
* `interf_h5_path`: Interference dataset file (`.h5`)
* `attenuation_factor`: Float between 0 and 1
* `new_name`: Optional; path prefix for output file

### Behavior:

* Lengths are matched automatically using repetition or truncation.
* Channel mismatches are flagged.
* Metadata is preserved from the clean file.

---

## **Utilities Provided**

### `utils.py`

Contains the following tools:

* `adjust_signal_length()`: Pads/truncates interference signals.
* `create_interference_dataset()`: Adds scaled interference and writes to new `.h5` with attributes.

---

## **Output Structure**

For each interference combination:

```
output_dir/
├── interference_interfererX_050/
│   ├── sampleY.h5              ← Interfered data
│   ├── sampleY.json            ← Metadata
│   ├── sampleY.mat             ← Optional signal content
│   └── bits_sampleY.h5         ← Bitstream file (if exists)
```

---

## **Dependencies**

Ensure these packages are installed:

```bash
pip install numpy h5py
```

For ease of setup, include these tools in your root `environment.yml`.

---

## **Use Case**

This tool is essential for:

* Generating **diverse training datasets** for denoising models.
* Evaluating the **robustness of signal recovery architectures** under varied interference.
* Creating **controlled experiments** with known SNR/SINR levels.

