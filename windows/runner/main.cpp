#if defined(_WIN32)
#include <windows.h>
#include "vlc_bridge.h"

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    vlc_bridge_init();
    // Native Direct3D 11 / WinUI / Flutter / Avalonia host window entry
    vlc_bridge_destroy();
    return 0;
}
#else
int main() {
    return 0;
}
#endif
