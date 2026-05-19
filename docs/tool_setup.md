# Tool Setup

The recommended environment is Ubuntu or WSL2 Ubuntu on Windows.

YosysHQ documents OSS CAD Suite as the easiest way to get `sby` together with
the required open-source formal tools. The GitHub Actions workflow in this repo
uses `YosysHQ/setup-oss-cad-suite@v4`.

References:

- https://symbiyosys.readthedocs.io/en/latest/install.html
- https://github.com/YosysHQ/setup-oss-cad-suite

## Ubuntu / WSL2

```sh
sudo apt update
sudo apt install -y yosys boolector iverilog gtkwave make git python3 python3-pip
pip3 install --user yowasp-yosys yowasp-sby
```

Depending on distribution packages, `sby` may come from `symbiyosys` instead:

```sh
sudo apt install -y symbiyosys
```

## Check Installation

```sh
yosys -V
sby --version
boolector --version
iverilog -V
```

## Run Project

```sh
cd riscv-formal
make formal
make cover
make sim
gtkwave waveforms/pipeline.vcd
```

If using native Windows PowerShell, install the same tools through OSS CAD
Suite and add its `bin` directory to `PATH`.

This repository also includes a Windows runner that activates a local OSS CAD
Suite extraction and runs proof, cover, simulation, and bug-injection checks:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_all_windows.ps1
```
