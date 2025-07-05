#!/bin/bash

# Runtime Firmware Flashing Script
# Flashes firmware without requiring BOOTSEL mode

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/examples/c/build"
OPENOCD_CONFIG="$SCRIPT_DIR/openocd_config.cfg"

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

# Function to show help
show_help() {
    echo "🚀 Runtime Firmware Flashing Tool"
    echo "=================================="
    echo ""
    echo "This tool flashes firmware without requiring BOOTSEL mode using:"
    echo "  1. USB Serial Commands (runtime reset to BOOTSEL)"
    echo "  2. picotool runtime reset"
    echo "  3. OpenOCD SWD programming"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE     Flash specific UF2 file"
    echo "  -t, --target NAME   Build and flash target (default: blinky)"
    echo "  -m, --method METHOD Flash method (auto, serial, picotool, openocd)"
    echo "  -p, --port PORT     Serial port for commands (default: auto-detect)"
    echo "  -s, --swd           Use SWD/OpenOCD for programming"
    echo "  -c, --compile       Compile before flashing"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Methods:"
    echo "  auto     - Try all methods automatically (default)"
    echo "  serial   - Send reset command via USB serial"
    echo "  picotool - Use picotool reboot command"
    echo "  openocd  - Use OpenOCD SWD programming"
    echo ""
    echo "Examples:"
    echo "  $0 -t blinky                    # Auto-flash blinky"
    echo "  $0 -f firmware.uf2 -m picotool  # Flash specific file with picotool"
    echo "  $0 -t temperature -s            # Flash via SWD"
    echo "  $0 -c -t blinky                 # Compile and flash"
}

# Function to detect Pico serial port
detect_serial_port() {
    print_status "Detecting Pico serial port..."
    
    # Look for Pico CDC device
    for port in /dev/ttyACM*; do
        if [ -e "$port" ]; then
            # Check if it's a Pico by sending a test command
            echo "INFO" > "$port" 2>/dev/null && echo "$port" && return 0
        fi
    done
    
    print_warning "No Pico serial port detected"
    return 1
}

# Function to send runtime command via serial
send_serial_command() {
    local command="$1"
    local port="$2"
    
    if [ -z "$port" ]; then
        port=$(detect_serial_port)
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    print_status "Sending command '$command' to $port"
    echo "$command" > "$port"
    sleep 2
    return 0
}

# Function to reset to BOOTSEL via serial
reset_via_serial() {
    local port="$1"
    print_status "Attempting reset to BOOTSEL via USB serial..."
    
    if send_serial_command "BOOTSEL" "$port"; then
        print_success "Reset command sent successfully"
        sleep 3  # Wait for reset
        return 0
    else
        print_error "Failed to send reset command"
        return 1
    fi
}

# Function to reset via picotool
reset_via_picotool() {
    print_status "Attempting reset to BOOTSEL via picotool..."
    
    if picotool reboot -f 2>/dev/null; then
        print_success "picotool reset successful"
        sleep 3  # Wait for reset
        return 0
    else
        print_error "picotool reset failed"
        return 1
    fi
}

# Function to program via OpenOCD
program_via_openocd() {
    local elf_file="$1"
    
    if [ ! -f "$elf_file" ]; then
        print_error "ELF file not found: $elf_file"
        return 1
    fi
    
    print_status "Programming via OpenOCD SWD interface..."
    print_warning "Ensure SWD debugger is connected to pins:"
    print_warning "  SWCLK -> GPIO 2 (Pin 4)"
    print_warning "  SWDIO -> GPIO 3 (Pin 5)"
    print_warning "  GND   -> GND (Pin 3)"
    
    # Create temporary OpenOCD script
    local temp_script="/tmp/pico_program.cfg"
    cat > "$temp_script" << EOF
source $OPENOCD_CONFIG
program $elf_file verify reset exit
EOF
    
    if openocd -f "$temp_script" 2>/dev/null; then
        print_success "OpenOCD programming successful"
        rm -f "$temp_script"
        return 0
    else
        print_error "OpenOCD programming failed"
        rm -f "$temp_script"
        return 1
    fi
}

# Function to flash firmware after device is in BOOTSEL
flash_bootsel_firmware() {
    local uf2_file="$1"
    local max_attempts=10
    local attempt=1
    
    print_status "Waiting for device in BOOTSEL mode..."
    
    while [ $attempt -le $max_attempts ]; do
        if picotool info -a 2>/dev/null | grep -q "RP2040"; then
            print_success "Device detected in BOOTSEL mode"
            
            print_status "Flashing firmware: $(basename "$uf2_file")"
            if picotool load "$uf2_file" 2>/dev/null; then
                print_success "Firmware loaded successfully"
                
                if picotool reboot 2>/dev/null; then
                    print_success "Device rebooted successfully"
                    return 0
                else
                    print_warning "Reboot failed, but firmware was loaded"
                    return 0
                fi
            else
                print_error "Failed to load firmware"
                return 1
            fi
        fi
        
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo ""
    print_error "Timeout waiting for BOOTSEL mode"
    return 1
}

# Function to compile target
compile_target() {
    local target="$1"
    local build_dir="$2"
    
    print_status "Compiling $target..."
    
    cd "$PROJECT_ROOT/examples/c" || {
        print_error "Failed to navigate to examples directory"
        return 1
    }
    
    export PICO_SDK_PATH="/home/murr2k/projects/agentic/ruv-swarm/pico-sdk"
    
    if make build TARGET="$target"; then
        print_success "Compilation successful"
        return 0
    else
        print_error "Compilation failed"
        return 1
    fi
}

# Main function
main() {
    echo "🚀 Runtime Firmware Flashing Tool"
    echo "=================================="
    
    # Parse command line arguments
    local uf2_file=""
    local target="blinky"
    local method="auto"
    local port=""
    local use_swd=false
    local compile_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                uf2_file="$2"
                shift 2
                ;;
            -t|--target)
                target="$2"
                shift 2
                ;;
            -m|--method)
                method="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -s|--swd)
                use_swd=true
                shift
                ;;
            -c|--compile)
                compile_mode=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Compile if requested
    if [ "$compile_mode" = true ]; then
        if ! compile_target "$target" "$BUILD_DIR"; then
            exit 1
        fi
    fi
    
    # Determine UF2 file
    if [ -z "$uf2_file" ]; then
        uf2_file="$BUILD_DIR/${target}.uf2"
    fi
    
    if [ ! -f "$uf2_file" ]; then
        print_error "UF2 file not found: $uf2_file"
        print_error "Try running with -c flag to compile first"
        exit 1
    fi
    
    print_status "Target firmware: $(basename "$uf2_file")"
    print_status "File size: $(du -h "$uf2_file" | cut -f1)"
    
    # Use SWD if requested
    if [ "$use_swd" = true ]; then
        local elf_file="${uf2_file%.uf2}.elf"
        program_via_openocd "$elf_file"
        exit $?
    fi
    
    # Try different methods based on selection
    case $method in
        serial)
            if reset_via_serial "$port" && flash_bootsel_firmware "$uf2_file"; then
                print_success "🎉 Runtime flashing successful via serial!"
                exit 0
            else
                exit 1
            fi
            ;;
        picotool)
            if reset_via_picotool && flash_bootsel_firmware "$uf2_file"; then
                print_success "🎉 Runtime flashing successful via picotool!"
                exit 0
            else
                exit 1
            fi
            ;;
        openocd)
            local elf_file="${uf2_file%.uf2}.elf"
            if program_via_openocd "$elf_file"; then
                print_success "🎉 Runtime flashing successful via OpenOCD!"
                exit 0
            else
                exit 1
            fi
            ;;
        auto)
            print_status "Trying all available methods..."
            
            # Try serial first
            if reset_via_serial "$port" && flash_bootsel_firmware "$uf2_file"; then
                print_success "🎉 Runtime flashing successful via serial!"
                exit 0
            fi
            
            print_warning "Serial method failed, trying picotool..."
            
            # Try picotool
            if reset_via_picotool && flash_bootsel_firmware "$uf2_file"; then
                print_success "🎉 Runtime flashing successful via picotool!"
                exit 0
            fi
            
            print_warning "All methods failed. Try manual BOOTSEL mode or SWD programming."
            print_warning "Commands to try:"
            print_warning "  $0 -f \"$uf2_file\" -s    # Use SWD programming"
            print_warning "  make flash-auto TARGET=$target  # Manual BOOTSEL mode"
            exit 1
            ;;
        *)
            print_error "Invalid method: $method"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"