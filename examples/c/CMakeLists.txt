# CMakeLists.txt for Raspberry Pi Pico examples

cmake_minimum_required(VERSION 3.13)

# Include Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Project name
project(pico_examples C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize Pico SDK
pico_sdk_init()

# Runtime update library
add_library(runtime_update 
    ../../src/c/runtime_update.c
)
target_link_libraries(runtime_update 
    pico_stdlib
    pico_bootrom
    hardware_watchdog
    hardware_resets
    hardware_flash
    pico_unique_id
    pico_stdio_usb
)

# Basic blinky example
add_executable(blinky blink_led.c)
target_link_libraries(blinky 
    pico_stdlib
    hardware_gpio
)
pico_enable_stdio_usb(blinky 1)
pico_enable_stdio_uart(blinky 1)
pico_add_extra_outputs(blinky)

# Enhanced blinky with runtime updates
add_executable(blink_led_enhanced blink_led_enhanced.c)
target_link_libraries(blink_led_enhanced 
    pico_stdlib
    hardware_gpio
    runtime_update
)
pico_enable_stdio_usb(blink_led_enhanced 1)
pico_enable_stdio_uart(blink_led_enhanced 1)
pico_add_extra_outputs(blink_led_enhanced)

# Print build information
message(STATUS "Building Raspberry Pi Pico examples")
message(STATUS "Available targets: blinky, blink_led_enhanced")
message(STATUS "Output files will be generated in build directory")