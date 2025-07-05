#!/bin/bash

echo "🚀 Direct Temperature Sensor Flash"
echo "=================================="
echo ""

echo "🔍 Waiting for device detection..."
TIMEOUT=30
COUNT=0

while [ $COUNT -lt $TIMEOUT ]; do
    if lsusb | grep -q "2e8a"; then
        echo "✅ Pico device detected!"
        lsusb | grep "2e8a"
        break
    fi
    echo -n "."
    sleep 1
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $TIMEOUT ]; then
    echo ""
    echo "❌ Device not found after ${TIMEOUT} seconds"
    echo "💡 Re-attach device: usbipd attach --wsl --busid 2-X"
    exit 1
fi

echo ""
echo "📋 Device State Check:"
if lsusb | grep -q "2e8a:000a"; then
    echo "✅ Device in BOOTSEL mode - ready for direct flash"
    BOOTSEL_MODE=true
elif lsusb | grep -q "2e8a:0003"; then
    echo "⚠️ Device in application mode - needs reset to BOOTSEL"
    echo "🔄 Attempting reset..."
    picotool reboot -f -u
    echo "⏱️ Waiting for BOOTSEL mode..."
    sleep 3
    
    if lsusb | grep -q "2e8a:000a"; then
        echo "✅ Successfully reset to BOOTSEL mode"
        BOOTSEL_MODE=true
    else
        echo "❌ Reset failed, try manual BOOTSEL"
        echo "💡 Hold BOOTSEL button and reconnect USB"
        exit 1
    fi
fi

if [ "$BOOTSEL_MODE" = true ]; then
    echo ""
    echo "🚀 Flashing Enhanced Temperature Sensor..."
    echo "File: build/temperature_enhanced.uf2 ($(du -h build/temperature_enhanced.uf2 | cut -f1))"
    
    # Direct picotool flash
    if picotool load build/temperature_enhanced.uf2 --force; then
        echo "✅ Flash successful!"
        
        # Reboot to application mode
        echo "🔄 Rebooting to application mode..."
        picotool reboot
        
        echo "⏱️ Waiting for device to boot..."
        sleep 3
        
        echo ""
        echo "🔍 Checking for USB serial interface..."
        if ls /dev/ttyACM* >/dev/null 2>&1; then
            DEVICE=$(ls /dev/ttyACM* | head -1)
            echo "✅ Serial interface ready: $DEVICE"
            
            echo ""
            echo "🌡️ TEMPERATURE REPORTS WILL APPEAR HERE:"
            echo "   📺 Live monitoring: make monitor"
            echo "   🎮 Interactive commands: TEMP, STATS, HISTORY"
            echo "   ⏱️ Automatic reports: Every 2000ms"
            echo ""
            echo "🎉 SUCCESS! Enhanced temperature sensor is running!"
            echo ""
            echo "🚀 Start monitoring now:"
            echo "   make monitor"
            
        else
            echo "⚠️ No serial interface yet, wait a moment and try:"
            echo "   make monitor"
        fi
        
    else
        echo "❌ Flash failed"
        exit 1
    fi
else
    echo "❌ Could not get device into BOOTSEL mode"
    exit 1
fi