/**
 * @file temperature_enhanced.c
 * @brief Enhanced temperature sensor with runtime updates and interactive commands
 * 
 * This example demonstrates:
 * - Internal temperature sensor reading with statistics
 * - Runtime update system for zero-friction development
 * - Interactive USB serial commands for temperature monitoring
 * - Real-time temperature reporting and control
 * 
 * Hardware requirements:
 * - Raspberry Pi Pico board only (uses internal temperature sensor)
 * 
 * Temperature reports shown via:
 * - USB serial output (make monitor)
 * - Interactive commands (STATUS, TEMP, etc.)
 * - Real-time continuous monitoring
 * 
 * @author Raspberry Pi Pico Development Project  
 * @date 2025
 */

#include "pico/stdlib.h"
#include "hardware/adc.h"
#include "hardware/gpio.h"
#include "../../src/c/runtime_update.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Temperature sensor configuration
#define TEMPERATURE_SENSOR_CHANNEL 4    // ADC channel for internal temp sensor
#define ADC_RESOLUTION 4096            // 12-bit ADC (2^12)
#define VOLTAGE_REFERENCE 3.3f         // Reference voltage
#define TEMP_SENSOR_VOLTAGE_27C 0.706f // Voltage at 27°C
#define TEMP_SENSOR_SLOPE 0.001721f    // V/°C slope

// LED pin for visual feedback
#define LED_PIN 25

// Temperature monitoring settings
#define DEFAULT_REPORT_INTERVAL_MS 2000
#define TEMP_HISTORY_SIZE 10

// Application state
static bool temp_monitoring_enabled = true;
static uint32_t report_interval_ms = DEFAULT_REPORT_INTERVAL_MS;
static absolute_time_t last_report_time;
static uint32_t reading_count = 0;
static float temperature_sum = 0.0f;
static float min_temp = 1000.0f;
static float max_temp = -1000.0f;
static float temp_history[TEMP_HISTORY_SIZE];
static uint8_t history_index = 0;

// Enhanced commands
#define CMD_TEMP        "TEMP"
#define CMD_STATS       "STATS"
#define CMD_HISTORY     "HISTORY"
#define CMD_INTERVAL    "INTERVAL"
#define CMD_START_TEMP  "START_TEMP"
#define CMD_STOP_TEMP   "STOP_TEMP"
#define CMD_RESET_STATS "RESET_STATS"

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
 * @brief Add temperature reading to history
 */
void add_temperature_to_history(float temp) {
    temp_history[history_index] = temp;
    history_index = (history_index + 1) % TEMP_HISTORY_SIZE;
}

/**
 * @brief Display temperature statistics
 */
void display_temperature_stats() {
    if (reading_count == 0) {
        printf("📊 No temperature readings yet\n");
        return;
    }
    
    float avg_temp = temperature_sum / reading_count;
    
    printf("📊 Temperature Statistics:\n");
    printf("   📈 Readings: %lu\n", reading_count);
    printf("   🌡️ Current: %.2f°C\n", temp_history[(history_index - 1 + TEMP_HISTORY_SIZE) % TEMP_HISTORY_SIZE]);
    printf("   📊 Average: %.2f°C\n", avg_temp);
    printf("   🔥 Maximum: %.2f°C\n", max_temp);
    printf("   🧊 Minimum: %.2f°C\n", min_temp);
    printf("   ⏱️ Interval: %lu ms\n", report_interval_ms);
    printf("   ▶️ Monitoring: %s\n", temp_monitoring_enabled ? "ENABLED" : "DISABLED");
}

/**
 * @brief Display temperature history
 */
void display_temperature_history() {
    printf("📈 Temperature History (last %d readings):\n", TEMP_HISTORY_SIZE);
    for (int i = 0; i < TEMP_HISTORY_SIZE; i++) {
        int idx = (history_index - TEMP_HISTORY_SIZE + i + TEMP_HISTORY_SIZE) % TEMP_HISTORY_SIZE;
        if (reading_count > i) {
            printf("   [%2d] %.2f°C\n", i + 1, temp_history[idx]);
        }
    }
}

/**
 * @brief Process temperature-specific commands
 */
void process_temperature_commands(const char* command) {
    if (strncmp(command, CMD_TEMP, 4) == 0) {
        float current_temp = read_onboard_temperature();
        printf("🌡️ Current Temperature: %.2f°C\n", current_temp);
        
    } else if (strncmp(command, CMD_STATS, 5) == 0) {
        display_temperature_stats();
        
    } else if (strncmp(command, CMD_HISTORY, 7) == 0) {
        display_temperature_history();
        
    } else if (strncmp(command, CMD_START_TEMP, 10) == 0) {
        temp_monitoring_enabled = true;
        printf("▶️ Temperature monitoring ENABLED\n");
        
    } else if (strncmp(command, CMD_STOP_TEMP, 9) == 0) {
        temp_monitoring_enabled = false;
        printf("⏹️ Temperature monitoring DISABLED\n");
        
    } else if (strncmp(command, CMD_RESET_STATS, 11) == 0) {
        reading_count = 0;
        temperature_sum = 0.0f;
        min_temp = 1000.0f;
        max_temp = -1000.0f;
        history_index = 0;
        printf("🔄 Temperature statistics RESET\n");
        
    } else if (strncmp(command, CMD_INTERVAL, 8) == 0) {
        // Parse interval value if provided
        if (strlen(command) > 9) {
            uint32_t new_interval = atoi(command + 9);
            if (new_interval >= 500 && new_interval <= 60000) {
                report_interval_ms = new_interval;
                printf("⏱️ Report interval set to %lu ms\n", report_interval_ms);
            } else {
                printf("❌ Invalid interval. Use 500-60000 ms\n");
            }
        } else {
            printf("⏱️ Current interval: %lu ms\n", report_interval_ms);
            printf("💡 Usage: INTERVAL <milliseconds>\n");
        }
        
    } else if (strncmp(command, "HELP", 4) == 0) {
        printf("📋 Enhanced Temperature Sensor Commands:\n");
        printf("   🌡️ Temperature Commands:\n");
        printf("     TEMP        - Read current temperature\n");
        printf("     STATS       - Show temperature statistics\n");
        printf("     HISTORY     - Show temperature history\n");
        printf("     START_TEMP  - Enable monitoring\n");
        printf("     STOP_TEMP   - Disable monitoring\n");
        printf("     RESET_STATS - Reset all statistics\n");
        printf("     INTERVAL <ms> - Set report interval (500-60000)\n");
        printf("   \n");
        printf("   🔄 Runtime Updates:\n");
        printf("     BOOTSEL     - Enter bootloader mode\n");
        printf("     RESET       - Soft reset system\n");
        printf("     INFO        - Show device info\n");
        printf("     PREPARE     - Prepare for update\n");
        printf("   \n");
        printf("   📊 Temperature Reports:\n");
        printf("     - Automatic reports every %lu ms\n", report_interval_ms);
        printf("     - USB serial output via make monitor\n");
        printf("     - Interactive commands available\n");
        
    } else {
        // Try runtime update commands
        runtime_process_command(command);
    }
}

/**
 * @brief Enhanced command processing with temperature commands
 */
void enhanced_temperature_command_loop(void) {
    static char command_buffer[64];
    static int buffer_pos = 0;
    
    int c = getchar_timeout_us(0);
    if (c != PICO_ERROR_TIMEOUT) {
        if (c == '\n' || c == '\r') {
            if (buffer_pos > 0) {
                command_buffer[buffer_pos] = '\0';
                process_temperature_commands(command_buffer);
                buffer_pos = 0;
            }
        } else if (buffer_pos < sizeof(command_buffer) - 1) {
            command_buffer[buffer_pos++] = c;
        }
    }
}

/**
 * @brief Update temperature monitoring and reporting
 */
void update_temperature_monitoring(void) {
    if (!temp_monitoring_enabled) {
        return;
    }
    
    if (absolute_time_diff_us(last_report_time, get_absolute_time()) >= (report_interval_ms * 1000)) {
        // Read temperature
        float temperature = read_onboard_temperature();
        
        // Update statistics
        reading_count++;
        temperature_sum += temperature;
        if (temperature < min_temp) min_temp = temperature;
        if (temperature > max_temp) max_temp = temperature;
        
        // Add to history
        add_temperature_to_history(temperature);
        
        // Calculate average
        float avg_temp = temperature_sum / reading_count;
        
        // Display current reading with enhanced formatting
        printf("\n🌡️ Temperature Reading #%lu:\n", reading_count);
        printf("   📊 Current: %.2f°C\n", temperature);
        printf("   📈 Average: %.2f°C\n", avg_temp);
        printf("   🔥 Max: %.2f°C  🧊 Min: %.2f°C\n", max_temp, min_temp);
        printf("   ⏱️ Next report in %lu ms\n", report_interval_ms);
        printf("   💡 Type 'HELP' for commands\n");
        printf("───────────────────────────────\n");
        
        // Visual feedback with LED
        gpio_put(LED_PIN, 1);
        sleep_ms(100);
        gpio_put(LED_PIN, 0);
        
        last_report_time = get_absolute_time();
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
    
    // Initialize runtime update system
    runtime_update_init();
    
    // Initialize timing
    last_report_time = get_absolute_time();
    
    // Print startup information
    printf("\n🌡️ Enhanced Raspberry Pi Pico Temperature Sensor\n");
    printf("===============================================\n");
    printf("📊 Features:\n");
    printf("   ✅ Real-time temperature monitoring\n");
    printf("   ✅ Interactive USB serial commands\n");
    printf("   ✅ Temperature statistics and history\n");
    printf("   ✅ Runtime firmware updates (no BOOTSEL!)\n");
    printf("   ✅ Configurable report intervals\n");
    printf("\n");
    printf("🔧 Configuration:\n");
    printf("   LED Pin: GP%d\n", LED_PIN);
    printf("   Report Interval: %lu ms\n", report_interval_ms);
    printf("   Runtime Updates: ENABLED\n");
    printf("\n");
    printf("📋 WHERE TO SEE TEMPERATURE REPORTS:\n");
    printf("   🖥️ USB Serial Output: make monitor\n");
    printf("   📱 Interactive Commands: TEMP, STATS, HISTORY\n");
    printf("   ⏱️ Automatic Reports: Every %lu ms\n", report_interval_ms);
    printf("   🔄 Real-time Updates: Via USB commands\n");
    printf("\n");
    printf("💡 Type 'HELP' for available commands\n");
    printf("🚀 Ready for temperature monitoring!\n\n");
    
    // Main loop - handle temperature monitoring and commands
    while (true) {
        // Update temperature monitoring and reporting
        update_temperature_monitoring();
        
        // Process USB serial commands
        enhanced_temperature_command_loop();
        
        // Small delay to prevent excessive CPU usage
        sleep_us(100);
    }
    
    return 0;
}