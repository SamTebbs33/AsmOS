
%include "Floppy16.s"

; ebx = buffer address
LoadRootDir:
    mov cx, 14
    mov ax, 13
    xor es, es
    call ReadSectors
    ret
