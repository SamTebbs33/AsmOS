KEYS_CODES: db 48, 46, 32, 33, 34, 35, 36, 37, 38, 50, 49, 47, 45, 44, 31, 30, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 51, 52, 53, 86, 41, 43, 0
KEYS_ASCII: db 'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'v', 'x', 'z', 's', 'a', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '+', ',', '.', '-', '<', 0
KEYS_SHIFT: db 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'V', 'X', 'Z', 'S', 'A', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '!', '"', '#', 0, '%', '&', '/', '(', ')', '=', '?', ';', ':', '_', '>', '*', 0
KEYS_ALT: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '@', 0, '$', 0, 0, 92, '[', ']', 0, 0, 0, 0, 0, 0, 0, 0
; 42 key codes in each array above

%define KEY_ENTER  28
%define KEY_BACK  14
%define KEY_RSHIFT  54
%define KEY_LSHIFT  42
%define KEY_TAB  15
%define KEY_ALT  56
%define KEY_CMD  92
%define KEY_LEFT  75
%define KEY_UP  72
%define KEY_DOWN  80
%define KEY_RIGHT  77
; Fn must also be held down for these
%define KEY_F1  16
%define KEY_F2  17
%define KEY_F3  18
%define KEY_F4  19
%define KEY_F5  20
%define KEY_F6  21
%define KEY_F7  22
%define KEY_F8  23
%define KEY_F9  24
%define KEY_F10  25
%define KEY_F11  26
%define KEY_F12  27