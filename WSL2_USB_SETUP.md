# 🔌 USB Device Access Setup for WSL2

## 🎯 Overview

WSL2 doesn't have direct USB access by default. To make USB devices (like Raspberry Pi Pico) available to WSL2, we need to use **USB/IP** (USB over IP) to forward devices from Windows to WSL2.

## 🚀 Method 1: USB/IP with usbipd-win (Recommended)

### **Step 1: Install usbipd-win on Windows**

1. **Download and install usbipd-win:**
   ```powershell
   # Run in Windows PowerShell as Administrator
   winget install usbipd
   ```
   
   Or download from: https://github.com/dorssel/usbipd-win/releases

2. **Restart your computer** after installation

### **Step 2: Install USB/IP tools in WSL2**

```bash
# Update package list
sudo apt update

# Install USB/IP client tools
sudo apt install -y usbip hwdata usbutils

# Install additional USB tools
sudo apt install -y usb-modeswitch usb-modeswitch-data
```

### **Step 3: List and Attach USB Devices**

**On Windows (PowerShell as Administrator):**

1. **List all USB devices:**
   ```powershell
   usbipd wsl list
   ```
   
   Look for entries like:
   ```
   BUSID  VID:PID    DEVICE                          STATE
   2-7    2e8a:0003  USB Serial Device (COM3)        Not attached
   2-8    2e8a:000a  RP2 Boot                        Not attached
   ```

2. **Bind the device to usbipd:**
   ```powershell
   # Replace 2-7 with your actual BUSID
   usbipd wsl bind --busid 2-7
   ```

3. **Attach device to WSL2:**
   ```powershell
   # Replace 2-7 with your actual BUSID
   usbipd wsl attach --busid 2-7
   ```

**In WSL2:**

4. **Verify device is available:**
   ```bash
   # Check if device appears
   lsusb
   
   # Look for Raspberry Pi devices
   lsusb | grep -i "raspberry\|pico\|2e8a"
   
   # Check for serial devices
   ls /dev/ttyACM* 2>/dev/null || echo "No ACM devices found"
   ```

### **Step 4: Automated Attachment Script**

Create this script on Windows for easy device management:

**Windows Script: `attach_pico.ps1`**
```powershell
# Run as Administrator
Write-Host "🔌 Attaching Raspberry Pi Pico to WSL2..." -ForegroundColor Green

# List devices
Write-Host "📋 Available USB devices:" -ForegroundColor Yellow
usbipd wsl list

# Find Pico devices (adjust VID:PID as needed)
$devices = usbipd wsl list | Select-String "2e8a:"

if ($devices) {
    foreach ($device in $devices) {
        $busid = ($device -split "\s+")[0]
        Write-Host "🔗 Binding and attaching device $busid..." -ForegroundColor Cyan
        
        # Bind device
        usbipd wsl bind --busid $busid
        
        # Attach to WSL
        usbipd wsl attach --busid $busid
        
        Write-Host "✅ Device $busid attached to WSL2" -ForegroundColor Green
    }
} else {
    Write-Host "❌ No Raspberry Pi Pico devices found" -ForegroundColor Red
    Write-Host "💡 Make sure device is connected and in the right mode" -ForegroundColor Yellow
}

Write-Host "🎯 Run 'lsusb' in WSL2 to verify devices are available" -ForegroundColor Cyan
```

## 🚀 Method 2: VirtualHere (Alternative)

### **Commercial USB over Network Solution**

1. **Download VirtualHere:**
   - Server: https://www.virtualhere.com/usb_server_software
   - Client: https://www.virtualhere.com/usb_client_software

2. **Setup:**
   ```bash
   # Install on Windows (USB Server)
   # Install in WSL2 (USB Client)
   
   # Run server on Windows
   # Connect from WSL2 client
   ```

## 🔧 Device-Specific Instructions

### **For Raspberry Pi Pico:**

**Device States and VID:PID:**
```
Normal Mode:    VID:PID = 2e8a:0003 (USB Serial)
BOOTSEL Mode:   VID:PID = 2e8a:000a (RP2 Boot)
```

**Complete Workflow:**

1. **Attach Pico in normal mode:**
   ```powershell
   # Windows PowerShell (Administrator)
   usbipd wsl list
   usbipd wsl bind --busid 2-7    # Adjust BUSID
   usbipd wsl attach --busid 2-7
   ```

2. **Verify in WSL2:**
   ```bash
   # Check USB devices
   lsusb | grep 2e8a
   
   # Check serial ports
   ls /dev/ttyACM*
   
   # Test communication
   echo "INFO" > /dev/ttyACM0
   ```

3. **For BOOTSEL mode (if needed):**
   ```powershell
   # If device switches to BOOTSEL mode, re-attach
   usbipd wsl attach --busid 2-8  # Different BUSID for BOOTSEL
   ```

## 🛠️ Troubleshooting

### **Common Issues:**

**1. Device Not Found:**
```bash
# Check if usbip kernel module is loaded
lsmod | grep usbip

# Load module if missing
sudo modprobe usbip-core
sudo modprobe vhci-hcd
```

**2. Permission Issues:**
```bash
# Add user to dialout group for serial access
sudo usermod -a -G dialout $USER

# Apply group changes (logout/login or)
newgrp dialout

# Set device permissions
sudo chmod 666 /dev/ttyACM*
```

**3. Device Keeps Disconnecting:**
```bash
# Check USB power management
lsusb -t
cat /sys/bus/usb/devices/*/power/autosuspend 2>/dev/null

# Disable autosuspend for specific device
echo -1 | sudo tee /sys/bus/usb/devices/1-1/power/autosuspend
```

**4. Multiple Device Instances:**
```powershell
# Detach all first, then reattach
usbipd wsl detach --busid 2-7
usbipd wsl detach --busid 2-8
usbipd wsl attach --busid 2-7
```

### **Diagnostic Commands:**

**In WSL2:**
```bash
# Comprehensive device check
echo "=== USB Devices ==="
lsusb

echo "=== Serial Devices ==="
ls -la /dev/tty* | grep -E "(ACM|USB)"

echo "=== USB/IP Status ==="
usbip list -l 2>/dev/null || echo "No local USB/IP devices"

echo "=== Kernel Modules ==="
lsmod | grep -E "(usbip|vhci)"

echo "=== Device Permissions ==="
ls -la /dev/ttyACM* 2>/dev/null || echo "No ACM devices"
```

**In Windows PowerShell:**
```powershell
# Check USB/IP status
usbipd wsl list

# Check WSL2 distributions
wsl -l -v

# Check specific device
usbipd wsl list | Select-String "2e8a"
```

## 🎯 Quick Setup Commands

### **One-time Setup:**

**Windows (PowerShell as Administrator):**
```powershell
# Install usbipd-win
winget install usbipd

# Find and attach Pico
usbipd wsl list
usbipd wsl bind --busid 2-7    # Replace with actual BUSID
usbipd wsl attach --busid 2-7
```

**WSL2:**
```bash
# Install USB tools
sudo apt update && sudo apt install -y usbip hwdata usbutils

# Add user to dialout group
sudo usermod -a -G dialout $USER
newgrp dialout

# Verify device
lsusb | grep 2e8a
ls /dev/ttyACM*
```

### **Daily Development Workflow:**

**Windows:**
```powershell
# Before starting development
usbipd wsl attach --busid 2-7
```

**WSL2:**
```bash
# Test device availability
make list-devices

# Start development
make flash-runtime-compile TARGET=blink_led_enhanced

# Monitor device
make monitor
```

## 🚀 Automation Scripts

### **Auto-Attach Script for WSL2:**

Create `/home/murr2k/projects/agentic/ruv-swarm/raspberry-pi-pico/tools/attach_usb.sh`:

```bash
#!/bin/bash
echo "🔌 Checking USB device availability..."

# Check if devices are available
if lsusb | grep -q "2e8a"; then
    echo "✅ Raspberry Pi devices found"
    lsusb | grep "2e8a"
    
    # Check serial ports
    if ls /dev/ttyACM* >/dev/null 2>&1; then
        echo "✅ Serial ports available:"
        ls -la /dev/ttyACM*
    else
        echo "⚠️ No serial ports found"
    fi
else
    echo "❌ No Raspberry Pi devices found"
    echo "💡 Run this in Windows PowerShell (Administrator):"
    echo "   usbipd wsl list"
    echo "   usbipd wsl attach --busid X-Y"
fi
```

### **Windows Batch Script:**

Create `attach_pico.bat`:
```batch
@echo off
echo 🔌 Attaching Raspberry Pi Pico to WSL2...

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Running as Administrator
) else (
    echo ❌ Please run as Administrator
    pause
    exit /b 1
)

REM List devices
echo 📋 Available USB devices:
usbipd wsl list

REM Find and attach Pico devices
for /f "tokens=1" %%i in ('usbipd wsl list ^| findstr "2e8a"') do (
    echo 🔗 Attaching device %%i...
    usbipd wsl bind --busid %%i
    usbipd wsl attach --busid %%i
    echo ✅ Device %%i attached
)

echo 🎯 Devices should now be available in WSL2
pause
```

## 🎉 Success Verification

Once setup is complete, you should see:

**In WSL2:**
```bash
$ lsusb | grep 2e8a
Bus 001 Device 002: ID 2e8a:0003 Raspberry Pi RP2 Boot

$ ls /dev/ttyACM*
/dev/ttyACM0

$ make list-devices
[32mScanning for Pico devices...[0m
picotool v2.1.1
Device at /dev/ttyACM0 is a RP2040 in application mode
```

**Ready for zero-friction development!** 🚀

---

**🎯 Result: Full USB device access in WSL2 with automated workflows!**