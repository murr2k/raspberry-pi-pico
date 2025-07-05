#!/usr/bin/env python3

"""
Raspberry Pi Pico Automated Flashing Tool (Python)

This tool provides automated flashing capabilities for the Raspberry Pi Pico
without requiring manual bootloader mode entry.

Features:
- Automatic device detection
- USB reset functionality
- Watch mode for development
- Cross-platform support
- Progress monitoring
"""

import os
import sys
import time
import argparse
import subprocess
import threading
from pathlib import Path
import logging
from typing import Optional, List, Tuple

try:
    import usb.core
    import usb.util
    USB_AVAILABLE = True
except ImportError:
    USB_AVAILABLE = False
    print("Warning: pyusb not available. USB reset functionality disabled.")

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False
    print("Warning: watchdog not available. Watch mode disabled.")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# Device IDs for Raspberry Pi Pico
PICO_VID = 0x2E8A  # Raspberry Pi
PICO_BOOTLOADER_PID = 0x0003  # RP2 Boot
PICO_RUNTIME_PID = 0x000A     # Pico CDC

class PicoDevice:
    """Represents a connected Pico device"""
    
    def __init__(self, device_type: str, device_info: dict):
        self.type = device_type  # 'bootloader' or 'runtime'
        self.info = device_info

class PicoFlasher:
    """Main flashing utility class"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.build_dir = self.project_root / "examples" / "c" / "build"
        
    def find_pico_devices(self) -> List[PicoDevice]:
        """Find all connected Pico devices"""
        devices = []
        
        if not USB_AVAILABLE:
            logger.warning("USB support not available, falling back to picotool")
            return self._find_devices_picotool()
        
        try:
            # Find bootloader devices
            bootloader_devices = usb.core.find(
                find_all=True,
                idVendor=PICO_VID,
                idProduct=PICO_BOOTLOADER_PID
            )
            
            for dev in bootloader_devices:
                devices.append(PicoDevice('bootloader', {
                    'vendor_id': dev.idVendor,
                    'product_id': dev.idProduct,
                    'device': dev
                }))
                
            # Find runtime devices
            runtime_devices = usb.core.find(
                find_all=True,
                idVendor=PICO_VID,
                idProduct=PICO_RUNTIME_PID
            )
            
            for dev in runtime_devices:
                devices.append(PicoDevice('runtime', {
                    'vendor_id': dev.idVendor,
                    'product_id': dev.idProduct,
                    'device': dev
                }))
                
        except Exception as e:
            logger.error(f"USB device detection failed: {e}")
            return self._find_devices_picotool()
            
        return devices
    
    def _find_devices_picotool(self) -> List[PicoDevice]:
        """Fallback device detection using picotool"""
        devices = []
        
        try:
            # Check for bootloader devices
            result = subprocess.run(
                ['picotool', 'info', '-a'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0 and 'RP2040' in result.stdout:
                devices.append(PicoDevice('bootloader', {'source': 'picotool'}))
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.warning("picotool not available or timeout")
            
        return devices
    
    def force_bootloader_mode(self) -> bool:
        """Force Pico into bootloader mode using various methods"""
        logger.info("Attempting to force bootloader mode...")
        
        # Method 1: picotool reboot
        if self._picotool_reboot():
            time.sleep(2)
            if self._check_bootloader_mode():
                return True
                
        # Method 2: USB reset
        if USB_AVAILABLE and self._usb_reset():
            time.sleep(2)
            if self._check_bootloader_mode():
                return True
                
        # Method 3: Manual mode with timeout
        return self._wait_for_manual_bootloader()
    
    def _picotool_reboot(self) -> bool:
        """Reboot Pico using picotool"""
        try:
            result = subprocess.run(
                ['picotool', 'reboot', '-f'],
                capture_output=True,
                timeout=10
            )
            if result.returncode == 0:
                logger.info("picotool reboot successful")
                return True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.warning("picotool reboot failed")
        return False
    
    def _usb_reset(self) -> bool:
        """Reset Pico using USB reset"""
        if not USB_AVAILABLE:
            return False
            
        try:
            devices = usb.core.find(
                find_all=True,
                idVendor=PICO_VID,
                idProduct=PICO_RUNTIME_PID
            )
            
            for device in devices:
                try:
                    device.reset()
                    logger.info("USB reset successful")
                    return True
                except usb.core.USBError as e:
                    logger.warning(f"USB reset failed: {e}")
                    
        except Exception as e:
            logger.warning(f"USB reset error: {e}")
            
        return False
    
    def _check_bootloader_mode(self) -> bool:
        """Check if Pico is in bootloader mode"""
        devices = self.find_pico_devices()
        return any(dev.type == 'bootloader' for dev in devices)
    
    def _wait_for_manual_bootloader(self, timeout: int = 30) -> bool:
        """Wait for manual bootloader mode entry"""
        logger.warning("Automatic bootloader entry failed")
        logger.warning("Please manually enter bootloader mode:")
        logger.warning("1. Disconnect USB cable")
        logger.warning("2. Hold BOOTSEL button")
        logger.warning("3. Connect USB cable")
        logger.warning("4. Release BOOTSEL button")
        
        logger.info(f"Waiting {timeout} seconds for bootloader mode...")
        
        for i in range(timeout):
            if self._check_bootloader_mode():
                logger.info("Bootloader mode detected!")
                return True
            time.sleep(1)
            if i % 5 == 0:
                print(f"Still waiting... ({timeout - i}s remaining)")
                
        logger.error("Timeout waiting for bootloader mode")
        return False
    
    def flash_firmware(self, uf2_file: Path) -> bool:
        """Flash firmware to Pico"""
        if not uf2_file.exists():
            logger.error(f"UF2 file not found: {uf2_file}")
            return False
            
        logger.info(f"Flashing firmware: {uf2_file.name}")
        logger.info(f"File size: {uf2_file.stat().st_size / 1024:.1f} KB")
        
        try:
            # Flash using picotool
            result = subprocess.run(
                ['picotool', 'load', str(uf2_file)],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                logger.info("Firmware loaded successfully")
                
                # Reboot to run firmware
                reboot_result = subprocess.run(
                    ['picotool', 'reboot'],
                    capture_output=True,
                    timeout=10
                )
                
                if reboot_result.returncode == 0:
                    logger.info("Pico rebooted successfully")
                else:
                    logger.warning("Reboot failed, but firmware was loaded")
                    
                return True
            else:
                logger.error(f"Flash failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("Flash operation timed out")
            return False
        except FileNotFoundError:
            logger.error("picotool not found")
            return False
    
    def verify_flash(self) -> bool:
        """Verify flash operation by checking device state"""
        logger.info("Verifying flash operation...")
        time.sleep(3)  # Wait for reboot
        
        devices = self.find_pico_devices()
        runtime_devices = [d for d in devices if d.type == 'runtime']
        
        if runtime_devices:
            logger.info("✅ Pico is running new firmware")
            return True
        elif any(d.type == 'bootloader' for d in devices):
            logger.warning("⚠️ Pico is still in bootloader mode")
            return False
        else:
            logger.warning("⚠️ Pico not detected after flashing")
            return False
    
    def compile_and_flash(self, target: str = "blinky") -> bool:
        """Compile target and flash to Pico"""
        logger.info(f"Compiling {target}...")
        
        if not self.build_dir.exists():
            logger.error(f"Build directory not found: {self.build_dir}")
            return False
            
        try:
            # Change to build directory
            original_dir = os.getcwd()
            os.chdir(self.build_dir)
            
            # Clean build
            subprocess.run(['make', 'clean'], capture_output=True)
            
            # Build
            result = subprocess.run(
                ['make', '-j4'],
                capture_output=True,
                text=True,
                timeout=120
            )
            
            os.chdir(original_dir)
            
            if result.returncode == 0:
                logger.info("Compilation successful")
                uf2_file = self.build_dir / f"{target}.uf2"
                
                if uf2_file.exists():
                    return self.flash_firmware(uf2_file)
                else:
                    logger.error(f"UF2 file not generated: {uf2_file}")
                    return False
            else:
                logger.error(f"Compilation failed: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error("Compilation timed out")
            return False
        except Exception as e:
            logger.error(f"Compilation error: {e}")
            return False
    
    def auto_flash_workflow(self, uf2_file: Optional[Path] = None) -> bool:
        """Main automated flashing workflow"""
        logger.info("🚀 Starting automated flash process...")
        
        # Use default file if none specified
        if uf2_file is None:
            uf2_file = self.build_dir / "blinky.uf2"
        
        # Step 1: Find devices
        devices = self.find_pico_devices()
        bootloader_devices = [d for d in devices if d.type == 'bootloader']
        runtime_devices = [d for d in devices if d.type == 'runtime']
        
        if bootloader_devices:
            logger.info("✅ Pico found in bootloader mode")
        elif runtime_devices:
            logger.info("🔄 Pico found in runtime mode, forcing bootloader...")
            if not self.force_bootloader_mode():
                logger.error("❌ Failed to enter bootloader mode")
                return False
        else:
            logger.error("❌ No Pico devices found")
            return False
        
        # Step 2: Flash firmware
        if self.flash_firmware(uf2_file):
            logger.info("✅ Flash operation completed")
            
            # Step 3: Verify
            if self.verify_flash():
                logger.info("🎉 Automated flashing successful!")
                return True
            else:
                logger.warning("⚠️ Flash completed but verification failed")
                return True  # Still consider success since flash completed
        else:
            logger.error("❌ Flash operation failed")
            return False

class SourceFileHandler(FileSystemEventHandler):
    """File system event handler for watch mode"""
    
    def __init__(self, flasher: PicoFlasher, target: str):
        self.flasher = flasher
        self.target = target
        self.last_build = 0
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        # Only trigger on C/C++ source files
        if event.src_path.endswith(('.c', '.cpp', '.h', '.hpp')):
            current_time = time.time()
            
            # Debounce: only build if 2 seconds have passed
            if current_time - self.last_build > 2:
                self.last_build = current_time
                logger.info(f"Source file changed: {event.src_path}")
                
                # Run compilation and flash in separate thread
                threading.Thread(
                    target=self._compile_and_flash_thread,
                    daemon=True
                ).start()
    
    def _compile_and_flash_thread(self):
        """Thread function for compilation and flashing"""
        try:
            if self.flasher.compile_and_flash(self.target):
                logger.info("🎉 Auto-flash completed successfully")
            else:
                logger.error("❌ Auto-flash failed")
        except Exception as e:
            logger.error(f"Auto-flash error: {e}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Raspberry Pi Pico Automated Flashing Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Flash default blinky.uf2
  %(prog)s -f custom.uf2           # Flash specific file
  %(prog)s -c -t temperature       # Compile and flash temperature example
  %(prog)s -w                      # Watch mode for automatic flashing
        """
    )
    
    parser.add_argument(
        '-f', '--file',
        type=Path,
        help='UF2 file to flash'
    )
    
    parser.add_argument(
        '-c', '--compile',
        action='store_true',
        help='Compile before flashing'
    )
    
    parser.add_argument(
        '-t', '--target',
        default='blinky',
        help='Target name to compile (default: blinky)'
    )
    
    parser.add_argument(
        '-w', '--watch',
        action='store_true',
        help='Watch mode - auto-compile and flash on changes'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    flasher = PicoFlasher()
    
    # Watch mode
    if args.watch:
        if not WATCHDOG_AVAILABLE:
            logger.error("Watch mode requires 'watchdog' package: pip install watchdog")
            return 1
            
        logger.info("🔍 Starting watch mode for automatic flashing...")
        logger.info(f"Watching: {flasher.project_root}/examples/c")
        logger.info(f"Target: {args.target}")
        logger.warning("Press Ctrl+C to stop")
        
        event_handler = SourceFileHandler(flasher, args.target)
        observer = Observer()
        observer.schedule(
            event_handler,
            str(flasher.project_root / "examples" / "c"),
            recursive=True
        )
        
        try:
            observer.start()
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Stopping watch mode...")
            observer.stop()
        observer.join()
        return 0
    
    # Compile mode
    if args.compile:
        success = flasher.compile_and_flash(args.target)
        return 0 if success else 1
    
    # Flash mode
    if args.file:
        success = flasher.auto_flash_workflow(args.file)
    else:
        success = flasher.auto_flash_workflow()
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())