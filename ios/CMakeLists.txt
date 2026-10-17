cmake_minimum_required(VERSION 3.20)
project(vlc_modern_ios LANGUAGES OBJCXX CXX)

add_library(VLCModernIOS STATIC
    Runner/AppDelegate.mm
)

target_link_libraries(VLCModernIOS PRIVATE
    vlc_modern_core
    "-framework UIKit"
    "-framework Metal"
    "-framework AVFoundation"
)
