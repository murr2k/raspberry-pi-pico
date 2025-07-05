# 🔌 USB/IP Commands for usbipd 5.1.0

## 🎯 Updated Syntax for Device 2-7

Your device: **BUSID 2-7** (VID:PID 2e8a:000a) in BOOTSEL mode

## 🚀 Correct Commands for usbipd 5.1.0

### **Step 1: Windows PowerShell (Run as Administrator)**

```powershell
# List devices (verify your device)
usbipd list

# Bind device for sharing (new syntax)
usbipd bind --busid 2-7

# Share device with WSL (updated command)
usbipd attach --wsl --busid 2-7
```

### **Alternative Single Command:**
```powershell
# Combined bind and attach (if supported)
usbipd attach --wsl --busid 2-7 --auto-attach
```

### **Step 2: Verify Attachment**
```powershell
# Check attachment status
usbipd list

# Should show "Attached - WSL" for device 2-7
```

## 🔄 Command Comparison

### **Old Syntax (usbipd < 5.0):**
```powershell
usbipd wsl bind --busid 2-7
usbipd wsl attach --busid 2-7
```

### **New Syntax (usbipd 5.1.0):**
```powershell
usbipd bind --busid 2-7
usbipd attach --wsl --busid 2-7
```

## 🛠️ Additional usbipd 5.1.0 Commands

### **Management Commands:**
```powershell
# List all devices
usbipd list

# Show detailed device info
usbipd list --verbose

# Detach device from WSL
usbipd detach --busid 2-7

# Unbind device (stop sharing)
usbipd unbind --busid 2-7

# Force detach if stuck
usbipd detach --busid 2-7 --force
```

### **Auto-attach Features:**
```powershell
# Enable auto-attach for device
usbipd attach --wsl --busid 2-7 --auto-attach

# Disable auto-attach
usbipd detach --busid 2-7
usbipd bind --busid 2-7  # Bind without auto-attach
```

## 🎯 Exact Commands for Your Device 2-7

### **Quick Setup:**
```powershell
# Windows PowerShell (Administrator)
usbipd bind --busid 2-7
usbipd attach --wsl --busid 2-7
```

### **Verification:**
```powershell
# Should show "Attached - WSL"
usbipd list | findstr "2-7"
```

### **In WSL2:**
```bash
# Verify device attachment
lsusb | grep 2e8a

# Flash firmware
make flash-runtime-compile TARGET=blink_led_enhanced
```

## 🔧 Troubleshooting usbipd 5.1.0

### **If Commands Fail:**

1. **Check usbipd version:**
   ```powershell
   usbipd --version
   ```

2. **Update if needed:**
   ```powershell
   winget upgrade usbipd
   ```

3. **Reset device binding:**
   ```powershell
   usbipd detach --busid 2-7 --force
   usbipd unbind --busid 2-7
   usbipd bind --busid 2-7
   usbipd attach --wsl --busid 2-7
   ```

### **Common Issues:**

**"Device not found" error:**
```powershell
# Refresh device list
usbipd list --refresh
```

**"Access denied" error:**
```powershell
# Ensure running as Administrator
# Right-click PowerShell → "Run as Administrator"
```

**"WSL not found" error:**
```powershell
# Check WSL status
wsl --list --verbose
wsl --status
```

## 🎉 Success Indicators

### **Windows PowerShell Output:**
```
BUSID  VID:PID    DEVICE                    STATE
2-7    2e8a:000a  USB Serial Device (COM6)  Attached - WSL
```

### **WSL2 Output:**
```bash
$ lsusb | grep 2e8a
Bus 001 Device 002: ID 2e8a:000a Raspberry Pi RP2 Boot

$ lsblk | grep -i rpi
sdb      8:16   1   128M  0 disk /media/user/RPI-RP2
```

## 🚀 Automated Script for usbipd 5.1.0

Create `attach_pico_v5.ps1`:

```powershell
# PowerShell script for usbipd 5.1.0
param(
    [string]$BusId = "2-7"
)

Write-Host "🔌 Attaching Pico device $BusId using usbipd 5.1.0..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Please run as Administrator" -ForegroundColor Red
    exit 1
}

# Check usbipd version
$version = usbipd --version
Write-Host "📋 Using usbipd version: $version" -ForegroundColor Cyan

# List devices
Write-Host "📋 Available devices:" -ForegroundColor Yellow
usbipd list

# Bind and attach device
try {
    Write-Host "🔗 Binding device $BusId..." -ForegroundColor Cyan
    usbipd bind --busid $BusId
    
    Write-Host "📎 Attaching device $BusId to WSL..." -ForegroundColor Cyan
    usbipd attach --wsl --busid $BusId
    
    Write-Host "✅ Device $BusId successfully attached!" -ForegroundColor Green
    
    # Show final status
    Write-Host "📊 Final status:" -ForegroundColor Yellow
    usbipd list | findstr $BusId
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Try: usbipd detach --busid $BusId --force" -ForegroundColor Yellow
}

Write-Host "🎯 Run 'lsusb | grep 2e8a' in WSL2 to verify" -ForegroundColor Cyan
```

## 🎯 Quick Reference Card

### **Daily Development Workflow:**

**Windows (Administrator PowerShell):**
```powershell
usbipd attach --wsl --busid 2-7
```

**WSL2:**
```bash
make flash-runtime-compile TARGET=blink_led_enhanced
```

**Detach when done:**
```powershell
usbipd detach --busid 2-7
```

---

**🎯 Ready for usbipd 5.1.0! Use the new syntax above.** 🚀