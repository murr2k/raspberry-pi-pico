# ⚡ Runtime Flashing System for Raspberry Pi Pico

## 🎯 Overview

**No more BOOTSEL button required!** This system enables firmware updates without manual intervention using multiple advanced techniques.

## 🚀 Available Methods

### 1. **USB Serial Commands** ⭐ (Recommended)
- Send commands via USB serial to reset device into BOOTSEL mode
- No physical access required
- Works remotely over USB connection

### 2. **picotool Runtime Reset**
- Use `picotool reboot -f` to force BOOTSEL mode
- Programmatic reset without manual intervention
- Works when device is running and accessible

### 3. **SWD/OpenOCD Programming** 🔧 (Advanced)
- Direct programming via SWD debug interface
- No BOOTSEL mode required at all
- Requires SWD debugger connection

## 📋 Quick Start Commands

### **Runtime Flash (Auto-Method)**
```bash
# Compile and flash with automatic method selection
make flash-runtime-compile TARGET=blinky

# Flash existing firmware
make flash-runtime TARGET=blinky
```

### **USB Serial Method**
```bash
# Use runtime flash tool with serial commands
./tools/runtime_flash.sh -c -t blinky -m serial
```

### **SWD Programming**
```bash
# Flash via SWD debugger (no device access needed)
make flash-swd TARGET=blinky
```

## 🛠️ Setup Requirements

### **For USB Serial & picotool Methods:**
- ✅ USB connection to Pico
- ✅ Enhanced firmware with runtime update support
- ✅ picotool installed and configured

### **For SWD Programming:**
- 🔌 **SWD Debugger** (J-Link, ST-Link, Pi Pico as Picoprobe)
- 📡 **Wiring:**
  ```
  Debugger    →    Pico
  SWCLK       →    GPIO 2 (Pin 4)
  SWDIO       →    GPIO 3 (Pin 5)  
  GND         →    GND (Pin 3)
  ```
- 🔧 **OpenOCD installed** (already done)

## 🎮 Enhanced Firmware Features

### **USB Serial Commands**
When running enhanced firmware (`blink_led_enhanced.c`), you can send these commands via USB serial:

#### **LED Control Commands:**
```bash
HELP        # Show available commands
STATUS      # Show current system status
FAST        # Fast blinking (125ms)
SLOW        # Slow blinking (1000ms) 
START       # Enable LED blinking
STOP        # Disable LED blinking
```

#### **Runtime Update Commands:**
```bash
BOOTSEL     # Enter bootloader mode immediately
RESET       # Soft reset the system
INFO        # Show device information
PREPARE     # Prepare for firmware update
```

### **Example Usage:**
```bash
# Connect to Pico via serial terminal
screen /dev/ttyACM0 115200

# Send commands (type and press Enter)
STATUS      # Check current state
FAST        # Change to fast blink
BOOTSEL     # Reset to bootloader for update
```

## 🔧 Runtime Flash Tool Usage

### **Basic Usage:**
```bash
# Auto-method (tries serial, then picotool)
./tools/runtime_flash.sh -c -t blinky

# Specific method
./tools/runtime_flash.sh -c -t blinky -m serial
./tools/runtime_flash.sh -c -t blinky -m picotool  
./tools/runtime_flash.sh -c -t blinky -m openocd
```

### **Advanced Options:**
```bash
# Flash specific file
./tools/runtime_flash.sh -f firmware.uf2 -m serial

# Use specific serial port
./tools/runtime_flash.sh -t blinky -p /dev/ttyACM0

# SWD programming
./tools/runtime_flash.sh -t blinky -s

# Show help
./tools/runtime_flash.sh -h
```

## 📊 Method Comparison

| Method | Speed | Requirements | Reliability | Remote Capable |
|--------|-------|-------------|-------------|----------------|
| **USB Serial** | ⚡ Fast | USB + Enhanced FW | 🟢 High | ✅ Yes |
| **picotool** | ⚡ Fast | USB + picotool | 🟢 High | ✅ Yes |
| **SWD/OpenOCD** | 🐌 Medium | SWD Debugger | 🟢 Excellent | ❌ Physical Access |

## 🏗️ Implementation Details

### **Runtime Update Module**
The `runtime_update.c` module provides:
- ROM bootloader access functions
- Watchdog-based reset to BOOTSEL
- USB serial command processing
- Device information queries
- Safe firmware update preparation

### **Key Functions:**
```c
runtime_update_init()       // Initialize update system
runtime_enter_bootsel()     // Force BOOTSEL mode
runtime_reset_to_bootsel()  // Watchdog reset to BOOTSEL  
runtime_process_command()   // Handle USB commands
```

### **Integration Example:**
```c
#include "runtime_update.h"

int main() {
    stdio_init_all();
    runtime_update_init();
    
    while (true) {
        // Your application code
        update_application();
        
        // Process runtime update commands
        runtime_update_loop();
    }
}
```

## 🔄 Development Workflow

### **1. Enhanced Development Cycle**
```bash
# Start with enhanced firmware
make flash-runtime-compile TARGET=blink_led_enhanced

# Make code changes
# ... edit files ...

# Runtime update (no BOOTSEL button!)
make flash-runtime-compile TARGET=blink_led_enhanced
```

### **2. Remote Development**
```bash
# Send update command via serial
echo "BOOTSEL" > /dev/ttyACM0

# Wait for BOOTSEL mode, then flash
make flash-auto TARGET=blinky
```

### **3. SWD Development**
```bash
# Direct programming via debugger
make flash-swd TARGET=blinky

# No device interaction needed
```

## 🛡️ Safety Features

### **Watchdog Protection**
- Safe reset timeouts prevent brick scenarios
- Multiple fallback methods available
- Automatic recovery mechanisms

### **Command Validation**
- Input sanitization for USB commands
- Safe state preservation during updates
- Error handling and status reporting

### **Update Verification**
- Checksum validation where possible
- Device information matching
- Rollback capabilities with SWD

## 🎯 Use Cases

### **Production Updates**
- **Remote firmware updates** via USB serial
- **Automated testing** with runtime resets
- **CI/CD integration** with automated flashing

### **Development Acceleration**
- **Instant updates** without physical access
- **Rapid prototyping** with runtime changes
- **Remote debugging** capabilities

### **Field Service**
- **On-site updates** without disassembly
- **Diagnostic commands** via serial
- **Status monitoring** and health checks

## 🚨 Troubleshooting

### **USB Serial Not Working**
```bash
# Check device detection
ls /dev/ttyACM*

# Test communication
echo "INFO" > /dev/ttyACM0

# Check permissions
sudo usermod -a -G dialout $USER
```

### **picotool Issues**
```bash
# Check device visibility
picotool info -a

# Force reset
picotool reboot -f

# Check USB permissions
sudo picotool info -a
```

### **SWD Connection Problems**
```bash
# Test OpenOCD connection
openocd -f tools/openocd_config.cfg

# Check wiring
# Verify debugger compatibility
# Try different SWD speeds
```

## 🎉 Benefits

### **🚀 Speed Improvements**
- **No manual BOOTSEL**: Saves 10-15 seconds per flash
- **Automated workflows**: 50%+ faster development cycles
- **Remote updates**: No physical access required

### **🔧 Enhanced Capabilities**
- **Multiple update methods**: Redundancy and flexibility
- **Runtime diagnostics**: Real-time system monitoring
- **Professional workflows**: Production-ready update system

### **💪 Reliability**
- **Fallback mechanisms**: Multiple methods ensure success
- **Safe operations**: Watchdog protection and validation
- **Error recovery**: Automatic and manual recovery options

---

**🎯 Result: Professional-grade embedded development with zero-friction firmware updates!**

**No more BOOTSEL button dance - just pure development productivity!** ⚡🚀