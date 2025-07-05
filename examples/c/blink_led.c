/**
 * @file blink_led.c
 * @brief Basic LED blinking example for Raspberry Pi Pico
 * 
 * This example demonstrates:
 * - GPIO initialization and configuration
 * - Basic digital output control
 * - Timing delays using sleep functions
 * 
 * Hardware requirements:
 * - Raspberry Pi Pico board
 * - Onboard LED (GP25) or external LED on any GPIO pin
 * 
 * @author Raspberry Pi Pico Development Project
 * @date 2025
 */

#include "pico/stdlib.h"
#include "hardware/gpio.h"

// Pin definitions
#define LED_PIN 25          // Onboard LED pin
#define BLINK_DELAY_MS 500  // Blink delay in milliseconds

/**
 * @brief Main function - entry point of the program
 * 
 * Initializes the LED pin and enters an infinite loop
 * that toggles the LED state every BLINK_DELAY_MS milliseconds.
 * 
 * @return int Program exit status (never reached)
 */
int main() {
    // Initialize standard I/O (enables printf, etc.)
    stdio_init_all();
    
    // Initialize the LED pin
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    
    // Print startup message
    printf("Raspberry Pi Pico LED Blink Example\n");
    printf("LED Pin: GP%d\n", LED_PIN);
    printf("Blink Delay: %d ms\n", BLINK_DELAY_MS);
    
    // Main loop - blink LED forever
    while (true) {
        // Turn LED on
        gpio_put(LED_PIN, 1);
        printf("LED ON\n");
        sleep_ms(BLINK_DELAY_MS);
        
        // Turn LED off
        gpio_put(LED_PIN, 0);
        printf("LED OFF\n");
        sleep_ms(BLINK_DELAY_MS);
    }
    
    return 0;
}