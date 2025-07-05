# CMakeLists.txt for blinky example

cmake_minimum_required(VERSION 3.13)

# Include Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# Project name
project(blinky C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Initialize Pico SDK
pico_sdk_init()

# Create executable
add_executable(blinky blink_led.c)

# Link libraries
target_link_libraries(blinky 
    pico_stdlib
    hardware_gpio
)

# Enable USB output
pico_enable_stdio_usb(blinky 1)
pico_enable_stdio_uart(blinky 1)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(blinky)

# Print build information
message(STATUS "Building blinky example for Raspberry Pi Pico")
message(STATUS "Output files will be generated in build directory")