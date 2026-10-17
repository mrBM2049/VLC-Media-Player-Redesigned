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

# Platform-specific linking and RPATH
if(APPLE)
    target_link_directories(vlc_modern_core PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/macos
        /Applications/VLC.app/Contents/MacOS/lib
    )
    target_link_libraries(vlc_modern_core PRIVATE
        "-framework Foundation"
        "-framework Metal"
        "-framework CoreVideo"
        "-framework Cocoa"
        vlc
        vlccore
    )
    set_target_properties(vlc_modern_core PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "@loader_path/../lib/macos;@loader_path;@executable_path/../lib/macos;/Applications/VLC.app/Contents/MacOS/lib"
    )
elseif(WIN32)
    # Direct3D 11 support & libvlc
    target_link_directories(vlc_modern_core PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/lib/windows)
    target_link_libraries(vlc_modern_core PRIVATE d3d11 dxgi)
elseif(ANDROID)
    target_link_directories(vlc_modern_core PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/lib/android)
    target_link_libraries(vlc_modern_core PRIVATE android log)
endif()

# Unit Test Executable
add_executable(native_core_tests
    tests/test_vlc_bridge.cpp
)

target_link_libraries(native_core_tests PRIVATE vlc_modern_core)

if(APPLE)
    set_target_properties(native_core_tests PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "@executable_path/../../native_core;@loader_path;${CMAKE_CURRENT_SOURCE_DIR}/lib/macos;/Applications/VLC.app/Contents/MacOS/lib"
    )
endif()

add_test(NAME native_core_tests COMMAND native_core_tests)
