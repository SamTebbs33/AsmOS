%include "floppy.s"

; ebx = buffer address
LoadRootDir:
    mov cx, 14
    mov ax, 13
    xor esi, esi
    ;call ReadSectors
    ret
