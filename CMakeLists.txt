# CMake configuration for Raspberry Pi Pico projects
cmake_minimum_required(VERSION 3.13)

# Include Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Project configuration
project(raspberry-pi-pico C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize Pico SDK
pico_sdk_init()

# Add subdirectories for different projects
# Uncomment as you add projects to src/c/

# Example: Basic blink project
# add_subdirectory(src/c/blink)

# Example: ADC temperature reading
# add_subdirectory(src/c/temperature)

# Example: UART communication
# add_subdirectory(src/c/uart_echo)

# Example: I2C sensor interface
# add_subdirectory(src/c/i2c_sensor)

# Example: PWM servo control
# add_subdirectory(src/c/servo_control)

# Add example projects
# add_subdirectory(examples/c/hello_world)
# add_subdirectory(examples/c/blink_led)
# add_subdirectory(examples/c/button_input)

# Global compiler flags for all targets
add_compile_options(-Wall -Werror -Wextra)

# Optional: Add debugging symbols
set(CMAKE_BUILD_TYPE Debug)

# Print configuration summary
message(STATUS "")
message(STATUS "Raspberry Pi Pico Project Configuration:")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Standard: ${CMAKE_C_STANDARD}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Pico SDK Path: $ENV{PICO_SDK_PATH}")
message(STATUS "")