#!/usr/bin/env python3
"""
Enhanced Serial Monitor for Raspberry Pi Pico
Provides interactive monitoring with built-in commands
"""

import serial
import threading
import time
import sys
import signal
import glob
import os
from datetime import datetime

class PicoMonitor:
    def __init__(self, port=None, baudrate=115200):
        self.baudrate = baudrate
        self.port = port or self.find_pico_port()
        self.serial_conn = None
        self.running = False
        self.monitor_thread = None
        self.command_history = []
        
    def find_pico_port(self):
        """Find the first available Pico serial port"""
        possible_ports = glob.glob('/dev/ttyACM*') + glob.glob('/dev/ttyUSB*')
        
        for port in possible_ports:
            try:
                # Try to open the port briefly to check if it's accessible
                with serial.Serial(port, self.baudrate, timeout=0.1):
                    return port
            except (serial.SerialException, PermissionError):
                continue
        
        return None
    
    def connect(self):
        """Connect to the Pico"""
        if not self.port:
            print("❌ No Pico serial port found")
            print("💡 Make sure:")
            print("   - Pico is connected via USB")
            print("   - Device is running firmware with USB stdio")
            print("   - You have permissions (run: ./tools/setup_usb_permissions.sh)")
            return False
        
        try:
            self.serial_conn = serial.Serial(
                self.port, 
                self.baudrate, 
                timeout=0.1,
                write_timeout=1.0
            )
            print(f"✅ Connected to {self.port} at {self.baudrate} baud")
            return True
        except serial.SerialException as e:
            print(f"❌ Failed to connect to {self.port}: {e}")
            return False
        except PermissionError:
            print(f"❌ Permission denied for {self.port}")
            print("🔧 Fix permissions: ./tools/setup_usb_permissions.sh")
            return False
    
    def disconnect(self):
        """Disconnect from the Pico"""
        self.running = False
        if self.monitor_thread and self.monitor_thread.is_alive():
            self.monitor_thread.join(timeout=1.0)
        
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print(f"\n📤 Disconnected from {self.port}")
    
    def send_command(self, command):
        """Send a command to the Pico"""
        if not self.serial_conn or not self.serial_conn.is_open:
            print("❌ Not connected to device")
            return False
        
        try:
            self.serial_conn.write(f"{command}\r\n".encode('utf-8'))
            self.serial_conn.flush()
            self.command_history.append(command)
            print(f"📤 Sent: {command}")
            return True
        except serial.SerialException as e:
            print(f"❌ Failed to send command: {e}")
            return False
    
    def read_from_pico(self):
        """Read data from Pico in a separate thread"""
        while self.running and self.serial_conn and self.serial_conn.is_open:
            try:
                if self.serial_conn.in_waiting > 0:
                    data = self.serial_conn.readline().decode('utf-8', errors='ignore').strip()
                    if data:
                        timestamp = datetime.now().strftime("%H:%M:%S")
                        print(f"📥 [{timestamp}] {data}")
                else:
                    time.sleep(0.01)  # Small delay to prevent busy waiting
            except serial.SerialException:
                break
            except UnicodeDecodeError:
                # Handle any encoding issues
                continue
    
    def print_help(self):
        """Print available monitor commands"""
        print("\n📋 Enhanced Monitor Commands:")
        print("=" * 50)
        print("🎮 Monitor Commands:")
        print("   quit, exit, q     - Exit monitor gracefully")
        print("   help, ?           - Show this help")
        print("   clear, cls        - Clear screen")
        print("   status            - Show connection status")
        print("   history           - Show command history")
        print("   reconnect         - Reconnect to device")
        print("")
        print("🌡️ Pico Commands (sent to device):")
        print("   TEMP              - Get current temperature")
        print("   STATS             - Show temperature statistics")
        print("   HISTORY           - Show temperature history")
        print("   INTERVAL <ms>     - Set report interval")
        print("   START_TEMP        - Enable temperature monitoring")
        print("   STOP_TEMP         - Disable temperature monitoring")
        print("   RESET_STATS       - Reset temperature statistics")
        print("   BOOTSEL           - Enter bootloader mode")
        print("   HELP              - Show Pico commands")
        print("")
        print("💡 Tips:")
        print("   - Type any command and press Enter")
        print("   - Commands starting with uppercase are sent to Pico")
        print("   - Commands starting with lowercase are monitor commands")
        print("   - Ctrl+C also exits gracefully")
    
    def print_status(self):
        """Print connection status"""
        print(f"\n📊 Monitor Status:")
        print(f"   Port: {self.port}")
        print(f"   Baudrate: {self.baudrate}")
        print(f"   Connected: {'✅ Yes' if self.serial_conn and self.serial_conn.is_open else '❌ No'}")
        print(f"   Running: {'✅ Yes' if self.running else '❌ No'}")
        if self.command_history:
            print(f"   Last command: {self.command_history[-1]}")
        print("")
    
    def run_interactive(self):
        """Run the interactive monitor"""
        print("🔗 Enhanced Raspberry Pi Pico Monitor")
        print("=" * 50)
        print(f"📡 Monitoring: {self.port} at {self.baudrate} baud")
        print("💡 Type 'help' for commands, 'quit' to exit")
        print("📥 Live data will appear below:")
        print("-" * 50)
        
        if not self.connect():
            return
        
        # Set up signal handler for graceful exit
        def signal_handler(sig, frame):
            print("\n🛑 Received interrupt signal")
            self.running = False
        
        signal.signal(signal.SIGINT, signal_handler)
        
        # Start monitoring thread
        self.running = True
        self.monitor_thread = threading.Thread(target=self.read_from_pico, daemon=True)
        self.monitor_thread.start()
        
        # Interactive command loop
        try:
            while self.running:
                try:
                    command = input().strip()
                    
                    if not command:
                        continue
                    
                    # Handle monitor commands (lowercase)
                    cmd_lower = command.lower()
                    
                    if cmd_lower in ['quit', 'exit', 'q']:
                        print("👋 Exiting monitor...")
                        break
                    
                    elif cmd_lower in ['help', '?']:
                        self.print_help()
                    
                    elif cmd_lower in ['clear', 'cls']:
                        os.system('clear' if os.name == 'posix' else 'cls')
                    
                    elif cmd_lower == 'status':
                        self.print_status()
                    
                    elif cmd_lower == 'history':
                        print(f"\n📝 Command History ({len(self.command_history)} commands):")
                        for i, cmd in enumerate(self.command_history[-10:], 1):
                            print(f"   {i:2d}. {cmd}")
                        print("")
                    
                    elif cmd_lower == 'reconnect':
                        print("🔄 Reconnecting...")
                        self.disconnect()
                        time.sleep(1)
                        if self.connect():
                            self.running = True
                            self.monitor_thread = threading.Thread(target=self.read_from_pico, daemon=True)
                            self.monitor_thread.start()
                    
                    else:
                        # Send command to Pico
                        self.send_command(command)
                
                except EOFError:
                    # Handle Ctrl+D
                    print("\n👋 EOF received, exiting...")
                    break
                except KeyboardInterrupt:
                    # Handle Ctrl+C
                    print("\n👋 Interrupt received, exiting...")
                    break
        
        finally:
            self.running = False
            self.disconnect()

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Enhanced Raspberry Pi Pico Monitor')
    parser.add_argument('-p', '--port', help='Serial port (auto-detected if not specified)')
    parser.add_argument('-b', '--baudrate', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('--list-ports', action='store_true', help='List available serial ports')
    
    args = parser.parse_args()
    
    if args.list_ports:
        print("📱 Available serial ports:")
        ports = glob.glob('/dev/ttyACM*') + glob.glob('/dev/ttyUSB*')
        if ports:
            for port in ports:
                print(f"   {port}")
        else:
            print("   No serial ports found")
        return
    
    monitor = PicoMonitor(port=args.port, baudrate=args.baudrate)
    monitor.run_interactive()

if __name__ == '__main__':
    main()