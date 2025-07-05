"""
Raspberry Pi Pico LED Blink Example - MicroPython

This example demonstrates:
- Basic GPIO control using machine module
- Digital output operations
- Timing delays using time.sleep()

Hardware requirements:
- Raspberry Pi Pico board
- Onboard LED (Pin 25) or external LED on any GPIO pin

Author: Raspberry Pi Pico Development Project
Date: 2025
"""

import machine
import time

# Pin definitions
LED_PIN = 25          # Onboard LED pin
BLINK_DELAY = 0.5     # Blink delay in seconds

def main():
    """
    Main function that initializes the LED and starts blinking
    """
    # Initialize LED pin as output
    led = machine.Pin(LED_PIN, machine.Pin.OUT)
    
    # Print startup information
    print("Raspberry Pi Pico LED Blink Example")
    print(f"LED Pin: GP{LED_PIN}")
    print(f"Blink Delay: {BLINK_DELAY} seconds")
    print("Starting LED blink sequence...")
    
    # Main loop - blink LED forever
    try:
        while True:
            # Turn LED on
            led.on()
            print("LED ON")
            time.sleep(BLINK_DELAY)
            
            # Turn LED off
            led.off()
            print("LED OFF")
            time.sleep(BLINK_DELAY)
            
    except KeyboardInterrupt:
        # Handle Ctrl+C gracefully
        print("\nProgram interrupted by user")
        led.off()  # Ensure LED is off when exiting
        print("LED turned off. Goodbye!")

# Alternative using led.value() method
def blink_alternative():
    """
    Alternative implementation using value() method
    """
    led = machine.Pin(LED_PIN, machine.Pin.OUT)
    state = 0
    
    while True:
        led.value(state)
        state = 1 - state  # Toggle between 0 and 1
        time.sleep(BLINK_DELAY)

# Run the main function
if __name__ == "__main__":
    main()