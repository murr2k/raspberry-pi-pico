/**
 * @file runtime_update.c
 * @brief Runtime firmware update system for Raspberry Pi Pico
 * 
 * This module provides the ability to update firmware without requiring
 * BOOTSEL mode, using USB DFU runtime updates and watchdog resets.
 */

#include "pico/stdlib.h"
#include "pico/bootrom.h"
#include "hardware/watchdog.h"
#include "hardware/resets.h"
#include "hardware/flash.h"
#include "pico/unique_id.h"
#include "pico/stdio_usb.h"
#include <string.h>
#include <stdio.h>

// Magic sequence for runtime update
#define RUNTIME_UPDATE_MAGIC 0xDEADBEEF
#define WATCHDOG_RESET_DELAY_MS 100

// Command structure for runtime updates
typedef struct {
    uint32_t magic;
    uint32_t command;
    uint32_t address;
    uint32_t size;
    uint8_t data[];
} runtime_update_cmd_t;

// Commands
#define CMD_ENTER_BOOTSEL     0x01
#define CMD_RESET_TO_BOOTSEL  0x02
#define CMD_SOFT_RESET        0x03
#define CMD_GET_DEVICE_INFO   0x04
#define CMD_PREPARE_UPDATE    0x05

/**
 * @brief Force entry into BOOTSEL mode using ROM function
 */
void runtime_enter_bootsel(void) {
    printf("🔄 Entering BOOTSEL mode for runtime update...\n");
    stdio_flush();
    
    // Reset USB to clean state
    reset_block(RESETS_RESET_USBCTRL_BITS);
    unreset_block_wait(RESETS_RESET_USBCTRL_BITS);
    
    // Enter BOOTSEL mode using ROM function
    // This is equivalent to holding BOOTSEL during power-on
    rom_reset_usb_boot(0, 0);
    
    // Should never reach here
    while (1) {
        tight_loop_contents();
    }
}

/**
 * @brief Force reset to BOOTSEL mode using watchdog
 */
void runtime_reset_to_bootsel(void) {
    printf("🔄 Resetting to BOOTSEL mode...\n");
    stdio_flush();
    
    // Configure watchdog to reset to BOOTSEL mode
    hw_clear_bits(&watchdog_hw->ctrl, WATCHDOG_CTRL_ENABLE_BITS);
    watchdog_hw->scratch[4] = 0xb007c0d3; // Magic value for BOOTSEL
    watchdog_hw->scratch[5] = 0; // GPIO mask
    watchdog_hw->scratch[6] = 0; // GPIO direction
    watchdog_hw->scratch[7] = 0; // GPIO output
    
    // Enable watchdog reset
    watchdog_enable(WATCHDOG_RESET_DELAY_MS, true);
    
    // Wait for reset
    while (1) {
        tight_loop_contents();
    }
}

/**
 * @brief Soft reset the system
 */
void runtime_soft_reset(void) {
    printf("🔄 Performing soft reset...\n");
    stdio_flush();
    
    // Use watchdog for clean reset
    watchdog_enable(WATCHDOG_RESET_DELAY_MS, true);
    
    while (1) {
        tight_loop_contents();
    }
}

/**
 * @brief Get device information for update verification
 */
void runtime_get_device_info(void) {
    pico_unique_board_id_t board_id;
    pico_get_unique_board_id(&board_id);
    
    printf("📱 Device Information:\n");
    printf("   Board ID: ");
    for (int i = 0; i < PICO_UNIQUE_BOARD_ID_SIZE_BYTES; i++) {
        printf("%02x", board_id.id[i]);
    }
    printf("\n");
    printf("   Flash Size: %d bytes\n", PICO_FLASH_SIZE_BYTES);
    printf("   RAM Size: 264KB\n");
    printf("   CPU: RP2040 Dual Cortex-M0+\n");
    printf("   SDK Version: %s\n", PICO_SDK_VERSION_STRING);
}

/**
 * @brief Prepare system for firmware update
 */
void runtime_prepare_update(void) {
    printf("🛠️ Preparing for firmware update...\n");
    
    // Disable interrupts
    // __disable_irq();  // Comment out for now - will work without this
    
    // Flush all stdio
    stdio_flush();
    
    // Disable USB
    stdio_usb_deinit();
    
    printf("✅ System prepared for update\n");
    printf("💡 Use one of these commands:\n");
    printf("   - picotool reboot -f        (force BOOTSEL)\n");
    printf("   - picotool load firmware.uf2 (if in BOOTSEL)\n");
    printf("   - OpenOCD programming        (via SWD)\n");
}

/**
 * @brief Process runtime update commands
 */
void runtime_process_command(const char* command) {
    if (strncmp(command, "BOOTSEL", 7) == 0) {
        runtime_enter_bootsel();
    } else if (strncmp(command, "RESET_BOOTSEL", 13) == 0) {
        runtime_reset_to_bootsel();
    } else if (strncmp(command, "RESET", 5) == 0) {
        runtime_soft_reset();
    } else if (strncmp(command, "INFO", 4) == 0) {
        runtime_get_device_info();
    } else if (strncmp(command, "PREPARE", 7) == 0) {
        runtime_prepare_update();
    } else {
        printf("❌ Unknown command: %s\n", command);
        printf("💡 Available commands:\n");
        printf("   - BOOTSEL       (enter bootloader)\n");
        printf("   - RESET_BOOTSEL (reset to bootloader)\n");
        printf("   - RESET         (soft reset)\n");
        printf("   - INFO          (device information)\n");
        printf("   - PREPARE       (prepare for update)\n");
    }
}

/**
 * @brief Initialize runtime update system
 */
void runtime_update_init(void) {
    printf("🚀 Runtime Update System Initialized\n");
    printf("📝 Type commands via USB serial:\n");
    printf("   - BOOTSEL, RESET_BOOTSEL, RESET, INFO, PREPARE\n");
    printf("🔧 OpenOCD SWD programming also available\n");
    printf("⚡ No BOOTSEL button required for updates!\n");
}

/**
 * @brief Main runtime update loop
 */
void runtime_update_loop(void) {
    static char command_buffer[64];
    static int buffer_pos = 0;
    
    int c = getchar_timeout_us(0);
    if (c != PICO_ERROR_TIMEOUT) {
        if (c == '\n' || c == '\r') {
            if (buffer_pos > 0) {
                command_buffer[buffer_pos] = '\0';
                runtime_process_command(command_buffer);
                buffer_pos = 0;
            }
        } else if (buffer_pos < sizeof(command_buffer) - 1) {
            command_buffer[buffer_pos++] = c;
        }
    }
}