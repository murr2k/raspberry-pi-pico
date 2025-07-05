#!/bin/bash

# Automated Pico Flashing Script
# This script automatically flashes firmware to Raspberry Pi Pico without manual intervention

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/examples/c/build"
DEFAULT_UF2="$BUILD_DIR/blinky.uf2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if picotool is available
check_picotool() {
    if ! command -v picotool &> /dev/null; then
        print_error "picotool is not installed or not in PATH"
        exit 1
    fi
    print_status "picotool version: $(picotool version)"
}

# Function to find Pico devices
find_pico_devices() {
    print_status "Scanning for Pico devices..."
    
    # Try to find Pico in bootloader mode
    BOOTLOADER_DEVICES=$(picotool info -a 2>/dev/null | grep -c "RP2040" || echo "0")
    
    # Try to find Pico running firmware
    RUNTIME_DEVICES=$(lsusb | grep -c "Raspberry Pi" || echo "0")
    
    echo "Bootloader devices: $BOOTLOADER_DEVICES"
    echo "Runtime devices: $RUNTIME_DEVICES"
    
    if [ "$BOOTLOADER_DEVICES" -gt 0 ]; then
        return 0  # Pico in bootloader mode found
    elif [ "$RUNTIME_DEVICES" -gt 0 ]; then
        return 1  # Pico in runtime mode found
    else
        return 2  # No Pico found
    fi
}

# Function to force Pico into bootloader mode
force_bootloader_mode() {
    print_status "Attempting to force Pico into bootloader mode..."
    
    # Method 1: Use picotool to reboot into bootloader
    if picotool reboot -f 2>/dev/null; then
        print_success "Successfully rebooted Pico into bootloader mode"
        sleep 2
        return 0
    fi
    
    # Method 2: Try USB reset (requires specific hardware setup)
    print_warning "picotool reboot failed. Please manually enter bootloader mode:"
    print_warning "1. Disconnect USB cable"
    print_warning "2. Hold BOOTSEL button"
    print_warning "3. Connect USB cable"
    print_warning "4. Release BOOTSEL button"
    
    # Wait for user to manually enter bootloader mode
    local timeout=30
    print_status "Waiting up to ${timeout} seconds for bootloader mode..."
    
    for ((i=0; i<$timeout; i++)); do
        if find_pico_devices && [ $? -eq 0 ]; then
            print_success "Pico detected in bootloader mode"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    echo ""
    print_error "Timeout waiting for bootloader mode"
    return 1
}

# Function to flash firmware
flash_firmware() {
    local uf2_file="$1"
    
    if [ ! -f "$uf2_file" ]; then
        print_error "UF2 file not found: $uf2_file"
        return 1
    fi
    
    print_status "Flashing firmware: $(basename "$uf2_file")"
    print_status "File size: $(du -h "$uf2_file" | cut -f1)"
    
    # Flash using picotool
    if picotool load "$uf2_file" 2>/dev/null; then
        print_success "Firmware loaded successfully"
        
        # Reboot to run the new firmware
        if picotool reboot 2>/dev/null; then
            print_success "Pico rebooted to run new firmware"
            return 0
        else
            print_warning "Failed to reboot Pico, but firmware was loaded"
            return 0
        fi
    else
        print_error "Failed to load firmware"
        return 1
    fi
}

# Function to verify flash operation
verify_flash() {
    print_status "Verifying flash operation..."
    sleep 3  # Wait for reboot
    
    # Check if device is now running (no longer in bootloader)
    find_pico_devices
    local result=$?
    
    if [ $result -eq 1 ]; then
        print_success "Pico is running new firmware"
        return 0
    elif [ $result -eq 0 ]; then
        print_warning "Pico is still in bootloader mode"
        return 1
    else
        print_warning "Pico not detected after flashing"
        return 1
    fi
}

# Function to compile and flash
compile_and_flash() {
    local target="$1"
    local build_dir="$2"
    
    print_status "Compiling $target..."
    
    # Navigate to build directory
    cd "$build_dir" || {
        print_error "Failed to navigate to build directory: $build_dir"
        return 1
    }
    
    # Clean and build
    make clean 2>/dev/null || true
    if make -j4; then
        print_success "Compilation successful"
        
        local uf2_file="$build_dir/${target}.uf2"
        if [ -f "$uf2_file" ]; then
            flash_firmware "$uf2_file"
        else
            print_error "UF2 file not generated: $uf2_file"
            return 1
        fi
    else
        print_error "Compilation failed"
        return 1
    fi
}

# Function to watch for file changes and auto-flash
watch_and_flash() {
    local watch_dir="$1"
    local target="$2"
    
    print_status "Starting watch mode for automatic flashing..."
    print_status "Watching directory: $watch_dir"
    print_status "Target: $target"
    print_warning "Press Ctrl+C to stop watching"
    
    # Check if inotify-tools is available
    if ! command -v inotifywait &> /dev/null; then
        print_error "inotifywait not found. Installing inotify-tools..."
        sudo apt install -y inotify-tools
    fi
    
    # Watch for changes in source files
    while true; do
        inotifywait -e modify,create,delete -r "$watch_dir" --include '\.(c|cpp|h|hpp)$' 2>/dev/null
        
        print_status "Source file changed, recompiling and flashing..."
        if compile_and_flash "$target" "$BUILD_DIR"; then
            print_success "Auto-flash completed successfully"
        else
            print_error "Auto-flash failed"
        fi
        
        sleep 1  # Prevent rapid successive builds
    done
}

# Main function
main() {
    echo "🚀 Raspberry Pi Pico Automated Flashing Tool"
    echo "============================================="
    
    # Parse command line arguments
    local uf2_file=""
    local watch_mode=false
    local compile_mode=false
    local target="blinky"
    local help_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                uf2_file="$2"
                shift 2
                ;;
            -w|--watch)
                watch_mode=true
                shift
                ;;
            -c|--compile)
                compile_mode=true
                shift
                ;;
            -t|--target)
                target="$2"
                shift 2
                ;;
            -h|--help)
                help_mode=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                help_mode=true
                shift
                ;;
        esac
    done
    
    # Show help
    if [ "$help_mode" = true ]; then
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -f, --file FILE     Flash specific UF2 file"
        echo "  -c, --compile       Compile and flash default target"
        echo "  -t, --target NAME   Specify target name (default: blinky)"
        echo "  -w, --watch         Watch mode - auto-compile and flash on changes"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                          # Flash default blinky.uf2"
        echo "  $0 -f custom.uf2           # Flash specific file"
        echo "  $0 -c -t temperature       # Compile and flash temperature example"
        echo "  $0 -w                      # Watch mode for automatic flashing"
        exit 0
    fi
    
    # Check prerequisites
    check_picotool
    
    # Watch mode
    if [ "$watch_mode" = true ]; then
        watch_and_flash "$PROJECT_ROOT/examples/c" "$target"
        exit 0
    fi
    
    # Compile mode
    if [ "$compile_mode" = true ]; then
        compile_and_flash "$target" "$BUILD_DIR"
        exit $?
    fi
    
    # Flash specific file or default
    if [ -n "$uf2_file" ]; then
        target_file="$uf2_file"
    else
        target_file="$DEFAULT_UF2"
    fi
    
    # Main flashing workflow
    print_status "Starting automated flash process..."
    
    # Step 1: Find Pico devices
    find_pico_devices
    local device_status=$?
    
    case $device_status in
        0)
            print_success "Pico found in bootloader mode"
            ;;
        1)
            print_status "Pico found in runtime mode, forcing bootloader mode..."
            if ! force_bootloader_mode; then
                print_error "Failed to enter bootloader mode"
                exit 1
            fi
            ;;
        2)
            print_error "No Pico devices found"
            print_error "Please ensure Pico is connected and in bootloader mode"
            exit 1
            ;;
    esac
    
    # Step 2: Flash firmware
    if flash_firmware "$target_file"; then
        print_success "Flash operation completed"
        
        # Step 3: Verify
        if verify_flash; then
            print_success "🎉 Automated flashing successful!"
            print_status "Your Pico should now be running the new firmware"
        else
            print_warning "Flash completed but verification inconclusive"
        fi
    else
        print_error "Flash operation failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"