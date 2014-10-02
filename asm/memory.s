; Sources
;   * http://brokenthorn.com/Resources/OSDev17.html

%define MEM_BLOCK_SIZE 4096    ; 4KB allocation block size
%define MEM_BLOCKS_PER_BYTE 8   ; how many blocks we can keep track of in one byte
%define MEM_BLOCK_ALIGN MEM_BLOCK_SIZE
memRamSize: dd 0
memUsedBlocks: dd 0
memMaxBlocks: dd 0
memMap: dd 0

; counter, initialization, loop until, loop function, end loop function
; in the loop function, jump to .contLoop to iterate the loop again
%macro for 4
    mov %1, %2
    .doLoop:
        cmp ecx, %3
        jl %4
        jmp %5
    .contLoop:
        inc %1
        jmp .doLoop
%endmacro

%macro setBit 1
    push ecx
    push ebx
    mov cl, %1
    mov ebx, 1
    shl ebx, cl
    mov ecx, dword [memMap]
    or dword [ecx], ebx
    pop ebx
    pop ecx
%endmacro

%macro unsetBit 1
    push ecx
    push ebx
    mov cl, %1
    mov ebx, 1
    shl ebx, cl
    not ebx
    mov ecx, dword [memMap]
    and dword [ecx], ebx
    pop ebx
    pop ecx
%endmacro

; carry = is set
%macro testBit 1
    push ebx
    push ecx
    mov ebx, 1
    mov cl, %1
    shl ebx, cl
    push eax
    mov ecx, dword [memMap]
    mov eax, dword [ecx]
    and eax, ebx
    cmp eax, ebx
    pop eax
    clc
    jne .return
    stc
    .return:
        pop ecx
        pop ebx

%endmacro

; start, value, length
%macro memSet 3
    cld
    xor esi, esi
    mov edi, %1
    mov cx, %3
    mov al, %2
    repne stosb
%endmacro

; al = bit to set
MemSet:
    setBit al
    ret

; al = bit to set
MemUnset:
    unsetBit al
    ret

; al = bit to test, carry = is set
MemTest:
    testBit al
    ret

; ebx = ram size, eax = address of memory allocation bitmap
MemInit:
    mov dword [memRamSize], ebx
    mov dword [memMap], eax
    mov ebx, 1024
    mul ebx
    mov ebx, MEM_BLOCK_SIZE
    div ebx
    mov dword [memMaxBlocks], eax
    mov dword [memUsedBlocks], 0          ; all memory is set as occupied since we don't now which areas are occupied in the memmap yet
    mov ebx, MEM_BLOCKS_PER_BYTE
    div ebx
    memSet dword [memMap], 0x0, ax
    ret

; ecx = base, eax = size
MemForceFreeBlocks:
    push edx
    mov edx, MEM_BLOCK_SIZE
    div edx
    xchg eax, ecx
    div edx         ; ecx = blocks, eax = align
    cld
    .loop:
        inc eax
        call MemUnset
        dec dword [memUsedBlocks]
        loop .loop
    setBit 0
    pop edx
    ret

; ecx = base, eax = size
MemForceAllocBlocks:
    push edx
    mov edx, MEM_BLOCK_SIZE
    div edx
    xchg eax, ecx
    div edx         ; ecx = blocks, eax = align
    cld
    .loop:
        inc eax
        call MemSet
        inc dword [memUsedBlocks]
        loop .loop
    pop edx
    ret

; eax = allocated memory location, -1 if no memory
MemAllocBlock:
    call MemGetFreeBlockCount
    cmp eax, 0
    jle .noMem
    call MemFirstFree
    cmp eax, -1
    je .noMem
    call MemSet
    push ebx
    mov ebx, MEM_BLOCK_SIZE
    mul ebx
    pop ebx
    inc dword [memUsedBlocks]
    ret
    .noMem:
        mov eax, -1
        ret

; eax = memory location to free
MemFreeBlock:
    mov ebx, MEM_BLOCK_SIZE
    div ebx
    call MemUnset
    dec dword [memUsedBlocks]
    ret

MemGetFreeBlockCount:
    mov eax, dword [memMaxBlocks]
    sub eax, dword [memUsedBlocks]
    ret

MemGetUsedBlockCount:
    mov eax, dword [memUsedBlocks]
    ret

; eax = first free block
MemFirstFree:
    push ecx
    push esi
    push edx
    push ebx
    push edi
    mov edx, 32
    mov eax, dword [memMaxBlocks]
    mov edi, dword [memMap]         ; edi = address of mem alloc bitmap
    div edx                         ; eax = memBlocks / 32
    xor edx, edx                    ; edx = i
    .loop:
        mov esi, dword [edi+edx]
        cmp esi, 0xFFFFFFFF    ; if all bits in integer are set
        xor edx, ecx                                  ; ecx = j
        .loop2:
            mov ebx, 1
            shl ebx, cl
            push esi
            and esi, ebx
            cmp ebx, esi
            je .endLoop2
            mov ebx, 4
            mov eax, edx
            mul ebx
            mov ebx, 8
            mul ebx
            add eax, ecx
            jmp .return
        .endLoop2:
            inc ecx
            cmp ecx, 32
            jg .endLoop
            jmp .loop2
    .endLoop:
        inc edx
        cmp edx, eax
        jle .loop
        mov eax, -1
    .return:
        pop edi
        pop ebx
        pop edx
        pop esi
        pop ecx
        ret