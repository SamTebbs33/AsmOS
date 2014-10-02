KEYS_CODES: db 48, 46, 32, 33, 34, 35, 36, 37, 38, 50, 49, 47, 45, 44, 31, 30, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 51, 52, 53, 86, 41, 43, 0
KEYS_ASCII: db 'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'v', 'x', 'z', 's', 'a', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '+', ',', '.', '-', '<', 0
KEYS_SHIFT: db 'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'V', 'X', 'Z', 'S', 'A', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '!', '"', '#', 0, '%', '&', '/', '(', ')', '=', '?', ';', ':', '_', '>', '*', 0
KEYS_ALT: db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '@', 0, '$', 0, 0, 92, '[', ']', 0, 0, 0, 0, 0, 0, 0, 0
; 42 key codes in each array above

KEY_ENTER: db 28
KEY_BACK: db 14
KEY_RSHIFT: db 54
KEY_LSHIFT: db 42
KEY_TAB: db 15
KEY_ALT: db 56
KEY_CMD: db 92
KEY_LEFT: db 75
KEY_UP: db 72
KEY_DOWN: db 80
KEY_RIGHT: db 77
; Fn must also be held down for these
KEY_F1: db 16
KEY_F2: db 17
KEY_F3: db 18
KEY_F4: db 19
KEY_F5: db 20
KEY_F6: db 21
KEY_F7: db 22
KEY_F8: db 23
KEY_F9: db 24
KEY_F10: db 25
KEY_F11: db 26
KEY_F12: db 27