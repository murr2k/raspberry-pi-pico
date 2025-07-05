/**
 * @file blink_led_enhanced.c
 * @brief Enhanced LED blinking example with runtime update capabilities
 * 
 * This example demonstrates:
 * - GPIO initialization and control
 * - Basic digital output control
 * - Runtime firmware update system
 * - USB serial commands for remote control
 * 
 * Hardware requirements:
 * - Raspberry Pi Pico board
 * - Onboard LED (GP25) or external LED on any GPIO pin
 * 
 * Runtime update features:
 * - No BOOTSEL button required for updates
 * - USB serial command interface
 * - Remote reset to bootloader
 * - Device information querying
 * 
 * @author Raspberry Pi Pico Development Project
 * @date 2025
 */

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "../../src/c/runtime_update.h"

// Pin definitions
#define LED_PIN 25          // Onboard LED pin
#define BLINK_DELAY_MS 250  // Blink delay in milliseconds (doubled rate)

// Runtime update commands
#define CMD_HELP        "HELP"
#define CMD_STATUS      "STATUS"
#define CMD_SPEED_FAST  "FAST"
#define CMD_SPEED_SLOW  "SLOW"
#define CMD_STOP        "STOP"
#define CMD_START       "START"

// Application state
static bool led_enabled = true;
static uint32_t current_delay = BLINK_DELAY_MS;
static bool led_state = false;
static absolute_time_t last_blink_time;

/**
 * @brief Process application-specific commands
 */
void process_app_commands(const char* command) {
    if (strncmp(command, CMD_HELP, 4) == 0) {
        printf("📋 Available Commands:\n");
        printf("   LED Control:\n");
        printf("     HELP        - Show this help\n");
        printf("     STATUS      - Show current status\n");
        printf("     FAST        - Fast blinking (125ms)\n");
        printf("     SLOW        - Slow blinking (1000ms)\n");
        printf("     START       - Enable LED blinking\n");
        printf("     STOP        - Disable LED blinking\n");
        printf("   \n");
        printf("   Runtime Updates:\n");
        printf("     BOOTSEL     - Enter bootloader mode\n");
        printf("     RESET       - Soft reset system\n");
        printf("     INFO        - Show device info\n");
        printf("     PREPARE     - Prepare for update\n");
        
    } else if (strncmp(command, CMD_STATUS, 6) == 0) {
        printf("📊 System Status:\n");
        printf("   LED Pin: GP%d\n", LED_PIN);
        printf("   LED State: %s\n", led_state ? "ON" : "OFF");
        printf("   LED Enabled: %s\n", led_enabled ? "YES" : "NO");
        printf("   Blink Delay: %d ms\n", current_delay);
        printf("   Runtime Updates: ENABLED\n");
        
    } else if (strncmp(command, CMD_SPEED_FAST, 4) == 0) {
        current_delay = 125;
        printf("⚡ Fast blink mode: %d ms\n", current_delay);
        
    } else if (strncmp(command, CMD_SPEED_SLOW, 4) == 0) {
        current_delay = 1000;
        printf("🐌 Slow blink mode: %d ms\n", current_delay);
        
    } else if (strncmp(command, CMD_START, 5) == 0) {
        led_enabled = true;
        printf("▶️ LED blinking enabled\n");
        
    } else if (strncmp(command, CMD_STOP, 4) == 0) {
        led_enabled = false;
        gpio_put(LED_PIN, 0);
        led_state = false;
        printf("⏹️ LED blinking disabled\n");
        
    } else {
        // Try runtime update commands
        runtime_process_command(command);
    }
}

/**
 * @brief Enhanced command processing with app and runtime commands
 */
void enhanced_command_loop(void) {
    static char command_buffer[64];
    static int buffer_pos = 0;
    
    int c = getchar_timeout_us(0);
    if (c != PICO_ERROR_TIMEOUT) {
        if (c == '\n' || c == '\r') {
            if (buffer_pos > 0) {
                command_buffer[buffer_pos] = '\0';
                process_app_commands(command_buffer);
                buffer_pos = 0;
            }
        } else if (buffer_pos < sizeof(command_buffer) - 1) {
            command_buffer[buffer_pos++] = c;
        }
    }
}

/**
 * @brief Update LED blinking logic
 */
void update_led_blink(void) {
    if (!led_enabled) {
        return;
    }
    
    if (absolute_time_diff_us(last_blink_time, get_absolute_time()) >= (current_delay * 1000)) {
        led_state = !led_state;
        gpio_put(LED_PIN, led_state);
        last_blink_time = get_absolute_time();
        
        printf("LED %s (delay: %dms)\n", led_state ? "ON" : "OFF", current_delay);
    }
}

/**
 * @brief Main function - entry point of the program
 * 
 * Initializes the LED pin, runtime update system, and enters an infinite loop
 * that handles both LED blinking and runtime update commands.
 * 
 * @return int Program exit status (never reached)
 */
int main() {
    // Initialize standard I/O (enables printf, USB serial, etc.)
    stdio_init_all();
    
    // Initialize the LED pin
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    gpio_put(LED_PIN, 0);
    
    // Initialize runtime update system
    runtime_update_init();
    
    // Initialize timing
    last_blink_time = get_absolute_time();
    
    // Print startup information
    printf("\n🎉 Enhanced Raspberry Pi Pico LED Blink Example\n");
    printf("===============================================\n");
    printf("📋 Features:\n");
    printf("   ✅ LED blinking with configurable speed\n");
    printf("   ✅ USB serial command interface\n");
    printf("   ✅ Runtime firmware updates (no BOOTSEL!)\n");
    printf("   ✅ Remote control capabilities\n");
    printf("\n");
    printf("🔧 Configuration:\n");
    printf("   LED Pin: GP%d\n", LED_PIN);
    printf("   Initial Delay: %d ms\n", current_delay);
    printf("   Runtime Updates: ENABLED\n");
    printf("\n");
    printf("💡 Type 'HELP' for available commands\n");
    printf("🚀 Ready for operation!\n\n");
    
    // Main loop - handle LED blinking and commands
    while (true) {
        // Update LED blinking
        update_led_blink();
        
        // Process USB serial commands
        enhanced_command_loop();
        
        // Small delay to prevent excessive CPU usage
        sleep_us(100);
    }
    
    return 0;
}