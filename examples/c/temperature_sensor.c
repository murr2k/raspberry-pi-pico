/**
 * @file temperature_sensor.c
 * @brief Internal temperature sensor reading example for Raspberry Pi Pico
 * 
 * This example demonstrates:
 * - ADC (Analog-to-Digital Converter) initialization
 * - Reading from the internal temperature sensor
 * - Converting raw ADC values to temperature
 * - Serial output for monitoring
 * 
 * Hardware requirements:
 * - Raspberry Pi Pico board only (uses internal temperature sensor)
 * 
 * @author Raspberry Pi Pico Development Project
 * @date 2025
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

/**
 * @brief Read the internal temperature sensor
 * 
 * @return float Temperature in Celsius
 */
float read_onboard_temperature() {
    // Select temperature sensor ADC input
    adc_select_input(TEMPERATURE_SENSOR_CHANNEL);
    
    // Read raw ADC value
    uint16_t adc_raw = adc_read();
    
    // Convert to voltage
    float voltage = (float)adc_raw * VOLTAGE_REFERENCE / ADC_RESOLUTION;
    
    // Convert voltage to temperature using RP2040 formula
    // Temperature = 27 - (voltage - 0.706) / 0.001721
    float temperature = 27.0f - (voltage - TEMP_SENSOR_VOLTAGE_27C) / TEMP_SENSOR_SLOPE;
    
    return temperature;
}

/**
 * @brief Initialize ADC for temperature reading
 */
void init_temperature_sensor() {
    // Initialize ADC
    adc_init();
    
    // Enable temperature sensor
    adc_set_temp_sensor_enabled(true);
    
    // Set ADC clock divider for stable readings
    adc_set_clkdiv(48000);  // Slow down ADC clock for better accuracy
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
    
    printf("Raspberry Pi Pico Internal Temperature Sensor\n");
    printf("============================================\n");
    printf("Reading temperature every 2 seconds...\n\n");
    
    uint32_t reading_count = 0;
    float temperature_sum = 0.0f;
    float min_temp = 1000.0f;
    float max_temp = -1000.0f;
    
    while (true) {
        // Read temperature
        float temperature = read_onboard_temperature();
        
        // Update statistics
        reading_count++;
        temperature_sum += temperature;
        if (temperature < min_temp) min_temp = temperature;
        if (temperature > max_temp) max_temp = temperature;
        
        // Calculate average
        float avg_temp = temperature_sum / reading_count;
        
        // Display current reading
        printf("Reading #%lu:\n", reading_count);
        printf("  Current: %.2f°C\n", temperature);
        printf("  Average: %.2f°C\n", avg_temp);
        printf("  Min: %.2f°C, Max: %.2f°C\n", min_temp, max_temp);
        printf("-------------------\n");
        
        // Visual feedback with LED
        gpio_put(LED_PIN, 1);
        sleep_ms(100);
        gpio_put(LED_PIN, 0);
        
        // Wait before next reading
        sleep_ms(1900);  // Total 2 second interval
    }
    
    return 0;
}