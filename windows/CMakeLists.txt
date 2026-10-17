cmake_minimum_required(VERSION 3.20)
project(vlc_modern_windows LANGUAGES CXX)

add_executable(VLCModernApp WIN32
    runner/main.cpp
)

target_link_libraries(VLCModernApp PRIVATE
    vlc_modern_core
    d3d11
    dxgi
)

