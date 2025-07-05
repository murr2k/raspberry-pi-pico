#!/bin/bash

echo "🌡️ Enhanced Temperature Sensor Flashing Demo"
echo "============================================="
echo ""

echo "📋 Step 1: Device Detection"
echo "Checking for Pico devices..."

if lsusb | grep -q "2e8a"; then
    echo "✅ Pico device detected:"
    lsusb | grep "2e8a"
    
    if lsusb | grep -q "2e8a:0003"; then
        echo "✅ Device in application mode - runtime update available!"
        RUNTIME_UPDATE=true
    elif lsusb | grep -q "2e8a:000a"; then
        echo "✅ Device in BOOTSEL mode - ready for flashing"
        BOOTSEL_MODE=true
    fi
else
    echo "❌ No Pico device found"
    echo ""
    echo "🔧 Re-attach device from Windows:"
    echo "   1. Windows PowerShell (Administrator):"
    echo "      usbipd list"
    echo "      usbipd attach --wsl --busid 2-X"
    echo "   2. Wait for device enumeration"
    echo "   3. Run this script again"
    exit 1
fi

echo ""
echo "📋 Step 2: Firmware Information"
echo "Target: Enhanced Temperature Sensor with Runtime Updates"
echo "File: build/temperature_enhanced.uf2 ($(du -h build/temperature_enhanced.uf2 | cut -f1))"
echo "Features:"
echo "  ✅ Real-time temperature monitoring"
echo "  ✅ Interactive USB serial commands"
echo "  ✅ Temperature statistics and history"
echo "  ✅ Runtime firmware updates (no BOOTSEL!)"
echo "  ✅ Configurable report intervals"

echo ""
echo "📋 Step 3: Professional Flashing Methods Available"

if [ "$RUNTIME_UPDATE" = true ]; then
    echo ""
    echo "🚀 Method 1: Zero-Friction Runtime Update (RECOMMENDED)"
    echo "   Command: make flash-runtime-compile TARGET=temperature_enhanced"
    echo "   ✅ No BOOTSEL button required"
    echo "   ✅ Instant updates while running"
    echo "   ✅ Professional development workflow"
    
    echo ""
    echo "🔄 Executing zero-friction update..."
    make flash-runtime-compile TARGET=temperature_enhanced
    
elif [ "$BOOTSEL_MODE" = true ]; then
    echo ""
    echo "🎯 Method 2: Direct BOOTSEL Flashing"
    echo "   Command: picotool load build/temperature_enhanced.uf2"
    echo "   ✅ Direct programming"
    echo "   ✅ Reliable flashing"
    
    echo ""
    echo "🔄 Executing direct flash..."
    picotool load build/temperature_enhanced.uf2 --force
    picotool reboot
fi

echo ""
echo "📋 Step 4: Post-Flash Verification"
echo "Waiting for device to boot..."
sleep 3

echo ""
echo "🔍 Checking for USB serial interface..."
if ls /dev/ttyACM* >/dev/null 2>&1; then
    DEVICE=$(ls /dev/ttyACM* | head -1)
    echo "✅ Serial interface found: $DEVICE"
    
    echo ""
    echo "📋 Step 5: Testing Temperature Monitoring"
    echo "🌡️ WHERE TO SEE TEMPERATURE REPORTS:"
    echo "   📺 Live monitoring: make monitor"
    echo "   🎮 Interactive commands: TEMP, STATS, HISTORY"
    echo "   ⏱️ Automatic reports: Every 2000ms"
    echo "   🔄 Runtime updates: Via USB commands"
    
    echo ""
    echo "🎉 SUCCESS! Enhanced temperature sensor is ready!"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Start monitoring: make monitor"
    echo "   2. Send commands: TEMP, STATS, HELP"
    echo "   3. Change intervals: INTERVAL 1000"
    echo "   4. Runtime updates: make flash-runtime-compile TARGET=other_firmware"
    
else
    echo "⚠️ No serial interface detected yet"
    echo "💡 Try re-attaching device:"
    echo "   usbipd attach --wsl --busid 2-X"
fi

echo ""
echo "🔧 Available Flash Commands:"
echo "   make flash-runtime-compile TARGET=temperature_enhanced  # Zero-friction update"
echo "   make flash-auto TARGET=temperature_enhanced            # Automated detection" 
echo "   make flash-swd TARGET=temperature_enhanced             # SWD programming"
echo "   make monitor                                           # Start temperature monitoring"

echo ""
echo "✨ Professional embedded development - zero friction, maximum productivity!"