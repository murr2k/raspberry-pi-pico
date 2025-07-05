#!/bin/bash

# Raspberry Pi Pico Development Environment Setup
# Run this script to set up your environment for automated flashing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍓 Setting up Raspberry Pi Pico Development Environment${NC}"
echo "=================================================="

# Set up environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_PATH="/home/murr2k/projects/agentic/ruv-swarm/pico-sdk"

echo -e "${YELLOW}Setting up environment variables...${NC}"

# Add to bashrc if not already present
if ! grep -q "PICO_SDK_PATH" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Raspberry Pi Pico SDK" >> ~/.bashrc
    echo "export PICO_SDK_PATH=\"$SDK_PATH\"" >> ~/.bashrc
    echo "export PATH=\"\$PATH:$SCRIPT_DIR/tools\"" >> ~/.bashrc
    echo -e "${GREEN}✅ Added to ~/.bashrc${NC}"
else
    echo -e "${YELLOW}⚠️ Environment variables already in ~/.bashrc${NC}"
fi

# Set for current session
export PICO_SDK_PATH="$SDK_PATH"
export PATH="$PATH:$SCRIPT_DIR/tools"

echo -e "${YELLOW}Installing system dependencies...${NC}"

# Install required packages
sudo apt update
sudo apt install -y \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    build-essential \
    git \
    libusb-1.0-0-dev \
    pkg-config \
    screen \
    inotify-tools

echo -e "${YELLOW}Installing Python dependencies...${NC}"

# Install Python packages
pip3 install -r "$SCRIPT_DIR/tools/requirements.txt"

echo -e "${YELLOW}Making scripts executable...${NC}"

# Make scripts executable
chmod +x "$SCRIPT_DIR/tools/flash_auto.sh"
chmod +x "$SCRIPT_DIR/tools/pico_flash.py"

echo -e "${YELLOW}Checking toolchain...${NC}"

# Verify installation
cd "$SCRIPT_DIR/examples/c"
make check-toolchain

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo "1. Connect your Pico and put it in bootloader mode"
echo "2. cd $SCRIPT_DIR/examples/c"
echo "3. make flash-auto"
echo ""
echo -e "${BLUE}Development Workflow:${NC}"
echo "• make watch              # Auto-compile and flash on changes"
echo "• make flash-compile      # Compile and flash in one step"
echo "• make list-devices       # Check connected Picos"
echo "• make monitor            # Monitor serial output"
echo ""
echo -e "${YELLOW}Note: Restart your terminal or run 'source ~/.bashrc' to load environment${NC}"