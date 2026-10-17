cmake_minimum_required(VERSION 3.20)
project(vlc_modern_macos LANGUAGES CXX OBJCXX)

add_executable(VLCModernApp
    Runner/main.mm
)

target_link_libraries(VLCModernApp PRIVATE
    vlc_modern_core
    "-framework Cocoa"
    "-framework Metal"
    "-framework MetalKit"
    "-framework CoreVideo"
)
