#!/bin/bash
set -e  # Exit on any error

echo "=== Setting up environment for Grounded-SAM-2 ==="

# Create and activate conda environment
echo "=== Creating and activating conda environment ==="
ENV_NAME="gsam2_env"

# Check if environment already exists
if conda info --envs | grep -q "$ENV_NAME"; then
    echo "Conda environment '$ENV_NAME' already exists"
else
    echo "Creating new conda environment '$ENV_NAME'"
    conda create -n "$ENV_NAME" python=3.10 -y
fi

# Ensure we can activate conda environments in this script
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Verify environment is activated
echo "Active conda environment: $CONDA_PREFIX"

# Create models directory if it doesn't exist
echo "=== Creating models directory ==="
mkdir -p models

# Download model files if they don't exist
echo "=== Downloading model files ==="


# Detect terminal type and set CUDA environment variables
echo "=== Detecting environment and setting CUDA paths ==="

# Check if we're in WSL
if grep -q Microsoft /proc/version 2>/dev/null; then
    echo "WSL environment detected"
    TERMINAL_TYPE="wsl"
elif [ -f /etc/lsb-release ]; then
    echo "Linux environment detected"
    TERMINAL_TYPE="linux"
else
    echo "Other environment detected"
    TERMINAL_TYPE="other"
fi

# Detect shell type
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
    SHELL_RC="$HOME/.zshrc"
    echo "ZSH shell detected"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
    SHELL_RC="$HOME/.bashrc"
    echo "Bash shell detected"
else
    # Default to bash if we can't determine
    SHELL_TYPE="bash"
    SHELL_RC="$HOME/.bashrc"
    echo "Shell type unknown, defaulting to bash"
fi

# Set CUDA environment variables
if [ -d "/usr/local/cuda" ]; then
    echo "Setting CUDA environment variables"
    export CUDA_HOME=/usr/local/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    
    # Add these to the shell config file if they don't exist already
    if ! grep -q "CUDA_HOME=/usr/local/cuda" "$SHELL_RC"; then
        echo "Adding CUDA environment variables to $SHELL_RC"
        echo "export CUDA_HOME=/usr/local/cuda" >> "$SHELL_RC"
        echo "export PATH=\$CUDA_HOME/bin:\$PATH" >> "$SHELL_RC"
        echo "export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH" >> "$SHELL_RC"
    fi
    
    echo "CUDA paths set: CUDA_HOME=$CUDA_HOME"
else
    echo "CUDA directory not found at /usr/local/cuda"
fi

# Install system dependencies based on terminal type
echo "=== Installing system dependencies ==="
if [ "$TERMINAL_TYPE" = "wsl" ] || [ "$TERMINAL_TYPE" = "linux" ]; then
    sudo apt-get update
    sudo apt-get install -y libstdc++6 build-essential ninja-build
fi
conda install -c conda-forge libstdcxx-ng -y

# Install PyTorch dependencies
echo "=== Installing PyTorch dependencies ==="
# Check if torch is already installed with correct version
if python -c "import torch; exit(0) if torch.__version__ == '2.5.1' else exit(1)" 2>/dev/null; then
    echo "PyTorch 2.5.1 already installed, skipping reinstallation"
else
    echo "Installing PyTorch 2.5.1"
    pip uninstall -y torch torchvision
    pip install torch==2.5.1 torchvision==0.20.1
    pip install opencv-python numpy supervision pycocotools transformers addict yapf timm
fi

# Install ninja if not already installed
if ! pip show ninja > /dev/null 2>&1; then
    echo "Installing ninja build system"
    pip install ninja  # Required for compilation
else
    echo "Ninja already installed, skipping"
fi

# Clone repositories
echo "=== Cloning repositories ==="
if [ ! -d "Grounded-SAM-2" ]; then
    git clone https://github.com/IDEA-Research/Grounded-SAM-2
else
    echo "Grounded-SAM-2 directory already exists, skipping clone"
fi

if [ ! -d "sam2" ]; then
    git clone https://github.com/facebookresearch/sam2
else
    echo "sam2 directory already exists, skipping clone"
fi

# Update setuptools version requirement in setup files
echo "=== Updating setuptools requirement ==="
find . -name "setup.py" -o -name "pyproject.toml" -type f -exec grep -l "setuptools>=61.0" {} \; | xargs -I{} sed -i 's/setuptools>=61.0/setuptools>=62.3.0,<75.9/g' {}

# Export CUDA architecture for compilation
export TORCH_CUDA_ARCH_LIST="8.6"

# Setup Grounded-SAM-2
echo "=== Setting up Grounded-SAM-2 ==="
cd Grounded-SAM-2

# Install grounding_dino first with no-build-isolation flag
python -m pip install --no-build-isolation -e grounding_dino

# Fix ms_deform_attn.py if needed for WSL environment
if [ -f "grounding_dino/groundingdino/models/dingDINO/ms_deform_attn.py" ]; then
    echo "Checking if ms_deform_attn.py needs patching..."
    # Add patching logic if needed
fi

# Build the main package
python setup.py build_ext --inplace

# Now build the grounding_dino submodule
cd grounding_dino
TORCH_CUDA_ARCH_LIST="8.6" python setup.py build_ext --inplace
cd ..

# Install the package in development mode
pip install -e ".[notebooks]"
cd ..

# Setup SAM2
echo "=== Setting up SAM2 ==="
cd sam2
# Install requirements first
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

# Install with both notebooks and demo options
SAM2_BUILD_CUDA=0 pip install -e ".[notebooks]"
pip install -e ".[demo]"
python setup.py build_ext --inplace
cd ..

echo "=== Installation complete! ==="
echo "To test the installation, run: python test.py"