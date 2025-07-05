#!/bin/bash

# USB Permissions Setup for Raspberry Pi Pico
# This script sets up proper USB permissions for picotool access

set -e

echo "🔧 Setting up USB permissions for Raspberry Pi Pico..."

# Create udev rule for Raspberry Pi Pico
UDEV_RULE_FILE="/etc/udev/rules.d/99-pico.rules"
UDEV_RULE_CONTENT='# Raspberry Pi Pico BOOTSEL mode
SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", MODE="0666", TAG+="uaccess"

# Raspberry Pi Pico running mode
SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666", TAG+="uaccess"

# Generic RP2040 devices
SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", MODE="0666", TAG+="uaccess"'

echo "Creating udev rule at $UDEV_RULE_FILE..."
echo "$UDEV_RULE_CONTENT" | sudo tee "$UDEV_RULE_FILE" > /dev/null

echo "Adding user to dialout group..."
sudo usermod -a -G dialout $USER

echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "✅ USB permissions configured!"
echo ""
echo "⚠️  Important: You may need to:"
echo "   1. Disconnect and reconnect your Pico"
echo "   2. Or run: sudo udevadm trigger"
echo "   3. Or logout and login again for group changes"
echo ""
echo "Test with: picotool info -a"