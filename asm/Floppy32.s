
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

REG_STATUS_A: db 0x3F0         ; read only
REG_STATUS_B: db 0x3F1         ; read only
REG_DIGITAL_OUT: db 0x3F2      ; controls floppy drive motors, drive selection and resets
REG_TAPE_DRIVE: db 0x3F3
REG_STATUS_MAIN: db 0x3F4      ; read only, contain the "busy" flags that must be checked before reading/writing through FIFO
REG_DATARATE_SELECT: db 0x3F4 ; write only
REG_FIFO: db 0x3F5             ; all commands, parameter info, result codes and disk data transfers go through this
REG_DIGITAL_IN: db 0x3F7      ; read only
REG_CONFIG_CONTROL: db 0x3F7   ; write only

MOTOR_SPIN_DELAY: equ 300		; suggested motor spin delay (ms), test with 50ms
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

F32Init:
    ; set bit 3 of Digital output register in order to disable interrupt requests from the floppy controller

; dx = port, ax = input, cl = has execution phase, bl = command, bh = parameter, FifoBuffer = result byte
F32Command:
	mov dx, REG_STATUS_MAIN
	in ax, dx		; read MSR
	.step2:
		test ax, 128				; check bit 7
		jne near .reset
		test ax, 64					; check bit 6
		je near .reset
		mov dx, REG_FIFO
		mov al, bl
		out dx, ax			; send command to FIFO register
		mov dx, REG_STATUS_MAIN
	.loop:						; RQM and DIO check loop
		in ax, dx		; read MSR
		test ax, 128				; check bit 7
		jne .loop
		test ax, 64					; check bit 6
		je .loop
	mov al, bh
	mov dx, REG_FIFO
	out dx, ax			; send parameter
	cmp cl, 1
	jne .resultPhase	; if command doesn't have execution phase, skip
	mov dx, REG_STATUS_MAIN
	in ax, dx
	test ax, 32					; test bit 5
	jne .resultPhase			; if command doesn't have execution phase, skip
	.loop2:
		in ax, dx
		test ax, 128			; check bit 7
		jne .loop2
		.loop3:
			push dx
			mov dx, REG_FIFO
			in ax, dx
			mov byte [FifoBuffer], al
			pop dx
			in ax, dx
			test ax, 160			; bl & (bit 7 and bit 5)
			je .loop3
		test ax, 32				; test bit 5
		je .loop2
	.resultPhase:
		mov dx, REG_FIFO
		in ax, dx
		mov byte [FifoBuffer], ax
		mov dx, REG_STATUS_MAIN
		in ax, dx
		push ax
		shr ax, 4
		test ax, 0				; check bit 4
		jne .step2
		shr ax, 2
		test ax, 0
		jne .step2
		test ax, 2
		jne .step2
		jmp .done
	.reset:

	.done:
		popax
		ret













