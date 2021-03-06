jmp terminal

%include "macros.s"
%include "stdio.s"
%include "memory.s"
%include "string.s"
%include "maths.s"
%include "Files.s"

;MsgWelcome: db 0x0A,  " __  __          ____    _____",0x0A,"|  \/  |        / __ \  / ____|",0x0A,"| \  / | _   _ | |  | || (___  ",0x0A,"| |\/| || | | || |  | | \___ \ ",0x0A,"| |  | || |_| || |__| | ____) |",0x0A,"|_|  |_| \__, | \____/ |_____/ ",0x0A,"          __/ |                ",0x0A,"          |___/",0x0A,0x00
MsgWelcome: db "Sam's OS - v0.1", 0x00
Prompt: db 0x0A, "> ", 0x00
MsgInvalidCom: db "! No command found for: ",0x00
MsgText: db "Text: ",0x00
MsgBkg: db "Background: ",0x00

MsgComDesc: db ": ", 0x00
MsgDumpStart: db "Start: ", 0x00
MsgDumpSpacing1: db "    ", 0x00
MsgDumpSpacing2: db " ", 0x00
MsgDumpSpacing3: db "  ", 0x00

MsgCPUBrand: db "CPU:",0x00
MsgTest: db "aaaabbbb",0x00

MsgF32NotSupported: db "Floppy not supported", 0x00
MsgVerSpacing: db " - ", 0x00
MsgMB: db "MB RAM",0x00
MsgMemMapEntries: db "Memory map entries: ",0x00
MsgMemMapUsedBlocks: db "Used blocks: ", 0x00
MsgMemMapFreeBlocks: db "Free blocks: ", 0x00

ComClear: db "clear", 0x00
    ComClearDesc: db "Clears the screen", 0x00
ComHelp: db "help", 0x00
    ComHelpDesc: db "Prints the help message", 0x00
ComPrint: db "print", 0x00
    ComPrintDesc: db "Prints the argument", 0x00
ComRestart: db "restart", 0x00
    ComRestartDesc: db "Reboot the OS", 0x00
ComVer: db "ver", 0x00
    ComVerDesc: db "Show the OS version", 0x00
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
ComMem: db "mem", 0x00
    ComMemDesc: db "List memory block details", 0x00
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
    call InitSeed
    call PutL
    print MsgWelcome
    call PutL
    mov eax, dword [totalRam]
    mov ebx, 1024
    div ebx
    mov dword [totalRam], eax
    printI eax
    println MsgMB
    call PrintPrompt
    xor ax, ax
    xor bx, bx
    xor dx, dx
    ;call FloppyReset
    jmp InputLoop
    ret

InputLoop:
    call InString
    call PutL
    mov edi, InputBuffer
    cmp byte [edi], 0       ; if no text was entered, jump back
    je near .finishCom
    call StrTrim
    mov bl, ' '
    call StrSplit           ; split command by spaces
    mov edi, SplitStrs      ; move the first split string to edi

    doCommand ComClear, .comClear
    doCommand ComHelp, .comHelp
    doCommand ComPrint, .comPrint
    doCommand ComRestart, .comRestart
    doCommand ComVer, .comVer
    doCommand ComCol, .comCol
    doCommand ComBkg, .comBkg
    doCommand ComDump, .comDump
    doCommand ComScroll, .comScroll
    doCommand ComRand, .comRand
    doCommand ComSys, .comSys
    doCommand ComDir, .comDir
    doCommand ComTest, .comTest
    doCommand ComMem, .comMem

    mov ebx, MsgInvalidCom
    call PutS
    mov ebx, SplitStrs
    call PutS
    jmp .finishCom

.finishCom
    call ClearSplitStrs
    ;mov edi, LastCom
    ;mov esi, InputBuffer
    ;call StrClear           ; clears the previous command
    ;xchg esi, edi
    ;call StrCopy            ; copies the command to the previous command
    mov edi, InputBuffer
    call StrClear           ; clears the command
    mov byte [InputPtr], 1    ; resets the pointer
    call PrintPrompt
    jmp InputLoop

.comClear:
    call ClrScr
    jmp .finishCom

.comHelp:
    doHelp ComClear, ComClearDesc
    doHelp ComHelp, ComHelpDesc
    doHelp ComPrint, ComPrintDesc
    doHelp ComRestart, ComRestartDesc
    doHelp ComVer, ComVerDesc
    doHelp ComCol, ComColDesc
    doHelp ComBkg, ComBkgDesc
    doHelp ComDump, ComDumpDesc
    doHelp ComScroll, ComScrollDesc
    doHelp ComRand, ComRandDesc
    doHelp ComSys, ComSysDesc
    doHelp ComDir, ComDirDesc
    doHelp ComMem, ComMemDesc

    jmp .finishCom

.comPrint:
    checkArgNum 1
    jnc .finishCom
    getArg 1
    print edi
    jmp .finishCom

.comRestart:
    mov        al, 0feh
	out        64h, al

.comVer:
    print MsgWelcome
    jmp .finishCom

.comCol:
    getArgI 1
    mov dl, al
    and dl, 15
    setColourClr dl, byte [ColBkg]
    jmp .finishCom

.comBkg:
    getArgI 1
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
    ; print RAM
    call PutL
    printI dword [totalRam]
    print MsgMB
    popa
    jmp .finishCom

.comDir:
    jmp .finishCom

.comMem:
    mov ecx, dword [bootInfoAddr]
    mov eax, dword [ecx+40]          ; mmap length os 40th byte
    print MsgMemMapEntries
    printlnI eax
    print MsgMemMapFreeBlocks
    call MemGetFreeBlockCount
    printlnI eax
    print MsgMemMapUsedBlocks
    call MemGetUsedBlockCount
    printI eax
    jmp .finishCom

.comTest:
    mov edi, MsgTest
    mov bh, 'e'
    mov bl, 'a'
    call StrReplace
    println MsgTest
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

LastCom: db 0
times 255 db 0
SysInfoBuffer: db 0
times 16 db 0