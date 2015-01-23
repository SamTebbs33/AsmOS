; For loop(start, end). Jumps to .loop each iteration, it is expected that .continue will be jumped to once the iteration is finished.
; The loop will jump to .endLoop once finished
%macro forLoop 2
    mov ecx, %1
    jmp .loop
    .continue:
        inc ecx
        cmp ecx, %2
        je .endLoop
        jmp .loop
%endmacro
