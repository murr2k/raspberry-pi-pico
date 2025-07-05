/**
 * @file temperature_simple.c
 * @brief Simple temperature sensor for immediate testing
 * 
 * This is a simplified version that demonstrates temperature monitoring
 * without complex build dependencies.
 */

#include "pico/stdlib.h"
#include "hardware/adc.h"
#include "hardware/gpio.h"
#include <stdio.h>

// Constants for temperature calculation
#define TEMPERATURE_SENSOR_CHANNEL 4    // ADC channel for internal temp sensor
#define ADC_RESOLUTION 4096            // 12-bit ADC (2^12)
#define VOLTAGE_REFERENCE 3.3f         // Reference voltage
#define TEMP_SENSOR_VOLTAGE_27C 0.706f // Voltage at 27°C
#define TEMP_SENSOR_SLOPE 0.001721f    // V/°C slope

// LED pin for visual feedback
#define LED_PIN 25

// Simple command buffer
static char cmd_buffer[32];
static int cmd_pos = 0;

/**
 * @brief Read the internal temperature sensor
 */
float read_onboard_temperature() {
    adc_select_input(TEMPERATURE_SENSOR_CHANNEL);
    uint16_t adc_raw = adc_read();
    float voltage = (float)adc_raw * VOLTAGE_REFERENCE / ADC_RESOLUTION;
    float temperature = 27.0f - (voltage - TEMP_SENSOR_VOLTAGE_27C) / TEMP_SENSOR_SLOPE;
    return temperature;
}

/**
 * @brief Initialize temperature sensor
 */
void init_temperature_sensor() {
    adc_init();
    adc_set_temp_sensor_enabled(true);
    adc_set_clkdiv(48000);  // Slow down ADC for better accuracy
}

/**
 * @brief Process simple commands
 */
void process_commands() {
    int c = getchar_timeout_us(0);
    if (c != PICO_ERROR_TIMEOUT) {
        if (c == '\n' || c == '\r') {
            if (cmd_pos > 0) {
                cmd_buffer[cmd_pos] = '\0';
                
                // Process commands
                if (cmd_buffer[0] == 'T' || cmd_buffer[0] == 't') {
                    float temp = read_onboard_temperature();
                    printf("🌡️ Temperature: %.2f°C\n", temp);
                    
                } else if (cmd_buffer[0] == 'H' || cmd_buffer[0] == 'h') {
                    printf("📋 Commands:\n");
                    printf("  T - Get temperature\n");
                    printf("  H - Show help\n");
                    printf("  S - Show status\n");
                    
                } else if (cmd_buffer[0] == 'S' || cmd_buffer[0] == 's') {
                    printf("📊 Simple Temperature Monitor Status:\n");
                    printf("  Device: Raspberry Pi Pico\n");
                    printf("  Sensor: Internal RP2040 temperature sensor\n");
                    printf("  Status: Active\n");
                }
                
                cmd_pos = 0;
            }
        } else if (cmd_pos < sizeof(cmd_buffer) - 1) {
            cmd_buffer[cmd_pos++] = c;
        }
    }
}

/**
 * @brief Main function
 */
int main() {
    // Initialize standard I/O
    stdio_init_all();
    
    // Initialize LED for visual feedback
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    
    // Initialize temperature sensor
    init_temperature_sensor();
    
    printf("\n🌡️ Simple Raspberry Pi Pico Temperature Monitor\n");
    printf("==============================================\n");
    printf("📊 Features:\n");
    printf("   ✅ Real-time temperature readings\n");
    printf("   ✅ Simple USB serial commands\n");
    printf("   ✅ LED visual feedback\n");
    printf("\n");
    printf("📋 Commands:\n");
    printf("   T - Get current temperature\n");
    printf("   H - Show help\n");
    printf("   S - Show status\n");
    printf("\n");
    printf("🚀 Ready! Type 'T' and press Enter for temperature\n\n");
    
    uint32_t count = 0;
    absolute_time_t last_temp_time = get_absolute_time();
    
    while (true) {
        // Process USB commands
        process_commands();
        
        // Automatic temperature display every 5 seconds
        if (absolute_time_diff_us(last_temp_time, get_absolute_time()) >= 5000000) {
            float temperature = read_onboard_temperature();
            count++;
            
            printf("📊 Auto Reading #%lu: %.2f°C\n", count, temperature);
            
            // Visual feedback with LED
            gpio_put(LED_PIN, 1);
            sleep_ms(100);
            gpio_put(LED_PIN, 0);
            
            last_temp_time = get_absolute_time();
        }
        
        // Small delay to prevent excessive CPU usage
        sleep_us(1000);
    }
    
    return 0;
}