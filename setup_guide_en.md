# Setup Guide: Building a Single-Cell Analysis Environment

This [guide](https://github.com/juninamo/SoM_class/blob/main/setup_guide_jp.md) provides instructions for setting up the environment required for the single-cell analysis workshop. It is compatible with both **macOS** and **Windows**.

> **⚠️ Important: About Versions**
> This guide specifies **precise version numbers** to ensure reproducibility.
> To reproduce the results in the lecture material (`single_cell_analysis_T.html`), please use the specified versions as much as possible.

---

## 0. Required PC Specifications

Single-cell analysis is memory-intensive. The following specifications are recommended.

| Item | Recommended Spec |
|------|-----------|
| OS | macOS 13+ / Windows 10 (64-bit)+ |
| Memory (RAM) | **8 GB+** (16 GB recommended) |
| Disk Space | **10 GB+** |
| CPU | Intel / Apple Silicon (M1/M2/M3/M4) |

---

## 1. How to Use the Command Line (Terminal)

In this guide, we will use the command line (Terminal) to install the software.
The command line is a tool for giving instructions to your computer using text.

### For macOS

1. Use **Spotlight Search** (`Command ⌘` + `Space`) and type "**Terminal**".
2. Open the **Terminal.app**.
3. You are ready when a black screen with text appears.

> **💡 Hint**: You can also open it from Launchpad → Other → Terminal.

### For Windows

Windows has several command-line tools, but in this guide, we will use the **Miniforge Prompt** (which will be installed in Section 2).

If you want to check if the command line works before installing Miniforge, you can open **PowerShell**:

1. Press the **`Windows` key** and type "**PowerShell**".
2. Click and open **Windows PowerShell**.
3. You are ready when a blue screen displays `PS C:\Users\(username)>`.

> **⚠️ Note (Windows)**: For Section 2 and onwards, always use the **Miniforge Prompt**.
> The Miniforge Prompt is a command line specifically configured to use Conda commands.

### How to Execute Commands

On the command line, type the command after the prompt (after `$` or `>`) and press the **Enter key** to execute it.
Please copy and paste the text from the code blocks in this guide **one line at a time** and execute them.

```bash
# This line is a "comment" (lines starting with # are not executed)
# Below is an example of a command:
conda --version
```

---

## 2. Installing Conda (Miniforge)

We will use **Conda** to install everything, including R itself and R packages.
Conda allows you to specify exact versions and manage environments separately.

### For macOS

Open the Terminal and execute the following.

#### For Apple Silicon (M1/M2/M3/M4) Mac

```bash
# Download the Miniforge installer
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"

# Install (Please proceed with the default settings)
bash Miniforge3-MacOSX-arm64.sh
```

#### For Intel Mac

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
bash Miniforge3-MacOSX-x86_64.sh
```

After installation, **close the Terminal and reopen it**.
You have successfully installed it if `(base)` appears at the beginning of the prompt.

### For Windows

1. Go to the [Miniforge Download Page](https://github.com/conda-forge/miniforge/releases/latest).
2. Download and run **`Miniforge3-Windows-x86_64.exe`**.
3. During the installation setup:
   - Check ☑️ **"Add Miniforge3 to my PATH environment variable"**.
   - Check **"Register Miniforge3 as my default Python"**.
4. After installation, open the **Start Menu**, search for "**Miniforge Prompt**", and open it.

> **💡 Hint (Windows)**: Perform all subsequent tasks in the **Miniforge Prompt**.
> The `conda` command may not work in the regular Command Prompt or PowerShell.

---

## 3. Creating a Conda Environment and Installing Software

Enter and execute the following commands **one line at a time** in the Terminal (macOS) or Miniforge Prompt (Windows).

### Step A. Creating the Conda Environment (R 4.3.2)

#### For macOS

```bash
# Create an environment named scworkshop
# This installs R 4.3.2 and RStudio simultaneously
conda create -n scworkshop -c conda-forge r-base=4.3.2 rstudio=2024.04.2 -y
```

#### For Windows

Since RStudio cannot be installed via Conda on Windows, only R will be installed.

```bash
# Create an environment named scworkshop (R 4.3.2 only)
conda create -n scworkshop -c conda-forge r-base=4.3.2 -y
```

> **⏱ Note**: Initial installation may take 10–20 minutes. Please wait even if it seems to have stopped.

> **⚠️ If an error occurs with the version specification**:
> Remove the version numbers such as `=4.3.2` or `=2024.04.2` and try again.
> Example:
> ```bash
> # macOS (without version)
> conda create -n scworkshop -c conda-forge r-base rstudio -y
> # Windows (without version)
> conda create -n scworkshop -c conda-forge r-base -y
> ```

### Step B. Activating the Environment

```bash
# Activate the environment (Always run this command first for subsequent tasks)
conda activate scworkshop
```

Confirm that the beginning of the prompt has changed to `(scworkshop)`.

> **⚠️ Important**: You must run `conda activate scworkshop` every time you open the Terminal / Miniforge Prompt.

### Step C. Installing R Packages (via Conda)

Install the packages used in `single_cell_analysis_T.Rmd`.

```bash
# CRAN Packages
conda install -c conda-forge \
  r-seurat=5.2.1 \
  r-patchwork=1.1.3 \
  r-dplyr=1.1.4 \
  r-magrittr=2.0.3 \
  r-rmarkdown=2.25 \
  r-knitr=1.45 \
  r-bookdown=0.37 \
  -y
```

> **💡 Note for Windows**: The `\` (backslash, line continuation character) may not work on Windows.
> In that case, combine everything into **one line**:
> ```bash
> conda install -c conda-forge r-seurat=5.2.1 r-patchwork=1.1.3 r-dplyr=1.1.4 r-magrittr=2.0.3 r-rmarkdown=2.25 r-knitr=1.45 r-bookdown=0.37 -y
> ```

> **⚠️ If an error occurs with the version specification**:
> Remove all version numbers such as `=5.2.1` and try again.
> ```bash
> conda install -c conda-forge r-seurat r-patchwork r-dplyr r-magrittr r-rmarkdown r-knitr r-bookdown -y
> ```

### Step D. Installing Bioconductor Packages (via Conda)

```bash
# Install BiocStyle from the Bioconda channel
conda install -c bioconda -c conda-forge \
  bioconductor-biocstyle=2.30.0 \
  -y
```

> **💡 Windows One-Line Version**:
> ```bash
> conda install -c bioconda -c conda-forge bioconductor-biocstyle=2.30.0 -y
> ```

> **⚠️ If an error occurs with the version specification**:
> ```bash
> conda install -c bioconda -c conda-forge bioconductor-biocstyle -y
> ```

---

## 4. Installing and Launching RStudio

### For macOS

RStudio was installed along with Conda in Step A. Launch it from the Terminal:

```bash
# Activate the environment (if not already done)
conda activate scworkshop

# Launch RStudio
rstudio &
```

> **⚠️ Note (macOS)**: Do not launch RStudio from the desktop shortcut; always launch it using the command above.
> If you don't use the command, the R in the Conda environment might not be utilized.

### For Windows

On Windows, install RStudio manually and configure it to use R from the Conda environment.

#### 1. Installing RStudio

1. Go to [posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/).
2. Download and run the Windows installer for the **Free version**.

#### 2. Launching RStudio from the Miniforge Prompt

Since R installed via Conda is not registered in the Windows registry, it cannot be selected from the RStudio settings (Global Options).
Instead, **set an environment variable and launch RStudio from the Miniforge Prompt**.

Open the Miniforge Prompt and **execute the following 3 lines every time**:

```bash
conda activate scworkshop
set RSTUDIO_WHICH_R=%CONDA_PREFIX%\Scripts\R.exe
"C:\Program Files\RStudio\rstudio.exe"
```

> **⚠️ If an error occurs with the path above**: The installation location of RStudio might be different.
> Try the following path as well:
> ```bash
> "C:\Program Files\RStudio\bin\rstudio.exe"
> ```
> If it still isn't found, right-click "RStudio" in the Start Menu → "Open file location" to check the path.

> **💡 Explanation**: `RSTUDIO_WHICH_R` is an environment variable that tells RStudio "which R to use".
> If you launch it this way, the R in the Conda environment will be used automatically.

> **💡 Confirmation**: Once RStudio launches, confirm that `R version 4.3.2` is displayed in the Console (bottom-left panel).

> **⚠️ Note**: Do not launch RStudio from the desktop or Start Menu shortcut.
> Always follow the procedure above to launch from the Miniforge Prompt.

#### (Alternative) Using R Directly Without RStudio

If the above method doesn't work, you can launch R directly from the Miniforge Prompt:

```bash
conda activate scworkshop
R
```

The R console will appear, so you can enter and execute commands directly.

---

## 5. Preparing Data

### A. Creating a Project Folder

Create a project folder on your Desktop.

#### For macOS (Terminal)
```bash
# Navigate to Desktop
cd ~/Desktop

# Create a folder
mkdir SingleCellWorkshop
cd SingleCellWorkshop

# Create a data folder
mkdir data
```

#### For Windows (Miniforge Prompt)
```bash
# Navigate to Desktop
cd %USERPROFILE%\Desktop

# Create a folder
mkdir SingleCellWorkshop
cd SingleCellWorkshop

# Create a data folder
mkdir data
```

#### Folder Structure Image
The structure after creation will look like this:
```
SingleCellWorkshop/
├── data/
│   ├── JIAsyno_CITEseq_T_share.rds         (Data for T-cell analysis)
│   ├── JIAsyno_CITEseq_T_full.rds          (Full data for verification)
│   └── JIAsyno_CITEseq_full.rds            (Data for overall analysis)
├── single_cell_analysis.Rmd                  (Part 1: Overall analysis)
└── single_cell_analysis_T.Rmd                (Part 2: T-cell subclass analysis)
```

### B. Downloading Data

This lecture uses data from **GSE278962** (JIA Synovial CITE-seq).
- Download the `.rds` files distributed in the lecture material from [here](https://drive.google.com/drive/folders/1ZW-uxlEOZ7xWBXT1D6wTNbN6fYFvRMye?usp=sharing) and place them in the `data/` folder mentioned above.
- Check the lecture material for how to set the working directory.

---

## 6. Verifying Installation

Launch RStudio (see Section 4) and execute the following script in the Console.

```r
# --- Version Verification Script ---

cat("=== R Version ===\n")
cat(R.version.string, "\n\n")

cat("=== Package Version Verification ===\n")

# Check required packages (used in single_cell_analysis_T.Rmd)
packages <- c("Seurat", "BiocStyle", "patchwork",
              "dplyr", "magrittr", "knitr", "rmarkdown")

for (pkg in packages) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat(sprintf("  ✓ %-15s : %s\n", pkg, packageVersion(pkg)))
  }, error = function(e) {
    cat(sprintf("  ✗ %-15s : Not installed!\n", pkg))
  })
}

cat("\n=== Result ===\n")
cat("If all of the above packages are marked with ✓, you are ready!\n")
```

### Expected Output (Reference)

| Package | Expected Version |
|-----------|-------------------|
| R         | 4.3.2             |
| Seurat    | 5.2.1             |
| BiocStyle | 2.30.0            |
| patchwork | 1.1.3             |
| dplyr     | 1.1.4             |
| magrittr  | 2.0.3             |
| knitr     | 1.45              |
| rmarkdown | 2.25              |

> **💡 Note**: Small differences in minor versions (e.g., 1.1.3 vs. 1.1.4) are not an issue.
> If the major version differs (e.g., Seurat 5.x.x vs. 4.x.x), please reinstall.

---

## 7. Troubleshooting

### Q1. `conda` Command Not Found

**For macOS:**
Close the Terminal and reopen it. If that doesn't resolve it:
```bash
# Initialize the shell
~/miniforge3/bin/conda init
```
Then restart the Terminal.

**For Windows:**
Use the **Miniforge Prompt** instead of the regular Command Prompt.
Search for "Miniforge Prompt" in the Start Menu and open it.

### Q2. `conda activate scworkshop` Doesn't Work

Execute:
```bash
conda init
```
Then **close and reopen** the Terminal / Miniforge Prompt.

### Q3. Error During Package Installation

**If it cannot be solved with Conda**, try installing directly from within R:

```bash
conda activate scworkshop
R
```

After launching R:

```r
# For CRAN packages
install.packages("package_name")

# If you want to install a specific version (example: Seurat 5.2.1)
install.packages("remotes")
remotes::install_version("Seurat", version = "5.2.1")

# For Bioconductor packages
if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("package_name")
```

**If a compilation error occurs on macOS:**
Xcode Command Line Tools are required. Run the following in the Terminal:
```bash
xcode-select --install
```

**If a compilation error occurs on Windows:**
Rtools may be required:
```bash
conda install -c conda-forge m2w64-toolchain -y
```

### Q4. RStudio Won't Launch / R Version Is Different

Make sure to run `conda activate scworkshop` and launch using the `rstudio` command (or the full path on Windows).
Launching from a desktop shortcut might use a different version of R.

### Q5. Out of Memory Error Occurs

- Close unnecessary applications.
- Delete unnecessary objects in the RStudio Environment tab (`rm(object_name); gc()`).

---

## 8. Reference: Full sessionInfo() Output

This is the complete information for the environment that generated `single_cell_analysis_T.html`. Please refer to it during troubleshooting.

```
R version 4.3.2 (2023-10-31)
Platform: aarch64-apple-darwin20 (64-bit)
Running under: macOS 26.2

attached base packages:
 stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
 patchwork_1.1.3    magrittr_2.0.3     Seurat_5.2.1
 SeuratObject_5.0.2 sp_2.1-2           BiocStyle_2.30.0  
```
