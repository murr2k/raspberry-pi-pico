#!/bin/bash

echo "🧪 USB Permissions Test for Raspberry Pi Pico"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠️ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

echo -e "${BLUE}👤 Current User: $USER${NC}"
echo ""

# Test 1: Group Memberships
echo "🔍 Test 1: Group Memberships"
echo "----------------------------"

if groups | grep -q "\bdialout\b"; then
    print_status "ok" "User is in dialout group (serial access)"
else
    print_status "error" "User NOT in dialout group"
    echo "   Fix: sudo usermod -a -G dialout $USER"
fi

if groups | grep -q "\bplugdev\b"; then
    print_status "ok" "User is in plugdev group (USB access)"
else
    print_status "error" "User NOT in plugdev group"
    echo "   Fix: sudo usermod -a -G plugdev $USER"
fi

echo ""

# Test 2: Device Detection
echo "🔍 Test 2: Device Detection"
echo "---------------------------"

if lsusb | grep -q "2e8a"; then
    DEVICE_INFO=$(lsusb | grep "2e8a")
    print_status "ok" "Raspberry Pi Pico detected"
    echo "   Device: $DEVICE_INFO"
    
    if echo "$DEVICE_INFO" | grep -q "2e8a:0003"; then
        echo "   Mode: Application mode (running firmware)"
    elif echo "$DEVICE_INFO" | grep -q "2e8a:000a"; then
        echo "   Mode: BOOTSEL mode (ready for flashing)"
    fi
else
    print_status "error" "No Raspberry Pi Pico device detected"
    echo "   Check: USB connection, device power, Windows USB passthrough"
fi

echo ""

# Test 3: udev Rules
echo "🔍 Test 3: udev Rules"
echo "---------------------"

UDEV_FILE="/etc/udev/rules.d/99-pico.rules"
if [ -f "$UDEV_FILE" ]; then
    print_status "ok" "udev rules file exists: $UDEV_FILE"
    
    if grep -q "2e8a" "$UDEV_FILE"; then
        print_status "ok" "udev rules contain Pico vendor ID (2e8a)"
    else
        print_status "error" "udev rules missing Pico vendor ID"
    fi
else
    print_status "error" "udev rules file not found"
    echo "   Run: ./tools/setup_usb_permissions.sh"
fi

echo ""

# Test 4: Serial Interface
echo "🔍 Test 4: Serial Interface"
echo "---------------------------"

if ls /dev/ttyACM* >/dev/null 2>&1; then
    SERIAL_DEVICE=$(ls /dev/ttyACM* | head -1)
    print_status "ok" "Serial device found: $SERIAL_DEVICE"
    
    # Check permissions
    PERMS=$(ls -la "$SERIAL_DEVICE")
    echo "   Permissions: $PERMS"
    
    if [ -r "$SERIAL_DEVICE" ]; then
        print_status "ok" "Read access to serial device"
    else
        print_status "error" "No read access to serial device"
    fi
    
    if [ -w "$SERIAL_DEVICE" ]; then
        print_status "ok" "Write access to serial device"
    else
        print_status "error" "No write access to serial device"
    fi
    
    # Test if device is busy
    if lsof "$SERIAL_DEVICE" >/dev/null 2>&1; then
        USING_PROCESS=$(lsof "$SERIAL_DEVICE" 2>/dev/null | tail -n +2 | awk '{print $1}' | head -1)
        print_status "warn" "Serial device busy (used by: $USING_PROCESS)"
    else
        print_status "ok" "Serial device available for use"
    fi
    
else
    print_status "error" "No serial interface found (/dev/ttyACM*)"
    echo "   Device may be in BOOTSEL mode or not properly enumerated"
fi

echo ""

# Test 5: picotool Access
echo "🔍 Test 5: picotool Access"
echo "--------------------------"

if command -v picotool >/dev/null 2>&1; then
    print_status "ok" "picotool is installed"
    echo "   Version: $(picotool version 2>/dev/null || echo 'Version check failed')"
    
    # Test device access
    PICOTOOL_OUTPUT=$(picotool info 2>&1)
    if echo "$PICOTOOL_OUTPUT" | grep -q "No accessible"; then
        if echo "$PICOTOOL_OUTPUT" | grep -q "USB serial connection"; then
            print_status "warn" "Device detected but in application mode"
            echo "   Use: picotool info -f (to force access)"
        else
            print_status "error" "picotool cannot access device"
        fi
    else
        print_status "ok" "picotool can access device"
    fi
else
    print_status "error" "picotool not found"
    echo "   Install: sudo apt install picotool"
fi

echo ""

# Test 6: Development Tools
echo "🔍 Test 6: Development Tools"
echo "----------------------------"

tools=("screen" "minicom" "cmake" "arm-none-eabi-gcc")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_status "ok" "$tool is installed"
    else
        print_status "warn" "$tool not found"
    fi
done

echo ""

# Test 7: VS Code Integration
echo "🔍 Test 7: VS Code Integration"
echo "------------------------------"

if [ -d ".vscode" ]; then
    print_status "ok" "VS Code workspace configuration exists"
    
    if [ -f ".vscode/tasks.json" ]; then
        print_status "ok" "VS Code tasks configured"
    else
        print_status "warn" "VS Code tasks not configured"
    fi
    
    if [ -f ".vscode/launch.json" ]; then
        print_status "ok" "VS Code debug configuration exists"
    else
        print_status "warn" "VS Code debug configuration missing"
    fi
else
    print_status "warn" "VS Code workspace not configured"
fi

echo ""

# Summary and Recommendations
echo "📋 Summary and Recommendations"
echo "=============================="

# Check if any critical issues exist
CRITICAL_ISSUES=false

if ! groups | grep -q "\bdialout\b"; then
    CRITICAL_ISSUES=true
fi

if ! lsusb | grep -q "2e8a"; then
    CRITICAL_ISSUES=true
fi

if [ "$CRITICAL_ISSUES" = true ]; then
    echo -e "${RED}❌ Critical issues found that prevent USB access${NC}"
    echo ""
    echo "🔧 Quick fixes:"
    echo "   1. Add to groups: sudo usermod -a -G dialout,plugdev $USER"
    echo "   2. Run USB setup: ./tools/setup_usb_permissions.sh"
    echo "   3. Reconnect device or run: sudo udevadm trigger"
    echo "   4. Log out and log back in"
else
    echo -e "${GREEN}✅ USB permissions appear to be configured correctly${NC}"
    echo ""
    echo "🚀 Ready for development:"
    echo "   make monitor          # Monitor temperature sensor"
    echo "   make flash-auto       # Flash new firmware"
    echo "   code .                # Open in VS Code"
fi

echo ""
echo "📞 Support Commands:"
echo "   lsusb | grep 2e8a               # Check device detection"
echo "   ls -la /dev/ttyACM*             # Check serial permissions"
echo "   groups                          # Check group memberships"
echo "   picotool info -a                # Test picotool access"
echo "   sudo udevadm trigger            # Reload device permissions"