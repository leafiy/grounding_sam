# Grounded-SAM-2 WSL 一键安装脚本指南
# Grounded-SAM-2 WSL One-Click Installation Script Guide

## 简介 | Introduction

这个脚本用于自动化安装 Grounded-SAM-2 和 SAM2 在 WSL (Windows Subsystem for Linux) 环境中。该脚本解决了在 WSL 环境中安装过程中常见的几个问题，包括：

This script automates the installation of Grounded-SAM-2 and SAM2 in the WSL (Windows Subsystem for Linux) environment. It resolves several common issues encountered during installation in WSL, including:

- CUDA 环境变量配置问题 (CUDA environment variable configuration issues)
- `no_python_abi_suffix` 错误 (no_python_abi_suffix errors)
- `name '_C' is not defined` 导入错误 (import errors where 'name '_C' is not defined')
- 编译和依赖问题 (Compilation and dependency problems)

## 主要功能 | Key Features

- 自动创建并激活独立的 conda 环境
- 自动检测和下载所需的模型文件
- 自动检测终端类型 (bash/zsh) 并适当配置环境
- 设置正确的 CUDA 环境变量
- 以正确的顺序安装并编译所有组件
- 修复 WSL 特定的编译和导入问题

---

- Automatically creates and activates a dedicated conda environment 
- Automatically detects and downloads required model files
- Detects terminal type (bash/zsh) and configures the environment accordingly
- Sets up correct CUDA environment variables
- Installs and compiles all components in the proper order
- Fixes WSL-specific compilation and import issues

## 使用方法 | Usage

1. 保存脚本为 `setup_grounded_sam2.sh`
2. 添加执行权限: `chmod +x setup_grounded_sam2.sh`
3. 运行脚本: `./setup_grounded_sam2.sh`

---

1. Save the script as `setup_grounded_sam2.sh`
2. Add execution permission: `chmod +x setup_grounded_sam2.sh`
3. Run the script: `./setup_grounded_sam2.sh`

## 脚本解决的具体问题 | Specific Issues Fixed by the Script

### 1. CUDA 配置问题 | CUDA Configuration Issues

脚本自动检测 CUDA 安装并设置必要的环境变量:
```bash
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

The script automatically detects CUDA installation and sets necessary environment variables.

### 2. 编译顺序问题 | Compilation Order Issues

脚本以正确的顺序编译组件:
1. 首先安装 grounding_dino 依赖
2. 然后编译主 Grounded-SAM-2 包
3. 接着编译 grounding_dino 子模块
4. 最后编译 SAM2

The script compiles components in the correct order.

### 3. '_C' 未定义错误 | '_C' Not Defined Error

通过正确设置 CUDA 架构和使用 `--no-build-isolation` 标志来修复:
```bash
export TORCH_CUDA_ARCH_LIST="8.6"
python -m pip install --no-build-isolation -e grounding_dino
```

Fixed by properly setting CUDA architecture and using the `--no-build-isolation` flag.

### 4. 依赖问题 | Dependency Issues

脚本安装所有必要的系统和 Python 依赖:
```bash
sudo apt-get install -y libstdc++6 build-essential ninja-build
pip install ninja
```

The script installs all necessary system and Python dependencies.

## 注意事项 | Notes

- 此脚本需要 sudo 权限来安装系统依赖
- 确保您的 WSL 环境已安装 CUDA
- 如果您使用的不是 bash 或 zsh，可能需要手动设置环境变量

---

- This script requires sudo privileges to install system dependencies
- Ensure your WSL environment has CUDA installed
- If you're not using bash or zsh, you may need to manually set environment variables