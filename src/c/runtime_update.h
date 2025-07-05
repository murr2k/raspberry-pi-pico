/**
 * @file runtime_update.h
 * @brief Runtime firmware update system header
 */

#ifndef RUNTIME_UPDATE_H
#define RUNTIME_UPDATE_H

#include "pico/stdlib.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Initialize runtime update system
 */
void runtime_update_init(void);

/**
 * @brief Main runtime update loop (call in main loop)
 */
void runtime_update_loop(void);

/**
 * @brief Force entry into BOOTSEL mode
 */
void runtime_enter_bootsel(void);

/**
 * @brief Reset to BOOTSEL mode using watchdog
 */
void runtime_reset_to_bootsel(void);

/**
 * @brief Perform soft reset
 */
void runtime_soft_reset(void);

/**
 * @brief Get device information
 */
void runtime_get_device_info(void);

/**
 * @brief Prepare for firmware update
 */
void runtime_prepare_update(void);

/**
 * @brief Process runtime update command
 * @param command Command string to process
 */
void runtime_process_command(const char* command);

#ifdef __cplusplus
}
#endif

#endif // RUNTIME_UPDATE_H