#!/bin/bash
echo "🔍 Testing Enhanced Firmware Serial Interface"
echo "============================================="
echo ""

echo "📊 Device Detection:"
if lsusb | grep -q "2e8a"; then
    echo "✅ Pico device found:"
    lsusb | grep "2e8a"
    
    if lsusb | grep -q "2e8a:0003"; then
        echo "✅ Device in application mode (enhanced firmware)"
    elif lsusb | grep -q "2e8a:000a"; then
        echo "⚠️ Device in BOOTSEL mode"
    fi
else
    echo "❌ No Pico device detected"
    echo "💡 Re-attach device in Windows: usbipd attach --wsl --busid 2-X"
fi

echo ""
echo "📱 Serial Device Check:"
if ls /dev/ttyACM* >/dev/null 2>&1; then
    echo "✅ Serial devices found:"
    ls -la /dev/ttyACM*
    
    echo ""
    echo "🎮 Testing Enhanced Firmware Commands:"
    DEVICE=$(ls /dev/ttyACM* | head -1)
    echo "Using device: $DEVICE"
    
    # Test basic communication
    echo "📤 Sending STATUS command..."
    echo "STATUS" > $DEVICE 2>/dev/null && echo "✅ Command sent" || echo "❌ Failed to send"
    
    echo ""
    echo "📥 Listening for response (5 seconds)..."
    timeout 5 cat $DEVICE 2>/dev/null || echo "No response received"
    
else
    echo "❌ No serial devices found (/dev/ttyACM*)"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "1. Check Windows: usbipd list | findstr '2e8a'"
    echo "2. Re-attach: usbipd attach --wsl --busid 2-X"
    echo "3. Wait a moment for enumeration"
    echo "4. Check permissions: ls -la /dev/ttyACM*"
fi

echo ""
echo "🎯 Enhanced Firmware Commands Available:"
echo "   HELP        - Show all commands"
echo "   STATUS      - System status" 
echo "   FAST        - Fast LED blink (125ms)"
echo "   SLOW        - Slow LED blink (1000ms)"
echo "   START       - Enable LED"
echo "   STOP        - Disable LED"
echo "   BOOTSEL     - Enter bootloader (runtime update!)"
echo "   RESET       - Soft reset"
echo "   INFO        - Device information"
echo ""
echo "🚀 Zero-friction development ready once serial is working!"