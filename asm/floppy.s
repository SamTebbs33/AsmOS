; Floppy driver

%define FLOPPY_DOR 0x3F2
%define FLOPPY_MSR 0x3F4
%define FLOPPY_FIFO 0x3F5
%define FLOPPY_CTRL 0x3F7

%define FLOPPY_MASK_DRIVE0 0
%define FLOPPY_MASK_DRIVE1 1
%define FLOPPY_MASK_DRIVE2 2
%define FLOPPY_MASK_DRIVE3 3
%define FLOPPY_MASK_RESET 4
%define FLOPPY_MASK_DMA 8
%define FLOPPY_MASK_DRIVE0_MOTOR 16
%define FLOPPY_MASK_DRIVE1_MOTOR 32
%define FLOPPY_MASK_DRIVE2_MOTOR 64
%define FLOPPY_MASK_DRIVE3_MOTOR 128

%define FLOPPY_MSR_MASK_DRIVE1_POS_MODE 1
%define FLOPPY_MSR_MASK_DRIVE2_POS_MODE 2
%define FLOPPY_MSR_MASK_DRIVE3_POS_MODE 4
%define FLOPPY_MSR_MASK_DRIVE4_POS_MODE 8
%define FLOPPY_MSR_MASK_BUSY 16
%define FLOPPY_MSR_MASK_DMA 32
%define FLOPPY_MSR_MASK_DATAIO 64
%define FLOPPY_MSR_MASK_DATAREG 128

%define FLOPPY_CMD_READ_TRACK 2
%define FLOPPY_CMD_SPECIFY 3
%define FLOPPY_CMD_CHECK_STAT 4
%define FLOPPY_CMD_WRITE_SECT 5
%define FLOPPY_CMD_READ_SECT 6
%define FLOPPY_CMD_CALIBRATE 7
%define FLOPPY_CMD_CHECK_INT 8
%define FLOPPY_CMD_WRITE_DEL_S 9
%define FLOPPY_CMD_READ_ID_S 10
%define FLOPPY_CMD_READ_DEL_S 12
%define FLOPPY_CMD_FORMAT 13
%define FLOPPY_CMD_SEEK 15

%define FLOPPY_CMD_EXT_SKIP 32
%define FLOPPY_CMD_EXT_DENSITY 64
%define FLOPPY_CMD_EXT_MULTITRACK 128

%define FLOPPY_GP3_LENGTH_STD 42
%define FLOPPY_GP3_LENGTH_5_14 32
%define FLOPPY_GP3_LENGTH_3_5 27

; bytes per sector
%define FLOPPY_SECTOR_DTL_128 0
%define FLOPPY_SECTOR_DTL_256 1
%define FLOPPY_SECTOR_DTL_512 2
%define FLOPPY_SECTOR_DTL_1024 4
%define FLOPPY_SECTORS_PER_TRACK 18

currentDrive: db 0

%macro outP 2
    mov ax, %2
    mov dx, %1
    out dx, ax
%endmacro

%macro inP 1
    mov dx, %1
    in ax, dx
%endmacro

%macro delay 1
    push ecx
    mov ecx, 6135667*%1    ; 10ms * %1 delay
    .delay:
        loop .delay
    pop ecx
%endmacro

FloppyDMAInit:
	outP 0x0A, 0x06	; mask dma channel 2
	outP 0xD8, 0xFF	; reset master flip-flop
	;mov eax, DMABuffer
	;and eax, 0xFF	; ax = lower byte of address
	outP 0x04, 0
	;mov eax, DMABuffer
	;shr eax, 8	; shift address by a bytes to get upper byte
	outP 0x04, 0x10
	outP 0xD8, 0xFF	; reset master flip-flop
	outP 0x05, 0xFF	; count to 0x23FF (number of bytes on a floppy)
	outP 0x05, 0x23
	outP 0x08, 0	; external page register = 0
	outP 0x0A, 0x02	; unmask DMA
	ret

; Prepare for DMA read
FloppyDMARead:
	outP 0x0A, 0x06	; mask DMA channel 2
	outP 0x0B, 0x56	; single transfe, address increment, autoinit, read, channel 2
	outP 0x0A, 0x02	; unmask DMA channel 2
	ret

; Prepare for DMA write
FloppyDMAWrite:
	outP 0x0A, 0x06	; mask DMA channel 2
	outP 0x0B, 0x5A	; single transfe, address increment, autoinit, read, channel 2
	outP 0x0A, 0x02	; unmask DMA channel 2
	ret
	
; al = value
FloppyWriteDOR:
	outP FLOPPY_DOR, ax
	ret

; carry = is busy
FloppyIsBusy:
	push ax
	inP FLOPPY_MSR
	and ax, FLOPPY_MSR_MASK_BUSY
	cmp ax, 0
	jne .busy
	clc
	jmp .return
	.busy:
		stc
	.return:
		pop ax
		ret

; ax = status
FloppyReadStatus:
	inP FLOPPY_MSR
	ret

FloppyCheckDataReg:
	push ax
	call FloppyReadStatus
	and ax, FLOPPY_MSR_MASK_DATAREG
	cmp ax, 0
	jne .not
	clc
	jmp .return
	.not:
		stc
	.return:
		pop ax
		ret
	
; ax = command
FloppySendCommand:
	push cx
	mov cx, 0	; 500 tries
	.loop:
		call FloppyCheckDataReg
		jnc .endLoop
		outP FLOPPY_FIFO, ax
		pop cx
		ret
	.endLoop:
		inc cx
		cmp cx, 500
		jne .loop
		pop cx
		ret

; ax = data, or -1 if not successful
FloppyReadData:
	mov ax, -1
	push cx
	mov cl, 0	; 500 tries
	.loop:
		call FloppyCheckDataReg
		jnc .endLoop
		inP FLOPPY_FIFO
		pop cx
		ret
	.endLoop:
		inc cx
		cmp cx, 500
		jne .loop
		pop cx
		ret

; al = value
FloppyWriteCCR:
	outP FLOPPY_CTRL, ax
	ret

; cl = track, ch = head, bl = sector
FloppyReadSector:
    call FloppyDMARead  ; init DMA fro read operation
    mov ax, FLOPPY_CMD_READ_SECT | FLOPPY_CMD_EXT_MULTITRACK | FLOPPY_CMD_EXT_SKIP | FLOPPY_CMD_EXT_DENSITY
    call FloppySendCommand
    xor ax, ax
    push cx
    shl ch, 2
    or ch, byte [currentDrive]
    mov al, cl
    call FloppySendCommand
    pop cx
    mov al, ch
    call FloppySendCommand
    mov al, bl
    call FloppySendCommand
    mov al, FLOPPY_SECTOR_DTL_512
    call FloppySendCommand
    inc bl
    cmp bl, FLOPPY_SECTORS_PER_TRACK    ; sector >= sectors per track ? sectors per track : sector++
    jge .cont
    mov bl, FLOPPY_SECTORS_PER_TRACK
    .cont:
        mov al, bl
    call FloppySendCommand
    mov al, FLOPPY_GP3_LENGTH_3_5
    call FloppySendCommand
    mov al, 0xFF
    call FloppySendCommand
    call FLoppyIRQWait
    mov cl, 0
    .loop:
        call FloppyReadData
        cmp cl, 7
        je .end
        inc cl
        jmp .loop
    .end:
        call FLoppyCheckInt

; eax = stepr, ebx = loadt, ecx = unloadt, dl = dma
FloppySendDriveData:
    xor ax, ax
    mov al, FLOPPY_CMD_SPECIFY
    call FloppySendCommand
    and eax, 0xF
    shl eax, 4
    and ecx, 0xF
    or eax, ecx              ;((stepr & 0xf) << 4) | (unloadt & 0xf)
    call FloppySendCommand
    shl ebx, 1
    or bl, dl                ;(loadt) << 1 | (dma==true) ? 1 : 0
    mov eax, ebx
    call FloppySendCommand
    ret

; eax = drive, ebx = error code
FloppyCalibrate:
    cmp eax, 4        ; ensure drive number is not greater than 3
    jl .do
    mov ebx, -2
    ret
    .do:
        stc
        call FloppyMotor
        mov cl, 0
        .loop:
            push eax
            xor eax, eax
            mov al, FLOPPY_CMD_CALIBRATE
            call FloppySendCommand
            pop eax
            call FloppySendCommand
            call FLoppyIRQWait
            call FLoppyCheckInt
            cmp ebx, 0
            je .done
            cmp cl, 10
            je .failure
            inc cl
            jmp .loop
        .failure:
            mov bl, -1
            jmp .return
        .done:
            mov bl, 0
        .return:
            clc
            call FloppyMotor
            ret

; ebx = result
FLoppyCheckInt:
    mov eax, FLOPPY_CMD_CHECK_INT
    call FloppySendCommand
    call FloppyReadData
    call FloppyReadData     ; read data twice
    mov ebx, eax
    ret

; cl = cylinder, ch = head, ebx = error code
FloppySeek:
    cmp byte [currentDrive], 4        ; ensure drive number is not greater than 3
    jl .do
    mov ebx, -1
    ret
    .do:
        mov dl, 0
        xor eax, eax
    .loop:
        mov al, FLOPPY_CMD_SEEK
        call FloppySendCommand
        shl ch, 2
        or ch, byte [currentDrive]
        mov al, ch
        call FloppySendCommand
        mov al, cl
        call FloppySendCommand
        call FLoppyIRQWait
        call FLoppyCheckInt
        cmp bl, cl          ; cyl == result
        je .done
        cmp dl, 10
        je .failure
        inc cl
        jmp .loop
    .done:
        mov ebx, 0
        jmp .return
    .failure:
        mov ebx, -1
    .return:
        ret

FloppyDisableController:
    xor eax, eax
    call FloppyWriteDOR
    ret

FloppyEnableController:
    mov eax, FLOPPY_MASK_RESET | FLOPPY_MASK_DMA
    call FloppyWriteDOR
    ret

MsgReset: db "Reset", 0x00
MsgIRQWait: db "IRQ Wait",0x00
MsgCheckInt: db "Cehck int",0x00
MsgWriteCCR: db "Write CCR", 0x00
MsgDriveData: db "Drive data", 0x00
MsgCalibrate: db "Calibrate", 0x00
FloppyReset:
    println MsgReset
    call FloppyDisableController
    call FloppyEnableController
    println MsgIRQWait
    call FLoppyIRQWait
    println MsgCheckInt
    call FLoppyCheckInt
    call FLoppyCheckInt
    call FLoppyCheckInt
    call FLoppyCheckInt     ; do 4 times
    xor eax, eax
    println MsgWriteCCR
    call FloppyWriteCCR     ; set data rate to 500kb/s
    ; eax = stepr, ebx = loadt, ecx = unloadt, dl = dma
    mov eax, 3
    mov ebx, 16
    mov ecx, 240
    mov edx, 1
    println MsgDriveData
    call FloppySendDriveData
    xor eax, eax
    mov al, byte [currentDrive]
    println MsgCalibrate
    call FloppyCalibrate
    ;call FloppyDMAInit
    ret

MsgLoop: db "loop", 0x00
FLoppyIRQWait:
    .loop:
        println MsgLoop
        cmp byte [floppyIRQ], 1
        jne .loop
        mov byte [floppyIRQ], 0
        ret

; carry = on/off
FloppyMotor:
    jc .on
    outP FLOPPY_DOR, FLOPPY_MASK_RESET
    jmp .return
    .on:
        outP FLOPPY_DOR, FLOPPY_MASK_DRIVE0_MOTOR | FLOPPY_MASK_RESET
        delay 5
    .return:
        ret




