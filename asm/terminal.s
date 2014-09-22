jmp terminal

%include "stdio.s"
%include "string.s"
%include "maths.s"

MsgWelcome: db 0x0A,"Sam's OS ",0x00
MsgVersion: db "v0.1",0x00
Prompt: db 0x0A, "> ", 0x00
MsgInvalidCom: db "! No command found for: ",0x00
MsgText: db "Text: ",0x00
MsgBkg: db "Background: ",0x00
MsgShift: db 0x0A, "Shift!",0x0A,0x00

MsgComDesc: db ": ", 0x00
MsgDumpStart: db "Start: ", 0x00
MsgDumpSpacing1: db "    ", 0x00
MsgDumpSpacing2: db " ", 0x00
MsgDumpSpacing3: db "  ", 0x00

MsgCPUBrand: db "CPU ID:",0x00

ComClear: db "clear", 0x00
    ComClearDesc: db "Clears the screen", 0x00
ComHelp: db "help", 0x00
    ComHelpDesc: db "Prints the help message", 0x00
ComEcho: db "echo", 0x00
    ComEchoDesc: db "Prints the last command used", 0x00
ComRestart: db "restart", 0x00
    ComRestartDesc: db "Reboot the OS", 0x00
ComVer: db "ver", 0x00
    ComVerDesc: db "Show the OS version", 0x00
ComColours: db "colours", 0x00
    ComColoursDesc: db "Show the current colour cofiguration", 0x00
ComCol: db "col", 0x00
    ComColDesc: db "Cycle through the text colours", 0x00
ComBkg: db "bkg", 0x00
    ComBkgDesc: db "Cycle through the background colours", 0x00
ComDump: db "dump", 0x00
    ComDumpDesc: db "Prints next 255 ram locations from mem pointer, then increments it", 0x00
ComReset: db "reset", 0x00
    ComResetDesc: db "Resets the mem pointer", 0x00
ComScroll: db "scroll", 0x00
    ComScrollDesc: db "Scrolls the screen downwards", 0x00
ComRand: db "rand", 0x00
    ComRandDesc: db "Prints a random number", 0x00
ComSys: db "sys", 0x00
    ComSysDesc: db "Prints information about the system", 0x00

terminal:
    call InitSeed
    mov	dl, [COLOUR_WHITE]
	mov	al, [COLOUR_LBLUE]
	call	SetColour
	call	ClrScr
    mov ebx, MsgWelcome
    call PutS
    mov ebx, MsgVersion
    call PutS
    call PutL
    mov eax, dword [0xB02]
    call PutI
    call PutL
    call PrintPrompt
    xor ax, ax
    xor bx, bx
    xor dx, dx
    jmp InputLoop
    ret

InputLoop:
    call WaitKey
    cmp bl, byte [KEY_ENTER]
    je near .enter
    cmp bl, byte [KEY_BACK]
    je .backspace
    cmp bl, byte [KEY_LSHIFT]
    je .shift
    cmp bl, byte [KEY_ALT]
    je .alt
    cmp byte [ComPtr], 254  ; make sure the pointer is not greater than the max string length
    je InputLoop
    call KeyToAscii
    cmp bl, 0
    je InputLoop            ; if a valid ascii key was not entered, jump out
    xor edx, edx            ; clear edx
    mov dl, byte [ComPtr]   ; move the current buffer pointer to dl
    dec dl                  ; decrease the pointer by one
    mov [ComBuffer+edx], bl ; move the character to the new address (buffer + pointer)
    inc byte [ComPtr]       ; increment the pointer
    call PutCh
    jmp InputLoop

.shift:
    mov byte [KeyOffset], 42; key code offset
    jmp InputLoop

.alt:
    mov byte [KeyOffset], 84
    jmp InputLoop

.backspace:
    mov bl, byte [ComPtr]   ; move the pointer to bl
    cmp bl, 1
    je InputLoop            ; if the pointer is 1, there is not text to remove so jump out
    dec byte [ComPtr]       ; decrement the pointer
    call BackSpace          ; call stdio.Backspace
    mov esi, ComBuffer
    mov bl, 0
    call StrSetLast         ; removes the last character of the buffer
    jmp InputLoop

.enter:
    call PutL
    mov edi, ComBuffer
    cmp byte [edi], 0       ; if no text was entered, jump back
    je near .finishCom
    call StrTrim
    call StrLower           ; removes all trailing spaces and coverts the command to lowercase
                            ; so that even commands in uppercase are recognised
    mov esi, ComClear
    call StrCmp
    jc near .comClear

    mov esi, ComHelp
    call StrCmp
    jc near .comHelp

    mov esi, ComEcho
    call StrCmp
    jc near .comEcho

    mov esi, ComRestart
    call StrCmp
    jc near .comRestart

    mov esi, ComVer
    call StrCmp
    jc near .comVer

    mov esi, ComColours
    call StrCmp
    jc near .comColours

    mov esi, ComCol
    call StrCmp
    jc near .comCol

    mov esi, ComBkg
    call StrCmp
    jc near .comBkg

    mov esi, ComDump
    call StrCmp
    jc near .comDump

    mov esi, ComReset
    call StrCmp
    jc near .comReset

    mov esi, ComScroll
    call StrCmp
    jc near .comScroll

    mov esi, ComRand
    call StrCmp
    jc near .comRand

    mov esi, ComSys
    call StrCmp
    jc near .comSys

    mov ebx, MsgInvalidCom
    call PutS
    mov ebx, ComBuffer
    call PutS
    jmp .finishCom

.finishCom
    mov edi, LastCom
    mov esi, ComBuffer
    call StrClear           ; clears the previous command
    xchg esi, edi
    call StrCopy            ; copies the command to the previous command
    mov edi, ComBuffer
    call StrClear           ; clears the command
    mov byte [ComPtr], 1    ; resets the pointer
    call PrintPrompt
    jmp InputLoop

.comClear:
    call ClrScr
    jmp .finishCom

.comHelp:
    mov esi, ComClear
    mov edi, ComClearDesc
    call .printComHelp

    call PutL

    mov esi, ComHelp
    mov edi, ComHelpDesc
    call .printComHelp

    call PutL

    mov esi, ComEcho
    mov edi, ComEchoDesc
    call .printComHelp

    call PutL

    mov esi, ComRestart
    mov edi, ComRestartDesc
    call .printComHelp

    call PutL

    mov esi, ComVer
    mov edi, ComVerDesc
    call .printComHelp

    call PutL

    mov esi, ComColours
    mov edi, ComColoursDesc
    call .printComHelp

    call PutL

    mov esi, ComCol
    mov edi, ComColDesc
    call .printComHelp

    call PutL

    mov esi, ComBkg
    mov edi, ComBkgDesc
    call .printComHelp

    call PutL

    mov esi, ComDump
    mov edi, ComDumpDesc
    call .printComHelp

    call PutL

    mov esi, ComReset
    mov edi, ComResetDesc
    call .printComHelp

    call PutL

    mov esi, ComScroll
    mov edi, ComScrollDesc
    call .printComHelp

    call PutL

    mov esi, ComRand
    mov edi, ComRandDesc
    call .printComHelp

    call PutL

    mov esi, ComSys
    mov edi, ComSysDesc
    call .printComHelp

    jmp .finishCom

.comEcho:
    mov ebx, LastCom
    call PutS
    jmp .finishCom

.comRestart:
    mov        al, 0feh
	out        64h, al

.comVer:
    mov ebx, MsgVersion
    call PutS
    jmp .finishCom

.comColours:
    xor eax, eax
    mov ebx, MsgText
    call PutS
    mov al, byte [ColChar]
    call PutHex
    call PutL
    mov ebx, MsgBkg
    call PutS
    mov al, byte [ColBkg]
    call PutHex
    jmp .finishCom

.comCol:
    mov dl, byte [ColChar]
    inc dl
    and dl, 15
    mov al, byte [ColBkg]
    call SetColour
    call ClrScr
    jmp .finishCom

.comBkg:
    mov al, byte [ColBkg]
    inc al
    and al, 15
    mov dl, byte [ColChar]
    call SetColour
    call ClrScr
    jmp .finishCom

.comDump:
    xor eax, eax
    xor edx, edx
    mov al, byte [MemPtr]      ; al = start address / 16
    mov cl, 225
    mul cl                     ; ax = start address
    mov ebx, MsgDumpStart
    call PutS
    call PutI                  ; print start address
    call PutL
    xor ecx, ecx                ; cl = horisontal address, ch = vertical address
    push ax
    xor ax, ax
    mov ebx, MsgDumpSpacing1
    call PutS
    .loop1:                     ; loop to print the horisontal hex addresses
        mov ebx, MsgHex
        call PutS
        call PutHexDigit
        mov ebx, MsgDumpSpacing2
        call PutS
        inc al
        cmp al, 16
        jl .loop1
        pop ax
    .loop2:                     ; vertical loop
        call PutL
        xor cl, cl              ; resets the x position
        push ax
        mov al, ch
        call PutHex
        add ch, 16
        pop ax
        mov ebx, MsgDumpSpacing2
        call PutS
        .loop3:                 ; horisontal loop
            mov dl, byte [eax]
            push eax
            mov al, dl
            shr al, 4           ; prints the first hex digit (most significant bits)
            call PutHexDigit
            mov al, dl
            and al, 15          ; prints the last hex digit (least significant bits)
            call PutHexDigit
            pop eax
            inc eax
            inc cl              ; increase the address and the x position
            cmp cl, 16
            je .loop3Done       ; if we are at the end of the horistontal address, end the horisontal loop
            mov ebx, MsgDumpSpacing3
            call PutS
            jmp .loop3
        .loop3Done
            cmp ch, 0           ; if the y position has overflown (255 + 1 = 0), finish the command
            je .finish
            jmp .loop2
    .finish:
        inc byte [MemPtr]       ; increment the mem pointer
        jmp .finishCom

.comReset:
    mov byte [MemPtr], 0
    jmp .finishCom

.comScroll:
    call Scroll
    jmp .finishCom

.comRand:
    call RandInt
    call PutI
    jmp .finishCom

.comSys:
    pusha
    mov eax, 0x0
    xor ecx, ecx
    xor edx, edx
    mov ebx, MsgCPUBrand
    call PutS
    xor ebx, ebx
    ; print brand string
    mov eax, 80000002h
    cpuid
    call PrintCPUId
    mov eax, 80000003h
    cpuid
    call PrintCPUId
    mov eax, 80000004h
    cpuid
    call PrintCPUId
    popa
    jmp .finishCom

.printComHelp:
    mov ebx, esi
    call PutS
    mov ebx, MsgComDesc
    call PutS
    mov ebx, edi
    call PutS
    ret

PrintCPUId:
    mov dword [SysInfoBuffer], eax
    mov dword [SysInfoBuffer+4], ebx
    mov dword [SysInfoBuffer+8], ecx
    mov dword [SysInfoBuffer+12], edx
    mov ebx, SysInfoBuffer
    call PutS
    ret

PrintPrompt:
    pusha
    mov ebx, Prompt
    call PutS
    popa
    ret

; eax = 1 if supported
CpuIdSupported:
    pushfd ; get
    pop eax
    mov ecx, eax ; save
    xor eax, 0x200000 ; flip
    push eax ; set
    popfd
    pushfd ; and test
    pop eax
    xor eax, ecx ; mask changed bits
    shr eax, 21 ; move bit 21 to bit 0
    and eax, 1 ; and mask others
    push ecx
    popfd ; restore original flags
    ret

ComBuffer: db 0
times 255 db 0
LastCom: db 0
times 255 db 0
ComPtr: db 1
MemPtr: db 0
SysInfoBuffer: db 0
times 16 db 0