;********************
; REGISTERS
;********************

REG_DOR: dw 0x3F2
REG_MSR: dw 0x3F4
REG_FIFO: dw 0x3F5
REG_CCR: dw 0x3F7

;********************
; COMMANDS
;********************

CMD_SPECIFY: db 3
CMD_WRITE: db 5
CMD_READ: db 6
CMD_RECALIBRATE: db 7
CMD_SENSE_INT: db 8
CMD_SEEK: db 15

;********************
; DATA
;********************

F32State: db 0
F32DmaLen: dw 0x4800
;.align: 0x8000     Is this needed?
F32DmaBuffer: times 0x4800 db 0
F32_READ_BUFFER: times 7 db 0
F32_MODE_READ: db 1
F32_MODE_WRITE: db 2

MsgPanic: db "Panic!!!",0
MsgLoop: db "loop", 0
MsgReset: db "reset",0
MsgWait: db "waited",0
MsgWrote: db "wrote",0
MsgCalibrate: db "calibrated",0
MsgInCalibrate: db "calibrating",0
MsgMotor: db "motor",0
MsgCheck: db "check",0
ErrorStatus: db "status error!!!",0
ErrorEndOfCyl: db "end of cylinder error!!!",0
ErrorDriveNotReady: db "drive not ready error!!!",0
ErrorCrc: db "CRC error!!!",0
ErrorControllerTimeout: db "controller timeout error!!!",0
ErrorNoData: db "no data error!!!",0
ErrorNoAddressMark: db "no address mark error!!!",0
ErrorDelAddressMark: db "deleted address mark error!!!",0
ErrorCrcData: db "CRC data error!!!",0
ErrorWrongCyl: db "wrong cylinder error!!!",0
ErrorUDPSector: db "UDP sector not found error!!!",0
ErrorBadCyl: db "bad cylinder error!!!",0
ErrorWanted512: db "wanted 512B error!!!",0
ErrorNotWritable: db "not writable error!!!",0
ErrorNoMoreTries: db "no more tries", 0

;********************
; MACROS
;********************
; port = arg1, val = arg2
%macro outPort 2
    mov dx, %1
    mov ax, %2
    out dx, ax
%endmacro

%macro delay 1
    push ecx
    mov ecx, 6135667*%1    ; 10ms * %1 delay
    .delay:
        loop .delay
    pop ecx
%endmacro

%macro wCommand 1
    push ax
    mov ax, %1
    call F32WriteCommand
    pop ax
%endmacro

%macro readData 1
    call F32ReadData
    mov byte [%1], al
%endmacro

%macro readFloppy 0
    xor dx, dx
    mov dl, byte [F32_MODE_READ]
    call F32DoTrack
%endmacro

%macro writeFloppy 0
    xor dx, dx
    mov dl, byte [F32_MODE_WRITE]
    call F32DoTrack
%endmacro

; ax = command, carry = success
F32WriteCommand:
    push ecx
    push eax
    mov cx, 600    ; 600 tries (timeout)
    xor eax, eax
    mov dx, word [REG_MSR]
    .loop:
        push ecx
        delay 1
        pop ecx
        in ax, dx
        test ax, 0x80
        je .success
        loop .loop
        clc
        pop eax
        pop ecx
        ret
    .success:
        stc
        mov dx, word [REG_FIFO]
        pop eax
        out dx, ax
        pop ecx
        ret

; ax = result, carry = success
F32ReadData:
    push ecx
    mov cx, 600    ; 600 tries (timeout)
    mov dx, word [REG_MSR]
    .loop:
        push ecx
        delay 1
        pop ecx
        push eax
        in ax, dx
        test ax, 0x80
        pop eax
        je .success
        loop .loop
        pop ecx
        clc
        ret
    .success:
        stc
        mov dx, word [REG_FIFO]
        in ax, dx
        pop ecx
        ret

; bl = st0, bh = cyl
F32CheckInterrupt:
    push ax
    mov al, byte [CMD_SENSE_INT]
    call F32WriteCommand
    call F32ReadData
    mov bl, al
    call F32ReadData
    mov bh, al
    pop ax
    ret

; bx = resulting cylinder (-1 if failed)
F32Calibrate:
    println MsgInCalibrate
    push ecx
    push eax
    mov bh, -1      ; cyl
    mov ecx, 10     ; 10 tries
    println MsgMotor
    call F32Motor   ; turn motot on
    .loop:
        mov al, byte [CMD_RECALIBRATE]
        call F32WriteCommand
        println MsgWrote
        xor ax, ax                      ; selects drive 0
        call F32WriteCommand
        println MsgWrote
        call F32IRQWait
        println MsgWait
        call F32CheckInterrupt
        println MsgCheck
        test bl, 0xC0
        loope .loop
        cmp bx, 0                       ; found cylinder 0?
        je .done
        loop .loop
        mov bx, -1
        jmp .return                     ; failed
    .done:
        xor bx, bx
    .return:
        pop eax
        pop ecx
        call F32Motor                   ; turn motor off
        println MsgMotor
        ret


F32Reset:
    println MsgReset
    mov dx, word [REG_DOR]
    mov ax, 0;
    out dx, ax                        ; disable controller
    mov ax, 0x0C
    out dx, ax                        ; enable controller
    call F32IRQWait
    println MsgWait
    mov dx, word [REG_CCR]
    mov ax, 0x00
    out dx, ax
    xor ax, ax                        ; set transfer rate
    mov al, byte [CMD_SPECIFY]
    call F32WriteCommand
    println MsgWrote
    mov ax, 0xDF
    call F32WriteCommand
    println MsgWrote
    mov ax, 0x02
    call F32WriteCommand
    println MsgWrote
    call F32Calibrate
    println MsgCalibrate
    ret

; carry = on/off
F32Motor:
    push dx
    push ecx
    jc .on
    ;mov byte [F32_STATE], 2     ; set state to wait
    ;mov word [F32_TICKS], 300   ; These two lines require two threads to be running simultaneoulsy (the floppy_timer() function decrements the ticks and when at 0, kills the motor)
    call F32MotorKill           ; I will just kill the motor outright, however, this may cause timing issues, I need to test and experiment
    jmp .done
    .on:
        cmp byte [F32State], 0
        mov dx, word [REG_DOR]
        mov ax, 0x1C
        out dx, ax           ; turn on
        delay 50
        mov byte [F32State], 1 ; set state to on
    .done:
        pop ecx
        pop dx
        ret

F32MotorKill:
    push dx
    push ax
    mov dx, word [REG_DOR]
    mov ax, 0x0C
    out dx, ax
    mov byte [F32State], 0
    pop ax
    pop dx
    ret

; dx = head, bx = cylinder, carry = success
F32Seek:
    stc
    call F32Motor
    push cx
    xor cx, cx
    mov cl, 10
    push dx
    shl dx, 2
    .loop:
        mov al, byte [CMD_SEEK]
        call F32WriteCommand
        mov ax, dx
        call F32WriteCommand
        mov ax, bx
        call F32WriteCommand
        call F32IRQWait
        call F32CheckInterrupt
        mov al, bh
        cmp bh, al
        je .return
        loop .loop
        jmp .return
    .return:
        clc
        call F32Motor
        pop dx
        pop cx
        ret

; cx = floppy mode (READ or WRITE)
F32DmaInit:
    pusha
    mov bx, word [F32DmaLen]
    dec bx                  ; bx = Buffer length - 1
    mov ax, F32DmaBuffer    ; ax = address of buffer
    push ax
    shr ax, 24
    cmp ax, 0
    pop ax
    jg near .panic               ; checking if address of buffer is greater than 24 bits
    push bx
    shr bx, 16
    cmp bx, 0
    pop bx
    jg near .panic               ; checking that length is at most 16 bits
    push bx
    push ax
    and ax, 0xFFFF
    add ax, cx
    shr ax, 16
    cmp ax, 0
    pop ax
    pop bx
    jg .panic              ; check if length + address doesn't cause a carry
    outPort 0x0a, 0x06
    outPort 0x0c, 0xff
    outPort 0x04, 0         ; Shouldn't these values not be 0? Check floppy_dma_init in floppy.c
    outPort 0x04, 0
    outPort 0x81, 0
    outPort 0x0c, 0xff
    outPort 0x05, 0
    outPort 0x05, 0
    outPort 0x0b, cx
    outPort 0x0a, 0x02
    jmp .return
    .panic:
        println MsgPanic
    .return:
        popa
        ret

; ax = command, bx = cylinder, dx = mode (READ, WRITE)
F32DoTrack:
    pusha
    or ax, 0xC0
    mov dx, 0
    call F32Seek        ; test seek for head 0
    jnc near .failed
    mov dx, 1
    call F32Seek        ; test seek for head 1
    jnc near .failed
    xor ecx, ecx        ; counter
    .loop:
        stc
        call F32Motor   ; set motor on
        push cx
        mov cx, dx
        call F32DmaInit ; init for floppy mode
        delay 10
        wCommand ax
        wCommand 0      ; 0:0:0:0:0:HD:US1:US0 = head and drive 
        wCommand bx     ; cylinder
        wCommand 0      ; head 0
        wCommand 1      ; first sector
        wCommand 2      ; 128*2 = 512 bytes per sector
        wCommand 18     ; tracks to operate on
        wCommand 0x1b   ; GAP3 length, 27 is default for 3.5 inch floppy
        wCommand 0xff   ; data length
        call F32IRQWait
        ; read status flags
        readData F32_READ_BUFFER    ; st0
        readData F32_READ_BUFFER+1  ; st1
        readData F32_READ_BUFFER+2  ; st2
        readData F32_READ_BUFFER+3  ; rcy (cylinder)
        readData F32_READ_BUFFER+4  ; rhe (head)
        readData F32_READ_BUFFER+5  ; rse (sector)
        readData F32_READ_BUFFER+6  ; bps (bytes per sector), should be waht we programmed in earlier
        test byte [F32_READ_BUFFER], 0xC0
        je near .statusError
        test byte [F32_READ_BUFFER+1], 0x80
        je near .endOfCyl
        test byte [F32_READ_BUFFER], 0x08
        je near .driveNotReady
        test byte [F32_READ_BUFFER+1], 0x20
        je near .crcError
        test byte [F32_READ_BUFFER+1], 0x10
        je near .controllerTimeout
        test byte [F32_READ_BUFFER+1], 0x04
        je near .noDataFound
        xor ax, ax
        mov al, byte [F32_READ_BUFFER+1]
        or al, byte [F32_READ_BUFFER+2]
        test ax, 0x01
        je near .noAddressMark
        test byte [F32_READ_BUFFER+2], 0x40
        je near .deletedAddressMark
        test byte [F32_READ_BUFFER+2], 0x20
        je near .crcErrorInData
        test byte [F32_READ_BUFFER+2], 0x10
        je near .wrongCylinder
        test byte [F32_READ_BUFFER+2], 0x04
        je near .upd765SectorNotFound
        test byte [F32_READ_BUFFER+2], 0x02
        je near .badCylinder
        cmp byte [F32_READ_BUFFER+6], 2
        jne near .wanted512PerSector
        test byte [F32_READ_BUFFER+1], 0x02
        je near .notWritable
        jmp .return                         ; success!
        .statusError:
            println ErrorStatus
            jmp near .error1
        .endOfCyl:
            println ErrorEndOfCyl
            jmp near .error1
        .driveNotReady:
            println ErrorDriveNotReady
            jmp near .error1
        .crcError:
            println ErrorCrc
            jmp near .error1
        .controllerTimeout
            println ErrorControllerTimeout
            jmp near .error1
        .noDataFound:
            println ErrorNoData
            jmp near .error1
        .noAddressMark:
            println ErrorNoAddressMark
            jmp near .error1
        .deletedAddressMark:
            println ErrorDelAddressMark
            jmp near .error1
        .badCylinder:
            println ErrorBadCyl
            jmp near .error1
        .crcErrorInData:
            println ErrorCrcData
            jmp near .error1
        .wrongCylinder:
            println ErrorWrongCyl
            jmp near .error1
        .upd765SectorNotFound:
            println ErrorUDPSector
            jmp near .error1
        .wanted512PerSector:
            println ErrorWanted512
            jmp near .error1
        .notWritable:
            println ErrorNotWritable
            jmp .return
        .error1:
            cmp cx, 20
            inc cx
            jl near .loop
            println ErrorNoMoreTries
        .return:
            popa
            clc
            call F32Motor
            ret
        .failed:
            popa
            ret

F32IRQWait:
    cmp byte [floppyIRQ], 1
    je .done
    jmp F32IRQWait
    .done:
        mov byte [floppyIRQ], 0
        ret



