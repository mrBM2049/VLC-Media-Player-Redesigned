cmake_minimum_required(VERSION 3.20)
project(vlc_modern_android LANGUAGES CXX C)

add_library(vlc_modern_jni SHARED
    app/src/main/cpp/native-lib.cpp
)

target_link_libraries(vlc_modern_jni PRIVATE
    vlc_modern_core
    android
    log
)

