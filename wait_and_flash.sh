#!/bin/bash
# Wait for device and flash enhanced firmware

echo "🔍 Waiting for Raspberry Pi Pico device..."
echo "💡 Make sure to re-attach device in Windows first!"
echo ""

# Wait for device to appear
for i in {1..30}; do
    if lsusb | grep -q "2e8a"; then
        echo "✅ Device found!"
        lsusb | grep "2e8a"
        echo ""
        
        # Check if it's BOOTSEL mode
        if lsusb | grep -q "2e8a:000a"; then
            echo "📱 Device in BOOTSEL mode - ready for flashing!"
            echo "🚀 Flashing enhanced firmware..."
            make flash-auto TARGET=blink_led_enhanced
            break
        else
            echo "📱 Device in application mode"
            echo "🔄 Trying runtime flash..."
            make flash-runtime TARGET=blink_led_enhanced
            break
        fi
    else
        echo "⏳ Waiting... ($i/30)"
        sleep 2
    fi
done

if [ $i -eq 30 ]; then
    echo "❌ Device not found after 60 seconds"
    echo "💡 Please check Windows attachment with: usbipd list"
fi