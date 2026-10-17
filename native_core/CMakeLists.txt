cmake_minimum_required(VERSION 3.20)
project(vlc_modern_core VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Public include directory
include_directories(include)

# Main Native Shared Library
add_library(vlc_modern_core SHARED
    src/vlc_bridge.cpp
)

target_compile_definitions(vlc_modern_core PRIVATE VLC_BRIDGE_BUILD_SHARED)

target_include_directories(vlc_modern_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Platform-specific frameworks and flags
if(APPLE)
    target_link_libraries(vlc_modern_core PRIVATE
        "-framework Foundation"
        "-framework Metal"
        "-framework CoreVideo"
    )
elseif(WIN32)
    # Direct3D 11 support
    target_link_libraries(vlc_modern_core PRIVATE d3d11 dxgi)
elseif(ANDROID)
    target_link_libraries(vlc_modern_core PRIVATE android log)
endif()

# Unit Test Executable
enable_testing()
add_executable(native_core_tests
    tests/test_vlc_bridge.cpp
)

target_link_libraries(native_core_tests PRIVATE vlc_modern_core)
add_test(NAME native_core_tests COMMAND native_core_tests)
