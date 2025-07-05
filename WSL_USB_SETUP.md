# 🔧 WSL2 USB Passthrough Setup for Raspberry Pi Pico

## 🚨 Current Issue: WSL2 USB Limitation

**WSL2 cannot directly access USB devices**, including the Raspberry Pi Pico in BOOTSEL mode. This is a known limitation of WSL2's virtualization architecture.

## ✅ Solutions for WSL2 + Pico Development

### Solution 1: USB/IP Passthrough (Recommended)

**Install usbipd-win on Windows host:**

1. Download and install usbipd-win from: https://github.com/dorssel/usbipd-win/releases
2. Open PowerShell as Administrator on Windows
3. Connect your Pico in BOOTSEL mode
4. List USB devices:
   ```powershell
   usbipd wsl list
   ```
5. Find your Pico (should show as "RP2 Boot" or similar)
6. Attach to WSL:
   ```powershell
   usbipd wsl attach --busid <BUSID>
   ```

**In WSL2 terminal:**
```bash
# Verify device is now visible
lsusb
picotool info -a

# Now the automated flashing should work
cd raspberry-pi-pico/examples/c
make flash-auto
```

### Solution 2: Windows Native Development

**Use Windows PowerShell/Command Prompt:**

```powershell
# Navigate to project in Windows
cd "\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico"

# Manual flash method
Copy-Item "examples\c\build\blinky.uf2" "D:\"

# Or use Windows picotool (if installed)
picotool load "examples\c\build\blinky.uf2"
```

### Solution 3: Hybrid Development Workflow

**Recommended approach for WSL2 users:**

1. **Development in WSL2**: Use WSL2 for coding, building, and Git operations
2. **Flashing in Windows**: Use Windows tools for device flashing

**WSL2 Commands:**
```bash
# Build in WSL2
cd raspberry-pi-pico/examples/c
make build TARGET=blinky

# The UF2 file is now at: examples/c/build/blinky.uf2
```

**Windows Commands:**
```powershell
# Copy UF2 to Pico (when in BOOTSEL mode)
Copy-Item "\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico\examples\c\build\blinky.uf2" "D:\"
```

### Solution 4: Windows Batch Script for Hybrid Workflow

Create a Windows batch file to automate the hybrid approach:

```batch
@echo off
echo 🚀 WSL2 Hybrid Pico Flash Script
echo ================================

REM Build in WSL2
echo Building in WSL2...
wsl cd /home/murr2k/projects/agentic/ruv-swarm/raspberry-pi-pico/examples/c && make build TARGET=%1

REM Check if UF2 exists
set UF2_PATH=\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico\examples\c\build\%1.uf2
if not exist "%UF2_PATH%" (
    echo ❌ Build failed - UF2 not found
    exit /b 1
)

REM Flash to Pico
echo Flashing to Pico...
echo Please ensure Pico is in BOOTSEL mode (drive D:)
pause

copy "%UF2_PATH%" "D:\"
if %errorlevel% equ 0 (
    echo ✅ Flash successful!
) else (
    echo ❌ Flash failed - check Pico connection
)
```

## 🔄 Updated Development Workflow

### For WSL2 Users (Hybrid Approach):

1. **Code and Build in WSL2:**
   ```bash
   cd raspberry-pi-pico/examples/c
   # Edit your code with VS Code or vim
   make build TARGET=blinky
   ```

2. **Flash from Windows:**
   - Put Pico in BOOTSEL mode (hold button while connecting)
   - Copy UF2 file to D: drive (or use Windows picotool)
   - Device automatically reboots and runs firmware

3. **Monitor in WSL2 (if needed):**
   ```bash
   # If device shows up after flashing
   make monitor
   ```

## 🛠️ Installing Windows picotool (Optional)

For better Windows integration:

1. Download pico-sdk for Windows
2. Build picotool with MSYS2 or use pre-built binaries
3. Add to Windows PATH

Then use from PowerShell:
```powershell
picotool load "path\to\firmware.uf2"
picotool reboot
```

## 📋 Troubleshooting

### Issue: "usbipd not found"
**Solution:** Install usbipd-win on Windows host first

### Issue: "Device not visible in WSL after attach"
**Solution:** 
```bash
# Reload USB subsystem
sudo modprobe -r usbcore && sudo modprobe usbcore
```

### Issue: "Permission denied" in WSL
**Solution:**
```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Logout and login again
```

### Issue: "Pico not detected in Windows"
**Solution:**
- Check Device Manager for "RP2 Boot" device
- Install Raspberry Pi Pico drivers if needed
- Try different USB cable/port

## 🎯 Recommended Setup

**For optimal WSL2 + Pico development:**

1. ✅ Use WSL2 for: coding, building, Git, testing
2. ✅ Use Windows for: flashing, device management
3. ✅ Set up USB/IP passthrough for advanced automation
4. ✅ Use hybrid batch scripts for streamlined workflow

This approach gives you the best of both worlds: Linux development environment with reliable USB access.

---

**Note:** This limitation affects all WSL2 USB devices, not just Raspberry Pi Pico. The solutions above work for any embedded development in WSL2.