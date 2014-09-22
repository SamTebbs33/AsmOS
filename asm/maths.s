LastRand: db 1
times 3 db 0

InitSeed:
    pusha
    rdtsc
    mov dword [LastRand], eax
    popa
    ret

RandInt:
    push edx
    mov eax, dword [LastRand]   ; Xn = eax
    mov edx, 22694577           ; ebx = a
    mul edx                     ; eax = a * Xn
    mov edx, 1013904223         ; ebx = c
    add eax, edx                ; eax = a * Xn + c
    mov edx, 4294967295         ; ebx = m
    ;div edx (This crashes the system) eax = (a * Xn + c) / m
    pop edx
    mov dword [LastRand], eax
    ret
