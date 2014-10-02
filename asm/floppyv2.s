
; Sources
; * http://wiki.osdev.org/Floppy_Disk_Controller
; * http://wiki.osdev.org/ATA_PIO_Mode#Hardware

; Using PIO data transfer
;   * init/reset controller if needed
;   * select drive if needed
;   * seek to cylinder
;   * issue sense interrupt command
;   * issue read/write command
;   * poll RQM bit in Main Status Register to determine when controller wants data moved in/out of FIFO buffer
;   * read result bytes to see if errors occured

REG_STATUS_A: dw 0x3F0         ; read only
REG_STATUS_B: dw 0x3F1         ; read only
REG_DIGITAL_OUT: dw 0x3F2      ; controls floppy drive motors, drive selection and resets
REG_TAPE_DRIVE: dw 0x3F3
REG_STATUS_MAIN: dw 0x3F4      ; read only, contain the "busy" flags that must be checked before reading/writing through FIFO
REG_DATARATE_SELECT: dw 0x3F4 ; write only
REG_FIFO: dw 0x3F5             ; all commands, parameter info, result codes and disk data transfers go through this
REG_DIGITAL_IN: dw 0x3F7      ; read only
REG_CONFIG_CONTROL: dw 0x3F7   ; write only

READ_TRACK: db 2	; generates IRQ6
SPECIFY: db 3      ; * set drive parameters
SENSE_DRIVE_STATUS: db 4
WRITE_DATA: db 5      ; * write to the disk
READ_DATA: db 6      ; * read from the disk
RECALIBRATE: db 7      ; * seek to cylinder 0
SENSE_INTERRUPT: db 8      ; * ack IRQ6, get status of last command
WRITE_DELETED_DATA: db 9
READ_ID: db 10	; generates IRQ6
READ_DELETED_DATA: db 12
FORMAT_TRACK: db 13     ; *
SEEK: db 15     ; * seek both heads to cylinder X
VERSION: db 16	; * used during initialization, once
SCAN_dbAL: db 17
PERPENDICULAR_MODE: db 18	; * used during initialization, once, maybe
CONFIGURE: db 19     ; * set controller parameters
LOCKF: db 20     ; * protect controller params from a reset
VERIFY: db 22
SCAN_LOW_OR_dbAL: db 25
SCAN_HIGH_OR_dbAL: db 29

MsgS1: db "S1",0x00
MsgS2: db "S2",0x00
MsgS3: db ".reset",0x00

MOTOR_SPIN_DELAY: db 300		; suggested motor spin delay (ms), test with 50ms
FifoBuffer: db 0				; buffer used when issuing commands

; DOR flags
; Mnemonic	 bit number	 value	 meaning/usage
; MOTD          7        0x80	 Set to turn drive 3's motor ON
; MOTC          6		0x40	 Set to turn drive 2's motor ON
; MOTB          5		0x20	 Set to turn drive 1's motor ON
; MOTA          4		0x10	 Set to turn drive 0's motor ON
; IRQ           3		8		Set to enable IRQs and DMA
; RESET         2		4		Clear = enter reset mode, Set = normal operation
; DSEL1 and 0	0, 1	3		"Select" drive number for next access

; to executer a command that accesses a disk, the disk's motor must be spinning up to speed and have its "select" bits set in DOR first
; toggling DOR reset state takes a 4us delay. May be better to use DSR reset mode instead as hardware untoggles reset mode after delay

; MSR flags
; Mnemonic	 bit number	 value	 meaning/usage
; RQM			7		0x80	 Set if it's OK (or mandatory) to exchange bytes with the FIFO IO port
; DIO			6		0x40	 Set if FIFO IO port expects an IN opcode
; NDMA			5		0x20	 Set in Execution phase of PIO mode read/write commands only. Signals end of execution phase
; CB			4		0x10	 Command Busy: set when command byte received, cleared at end of Result phase
; ACTD			3		8		Drive 3 is seeking
; ACTC			2		4		Drive 2 is seeking
; ACTB			1		2		Drive 1 is seeking
; ACTA			0		1		Drive 0 is seeking

; bottom 2 bits of DSR match CCR and specify the data transfer rate. 0 = 1.44M drive (500Kbps, 3 = 2.88M drive (1Mbps)
; reset procedure does not affect this register

; DIR register
; bit 7 (value = 0x80) is set if the floppy door is opnened/closed.
; the drive motor bit must be on before accessing the DIR register.It may also be necessary to read the register five times (discard the first 4 values) when changing the selected drive -- because "selecting" sometimes takes a little time.

; command, parameter, has execution phase
%macro f32Command 3
	pusha
	mov cl, %3
	mov bl, byte [%1]
	mov bh, %2
	call F32Command
	popa
%endmacro

%macro bitTest 2
	push %1
	and %1, %2
	printlnI %1
	cmp %1, %2
	pop %1
%endmacro

; carry = floppy is supported
F32Init:
    f32Command VERSION, 0, 0
	cmp byte [FifoBuffer], 0x90
	jne .notSupported
	; in order to not have to issue a Configure command every reset, I could follow step 3 of Reinitialisation in the osdev.wiki article
	call F32Reset
	f32Command RECALIBRATE, 0, 1
	stc
	ret
	.notSupported:
		clc
		ret

; cl = has execution phase, bl = command, bh = parameter, FifoBuffer = result byte
F32Command:
	xor edx, edx
	xor eax, eax
	.step2:
		xor eax, eax
		mov dx, word [REG_STATUS_MAIN]
		in ax, dx		; read MSR
		bitTest eax, 128
		jne near .reset
		and eax, 0xc0
		cmp eax, 0x80
		;bitTest eax, 64					; check bit 6
		je near .reset
		mov dx, word [REG_FIFO]
		xor ax, ax
		mov al, bl
		out dx, ax			; send command to FIFO register
		mov dx, word [REG_STATUS_MAIN]
	.loop:						; RQM and DIO check loop
		xor eax, eax
		in ax, dx					; read MSR
		bitTest eax, 128				; check bit 7
		jne .loop
		bitTest eax, 64					; check bit 6
		je .loop
	xor eax, eax
	mov al, bh
	mov dx, word [REG_FIFO]
	out dx, ax			; send parameter
	cmp cl, 1
	jne near .resultPhase	; if command doesn't have execution phase, skip
	mov dx, word [REG_STATUS_MAIN]
	in ax, dx
	bitTest eax, 32					; test bit 5
	jne .resultPhase			; if command doesn't have execution phase, skip
	.loop2:
		in ax, dx
		bitTest eax, 128			; check bit 7
		jne .loop2
		.loop3:
			push dx
			mov dx, word [REG_FIFO]
			in ax, dx
			mov byte [FifoBuffer], al
			pop dx
			in ax, dx
			bitTest eax, 160			; bl & (bit 7 and bit 5)
			je .loop3
		bitTest eax, 32				; test bit 5
		je .loop2
	.resultPhase:
		mov dx, REG_FIFO
		in ax, dx
		mov [FifoBuffer], al
		mov dx, word [REG_STATUS_MAIN]
		in ax, dx
		push ax
		shr ax, 4
		bitTest eax, 0				; check bit 4
		jne .step2
		shr ax, 2
		bitTest eax, 0
		jne .step2
		bitTest eax, 2
		jne .step2
		jmp .done
	.reset:
		println MsgS3
		call F32Reset
		jmp .step2
	.done:
		popax
		ret

F32Reset:
	pusha
	mov dx, word [REG_DATARATE_SELECT]
	xor ax, ax
	or ax, 0x80
	out dx, ax
	f32Command CONFIGURE, 0, 0
	call F32DriveSelect
	popa

F32DriveSelect:
	pusha
	xor ax, ax
	mov dx, word [REG_CONFIG_CONTROL]
	out dx, ax					; set data rate, can be changed to support multiple floopy types. setting it to 0 supports 1.44MB floppies
	mov dx, word [REG_DIGITAL_OUT]
	in ax, dx					; read DOR in order to set drive select, following operations can be changed to support mutiple floppies
	shr ax, 2
	shl ax, 2					; clears the two least significant bit in order to select drive 0
	out dx, ax
	popa
	ret










