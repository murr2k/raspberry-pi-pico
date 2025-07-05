# 🎯 Attach Device 2-7 to WSL2

## Current Device Status
- **BUSID:** 2-7
- **VID:PID:** 2e8a:000a (RP2 Boot - BOOTSEL mode)
- **Port:** COM6  
- **State:** Not shared

## 🚀 Quick Attachment Commands

### Step 1: Windows PowerShell (Run as Administrator)

```powershell
# Bind the device
usbipd wsl bind --busid 2-7

# Attach to WSL2
usbipd wsl attach --busid 2-7

# Verify
usbipd wsl list
```

### Step 2: Verify in WSL2

```bash
# Check USB devices
lsusb | grep 2e8a

# Check for BOOTSEL drive
lsblk | grep -i rpi
ls /media/*/
df -h | grep RPI

# Check mount points
mount | grep rpi
```

### Step 3: Flash Firmware

```bash
# Direct flash (BOOTSEL mode)
make flash-auto TARGET=blink_led_enhanced

# Or manual copy
cp build/blink_led_enhanced.uf2 /media/*/RPI-RP2/
```

## 🔄 Device Mode Transitions

Your device (2e8a:000a) is currently in **BOOTSEL mode**, which means:
- ✅ Ready for firmware flashing
- ✅ Appears as USB mass storage
- ✅ Can directly copy UF2 files

After flashing, device will switch to:
- **VID:PID:** 2e8a:0003 (USB Serial)
- **Mode:** Application mode with runtime updates

## 🛠️ Troubleshooting

If attachment fails:

```powershell
# Windows: Check device state
usbipd wsl list | findstr "2-7"

# Detach and retry
usbipd wsl detach --busid 2-7
usbipd wsl bind --busid 2-7
usbipd wsl attach --busid 2-7
```

```bash
# WSL2: Check kernel modules
lsmod | grep usbip
sudo modprobe usbip-core
sudo modprobe vhci-hcd
```

## 🎯 Success Indicators

You'll know it worked when:

**In WSL2:**
```bash
$ lsusb | grep 2e8a
Bus 001 Device 002: ID 2e8a:000a Raspberry Pi RP2 Boot

$ lsblk | grep -i rpi  
sdb      8:16   1   128M  0 disk /media/user/RPI-RP2

$ ls /media/*/
INFO_UF2.TXT  INDEX.HTM
```

**Ready to flash!** 🚀

## 🎉 One-Click Flash Command

Once attached:
```bash
make flash-runtime-compile TARGET=blink_led_enhanced
```

This will:
1. ✅ Build the enhanced firmware
2. ✅ Detect BOOTSEL mode
3. ✅ Copy UF2 file automatically
4. ✅ Device boots into enhanced firmware
5. ✅ Runtime updates enabled!

---

**Next:** After first flash, you can use runtime updates without BOOTSEL mode! 🎯