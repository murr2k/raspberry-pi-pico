# 🚀 Flash Instructions for Raspberry Pi Pico

## ✅ Compilation Successful!

Your blinky LED example has been successfully compiled! Here are the generated files:

- **`blinky.uf2`** - UF2 firmware file for flashing to Pico (68KB)
- **`blinky.elf`** - ELF debug file for debugging (734KB)
- **`blinky.bin`** - Raw binary file (34KB)

## 📍 File Location

The compiled firmware is located at:
```
/home/murr2k/projects/agentic/ruv-swarm/raspberry-pi-pico/examples/c/build/blinky.uf2
```

## 🔄 Flashing to Raspberry Pi Pico

### Method 1: Direct Copy (Recommended)

1. **Ensure Pico is in bootloader mode:**
   - Hold the BOOTSEL button on your Pico
   - Connect the USB cable to your computer
   - Release the BOOTSEL button
   - Your Pico should appear as a USB mass storage device

2. **Copy the UF2 file:**
   
   **From WSL/Linux:**
   ```bash
   # If D: drive is mounted
   cp blinky.uf2 /mnt/d/
   
   # Alternative: Access Windows Explorer path
   cp blinky.uf2 /mnt/c/Users/[YourUsername]/Desktop/
   ```
   
   **From Windows:**
   - Navigate to: `\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico\examples\c\build\`
   - Copy `blinky.uf2`
   - Paste to your Pico drive (usually D: or E:)

3. **Automatic reboot:**
   - The Pico will automatically reboot after copying
   - The onboard LED should start blinking every 500ms

### Method 2: Command Line (Windows)

```cmd
# From Windows Command Prompt
copy "\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico\examples\c\build\blinky.uf2" D:\
```

### Method 3: Using Windows Explorer

1. Open Windows Explorer
2. Navigate to: `\\wsl$\Ubuntu\home\murr2k\projects\agentic\ruv-swarm\raspberry-pi-pico\examples\c\build\`
3. Right-click on `blinky.uf2` and select "Copy"
4. Go to your Pico drive (D:)
5. Right-click and select "Paste"

## 🔍 Expected Behavior

After flashing successfully:

- **LED Blinking**: The onboard LED (connected to GPIO 25) will blink
- **Timing**: ON for 500ms, OFF for 500ms, repeating continuously
- **Serial Output**: Connect to the Pico's USB serial port to see debug messages:
  ```
  Raspberry Pi Pico LED Blink Example
  LED Pin: GP25
  Blink Delay: 500 ms
  LED ON
  LED OFF
  LED ON
  LED OFF
  ...
  ```

## 🔧 Troubleshooting

### Pico Not Detected
- Ensure you're holding BOOTSEL while connecting USB
- Try a different USB cable or port
- Check Device Manager for "RP2 Boot" device

### File Copy Fails
- Verify Pico is in bootloader mode (shows as mass storage)
- Ensure you have write permissions
- Try copying from Windows Explorer instead of command line

### LED Not Blinking
- Check power supply (USB should be sufficient)
- Verify the correct UF2 file was copied
- Try resetting the Pico (disconnect/reconnect USB)

## 📊 Build Information

- **Compiler**: ARM GCC 10.3.1
- **Target**: RP2040 (Cortex-M0+)
- **SDK Version**: Latest Pico SDK
- **Features Enabled**: 
  - USB stdio output
  - UART stdio output
  - Hardware GPIO control
  - Standard C library

## 🎯 Next Steps

Once the LED is blinking successfully:

1. **Try the temperature sensor example:**
   ```bash
   cd /home/murr2k/projects/agentic/ruv-swarm/raspberry-pi-pico/examples/c
   # Compile temperature_sensor.c next
   ```

2. **Modify the blink rate:**
   - Edit `blink_led.c`
   - Change `BLINK_DELAY_MS` value
   - Recompile and flash

3. **Add external components:**
   - Connect external LEDs to other GPIO pins
   - Add buttons for input
   - Interface with sensors

## 📖 Serial Monitor

To view the serial output from your Pico:

**Windows (PuTTY or similar):**
- Find the COM port in Device Manager
- Connect at 115200 baud, 8N1

**Linux/WSL:**
```bash
sudo apt install screen
screen /dev/ttyACM0 115200
```

**Arduino IDE Serial Monitor:**
- Tools → Port → Select Pico port
- Set baud rate to 115200

---

**🎉 Congratulations!** You've successfully compiled and are ready to flash your first Raspberry Pi Pico program!