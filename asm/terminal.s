jmp terminal

%include "stdio.s"
%include "string.s"
%include "maths.s"
%include "Files.s"

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

MsgF32NotSupported: db "Floppy not supported", 0x00

ComClear: db "clear", 0x00
    ComClearDesc: db "Clears the screen", 0x00
ComHelp: db "help", 0x00
    ComHelpDesc: db "Prints the help message", 0x00
ComEcho: db "echo", 0x00
    ComEchoDesc: db "Prints the argument", 0x00
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
    ComDumpDesc: db "Prints next 256 ram locations after the argument", 0x00
ComScroll: db "scroll", 0x00
    ComScrollDesc: db "Scrolls the screen downwards", 0x00
ComRand: db "rand", 0x00
    ComRandDesc: db "Prints a random number", 0x00
ComSys: db "sys", 0x00
    ComSysDesc: db "Prints information about the system", 0x00
ComDir: db "ls", 0x00
    ComDirDesc: db "List the contents of the current directory", 0x00
ComTest: db "test", 0x00
    ComTestDesc: db "Does some test related shizzle", 0x00

;**************************************************;
; Macros
;**************************************************;

; doCommand(commandStr, function)
%macro doCommand 2
    mov esi, %1
    call StrCmp
    jc near %2
%endmacro

; doHelp(comName, comDesc)
%macro doHelp 2
    mov esi, %1
    mov edi, %2
    call .printComHelp
    call PutL
%endmacro

%macro getArgI 1
    getArg %1
    call StrToInt
%endmacro

%macro getArg 1
    mov eax, %1
    call GetArg
%endmacro

%macro checkArgNum 1
    mov al, %1
    call CheckArgNum
%endmacro

;**************************************************;
; Main program
;**************************************************;

terminal:
    setColourClr [COLOUR_WHITE], [COLOUR_LBLUE]
    call InitSeed
    call F32Init
    jc .continue
    println MsgF32NotSupported
    .continue:
    print MsgWelcome
    println MsgVersion
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
    mov bl, ' '
    call StrSplit           ; split command by spaces
    mov edi, SplitStrs      ; move the first split string to edi

    doCommand ComClear, .comClear
    doCommand ComHelp, .comHelp
    doCommand ComEcho, .comEcho
    doCommand ComRestart, .comRestart
    doCommand ComVer, .comVer
    doCommand ComColours, .comColours
    doCommand ComCol, .comCol
    doCommand ComBkg, .comBkg
    doCommand ComDump, .comDump
    doCommand ComScroll, .comScroll
    doCommand ComRand, .comRand
    doCommand ComSys, .comSys
    doCommand ComDir, .comDir
    doCommand ComTest, .comTest

    mov ebx, MsgInvalidCom
    call PutS
    mov ebx, SplitStrs
    call PutS
    jmp .finishCom

.finishCom
    call ClearSplitStrs
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
    doHelp ComClear, ComClearDesc
    doHelp ComHelp, ComHelpDesc
    doHelp ComEcho, ComEchoDesc
    doHelp ComRestart, ComRestartDesc
    doHelp ComVer, ComVerDesc
    doHelp ComColours, ComColoursDesc
    doHelp ComCol, ComColDesc
    doHelp ComBkg, ComBkgDesc
    doHelp ComDump, ComDumpDesc
    doHelp ComScroll, ComScrollDesc
    doHelp ComRand, ComRandDesc
    doHelp ComSys, ComSysDesc
    doHelp ComDir, ComDirDesc

    jmp .finishCom

.comEcho:
    checkArgNum 1
    jnc .finishCom
    getArg 1
    print edi
    jmp .finishCom

.comRestart:
    mov        al, 0feh
	out        64h, al

.comVer:
    print MsgVersion
    jmp .finishCom

.comColours:
    xor eax, eax
    print MsgText
    printlnH byte [ColChar]
    print MsgBkg
    printH byte [ColBkg]
    jmp .finishCom

.comCol:
    mov dl, byte [ColChar]
    inc dl
    and dl, 15
    setColourClr dl, byte [ColBkg]
    jmp .finishCom

.comBkg:
    mov al, byte [ColBkg]
    inc al
    and al, 15
    setColourClr byte [ColChar], al
    jmp .finishCom

.comDump:
    getArgI 1
    xor edx, edx
    print MsgDumpStart
    printlnI eax                ; print start address
    xor ecx, ecx                ; cl = horisontal address, ch = vertical address
    push eax
    xor eax, eax
    print MsgDumpSpacing1
    .loop1:                     ; loop to print the horisontal hex addresses
        print MsgHex
        call PutHexDigit
        print MsgDumpSpacing2
        inc al
        cmp al, 16
        jl .loop1
        pop eax
    .loop2:                     ; vertical loop
        call PutL
        xor cl, cl              ; resets the x position
        push eax
        mov al, ch
        call PutHex
        add ch, 16
        pop eax
        print MsgDumpSpacing2
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
            print MsgDumpSpacing3
            jmp .loop3
        .loop3Done
            cmp ch, 0           ; if the y position has overflown (255 + 1 = 0), finish the command
            je .finish
            jmp .loop2
    .finish:
        jmp .finishCom

.comScroll:
    getArgI 1
    .loop:
        call Scroll
        cmp eax, 0
        je .finishCom
        dec eax
        jmp .loop

.comRand:
    call RandInt
    call PutI
    jmp .finishCom

.comSys:
    pusha
    mov eax, 0x0
    xor ecx, ecx
    xor edx, edx
    print MsgCPUBrand
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

.comDir:
    mov ebx, RootDirBuffer
    call LoadRootDir
    jmp .finishCom

.comTest:
    jmp .finishCom

.printComHelp:
    print esi
    print MsgComDesc
    print edi
    ret

PrintCPUId:
    mov dword [SysInfoBuffer], eax
    mov dword [SysInfoBuffer+4], ebx
    mov dword [SysInfoBuffer+8], ecx
    mov dword [SysInfoBuffer+12], edx
    print SysInfoBuffer
    ret

PrintPrompt:
    pusha
    print Prompt
    popa
    ret

; eax = arg number (max 127)
; returns edi = argument
GetArg:
    push ebx
    push ecx
    push edx
    cmp byte [SplitStrsLen+eax], 0
    je .return
    xor ebx, ebx                    ; sum
    xor ecx, ecx                    ; counter
    xor edx, edx
    .loop:
        mov dl, byte [SplitStrsLen+ecx]
        add ebx, edx
        inc ecx
        cmp ecx, eax
        jl .loop
    .done:
        mov ecx, SplitStrs
        add ecx, eax
        add ecx, ebx
        mov edi, ecx
    .return:
        pop edx
        pop ecx
        pop ebx
        ret

; al = number of args
; carry = number of args found
CheckArgNum:
    clc
    cmp byte [SplitStrsNum], al
    jne .done
    stc
    .done:
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
SysInfoBuffer: db 0
times 16 db 0
ArgAddr: db 0
times 3 db 0
RootDirBuffer: times 7168 db 0      ; root dir is 14 secctos * 512 bytes long
FileBuffer: times 1025 db 0