#include <windows.h>

CONSOLE_SCREEN_BUFFER_INFO x;

main () {

    printf("addr dwsize: %p\n",             &x.dwSize);
    printf("addr dwcursorposition: %p\n",   &x.dwCursorPosition);
    printf("addr wattrbutes: %p\n",         &x.wAttributes);
    printf("addr srwindow: %p\n",           &x.srWindow);
    printf("addr dwmaximumwindowsize: %p\n", &x.dwMaximumWindowSize);

}
