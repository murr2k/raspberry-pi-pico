# 🍓 Raspberry Pi Pico Development Project

> **Comprehensive development environment for Raspberry Pi Pico (2020) with C/C++ and MicroPython support**

![Raspberry Pi Pico](https://img.shields.io/badge/board-Raspberry%20Pi%20Pico-red.svg)
![RP2040](https://img.shields.io/badge/mcu-RP2040-green.svg)
![C/C++](https://img.shields.io/badge/language-C%2FC%2B%2B-blue.svg)
![MicroPython](https://img.shields.io/badge/language-MicroPython-yellow.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 🎯 Project Overview

This repository contains development resources, examples, and projects for the **Raspberry Pi Pico** board featuring the powerful **RP2040** dual-core ARM Cortex-M0+ microcontroller.

### 🔧 Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **Microcontroller** | RP2040 dual-core ARM Cortex-M0+ |
| **Clock Speed** | Up to 133 MHz |
| **RAM** | 264KB SRAM |
| **Flash** | 2MB onboard flash |
| **GPIO Pins** | 26 multifunction GPIO pins |
| **ADC** | 3 × 12-bit ADC channels |
| **PWM** | 16 × PWM channels |
| **Interfaces** | 2 × UART, 2 × SPI, 2 × I2C |
| **USB** | USB 1.1 device and host |
| **Power** | 1.8V - 5.5V input |

## 📁 Project Structure

```
raspberry-pi-pico/
├── 📁 src/                    # Source code
│   ├── 📁 c/                  # C/C++ projects
│   └── 📁 micropython/        # MicroPython scripts
├── 📁 examples/               # Example projects
│   ├── 📁 c/                  # C/C++ examples
│   └── 📁 micropython/        # MicroPython examples
├── 📁 docs/                   # Documentation
├── 📁 tools/                  # Development tools and scripts
├── 📁 tests/                  # Test files
├── 📋 CMakeLists.txt          # C/C++ build configuration
├── 📋 requirements.txt        # Python dependencies
└── 📚 README.md               # This file
```

## 🚀 Quick Start

### Option 1: C/C++ Development

#### Prerequisites
```bash
# Install development tools (Ubuntu/Debian)
sudo apt update
sudo apt install cmake gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential

# Clone Pico SDK
git clone https://github.com/raspberrypi/pico-sdk.git
export PICO_SDK_PATH=/path/to/pico-sdk
```

#### Build and Flash
```bash
# Navigate to project
cd raspberry-pi-pico

# Create build directory
mkdir build && cd build

# Configure and build
cmake ..
make

# Flash to Pico (hold BOOTSEL button, connect USB)
cp your_project.uf2 /media/RPI-RP2/
```

### Option 2: MicroPython Development

#### Prerequisites
```bash
# Install MicroPython tools
pip install adafruit-ampy rshell thonny

# Download MicroPython firmware for Pico
wget https://micropython.org/download/rpi-pico/rpi-pico-latest.uf2
```

#### Flash MicroPython
```bash
# 1. Hold BOOTSEL button on Pico
# 2. Connect USB cable
# 3. Copy firmware
cp rpi-pico-latest.uf2 /media/RPI-RP2/

# 4. Connect and upload scripts
ampy --port /dev/ttyACM0 put src/micropython/main.py
```

## 💡 Featured Examples

### 🔄 Blink LED (C++)
```cpp
#include "pico/stdlib.h"

int main() {
    const uint LED_PIN = 25;
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    
    while (true) {
        gpio_put(LED_PIN, 1);
        sleep_ms(500);
        gpio_put(LED_PIN, 0);
        sleep_ms(500);
    }
}
```

### 🔄 Blink LED (MicroPython)
```python
import machine
import time

led = machine.Pin(25, machine.Pin.OUT)

while True:
    led.on()
    time.sleep(0.5)
    led.off()
    time.sleep(0.5)
```

### 🌡️ Temperature Sensor (C++)
```cpp
#include "hardware/adc.h"

float read_onboard_temperature() {
    adc_init();
    adc_set_temp_sensor_enabled(true);
    adc_select_input(4);
    
    uint16_t raw = adc_read();
    float voltage = raw * 3.3f / (1 << 12);
    return 27 - (voltage - 0.706) / 0.001721;
}
```

### 📡 WiFi Example (with Pico W)
```python
import network
import time

# Connect to WiFi
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect('your_ssid', 'your_password')

while not wlan.isconnected():
    time.sleep(1)
    
print('Connected:', wlan.ifconfig())
```

## 🔧 Development Tools

### Recommended IDEs
- **VS Code** with C/C++ and Python extensions
- **Thonny** for MicroPython development
- **Arduino IDE** with Pico support
- **CLion** for advanced C++ development

### Useful Tools
- **picotool** - Pico board management utility
- **openocd** - On-chip debugging
- **rshell** - MicroPython file transfer
- **ampy** - Adafruit MicroPython utility

## 📊 Pin Configuration

### GPIO Pin Mapping
```
     ┌─────────────────────┐
 1 - │ GP0          VBUS │ - 40
 2 - │ GP1          VSYS │ - 39
GND - │ GND            3V3│ - 36
 4 - │ GP2       3V3_EN  │ - 37
 5 - │ GP3            GND│ - 38
 6 - │ GP4          GP28 │ - 34
 7 - │ GP5     ADC2/GP27 │ - 32
GND - │ GND     ADC1/GP26 │ - 31
 9 - │ GP6      RUN      │ - 30
10 - │ GP7     ADC0/GP22 │ - 29
     └─────────────────────┘
```

### Special Functions
- **GP25**: Onboard LED
- **GP26-28**: ADC inputs
- **GP0-1**: UART0 (default)
- **GP4-5**: I2C0 (default)
- **GP16-19**: SPI0 (default)

## 🎓 Learning Resources

### Official Documentation
- [Raspberry Pi Pico Datasheet](https://datasheets.raspberrypi.org/pico/pico-datasheet.pdf)
- [RP2040 Datasheet](https://datasheets.raspberrypi.org/rp2040/rp2040-datasheet.pdf)
- [Pico SDK Documentation](https://raspberrypi.github.io/pico-sdk-doxygen/)
- [MicroPython Documentation](https://docs.micropython.org/en/latest/rp2/)

### Tutorials and Guides
- [Getting Started with Pico](https://projects.raspberrypi.org/en/projects/getting-started-with-the-pico)
- [Pico Examples Repository](https://github.com/raspberrypi/pico-examples)
- [MicroPython Tutorial](https://www.raspberrypi.org/documentation/microcontrollers/micropython.html)

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes: `git commit -m 'Add amazing feature'`
4. **Push** to branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Guidelines
- Follow C/C++ coding standards for C projects
- Use PEP 8 style for Python/MicroPython code
- Include comprehensive documentation
- Add examples for new features
- Test on actual hardware when possible

## 📝 Project Ideas

### Beginner Projects
- 🔄 **LED Blink** - Classic first project
- 🌡️ **Temperature Monitor** - Read onboard sensor
- 🔘 **Button Input** - GPIO input handling
- 🎵 **Buzzer Control** - PWM audio output

### Intermediate Projects
- 📊 **Data Logger** - Store sensor data to flash
- 🌐 **Web Server** - HTTP server with Pico W
- 🤖 **Servo Control** - PWM motor control
- 📱 **UART Communication** - Serial protocols

### Advanced Projects
- 🎮 **USB HID Device** - Custom keyboard/mouse
- 📡 **LoRa Communication** - Long-range wireless
- 🎛️ **PID Controller** - Closed-loop control system
- 🔍 **Logic Analyzer** - Multi-channel signal capture

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Raspberry Pi Foundation** - For creating the amazing Pico board
- **ARM** - For the efficient Cortex-M0+ architecture
- **MicroPython Community** - For excellent embedded Python support
- **Open Source Community** - For tools and libraries

## 🔗 Links

- **Official Pico Page**: https://www.raspberrypi.org/products/raspberry-pi-pico/
- **Pico SDK**: https://github.com/raspberrypi/pico-sdk
- **Pico Examples**: https://github.com/raspberrypi/pico-examples
- **MicroPython**: https://micropython.org/download/rpi-pico/
- **Community Forum**: https://www.raspberrypi.org/forums/

---

**Happy Coding! 🚀** 

*Building the future, one GPIO pin at a time.*