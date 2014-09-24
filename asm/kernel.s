
;*******************************************************
;
;	Stage3.asm
;		A basic 32 bit binary kernel running
;
;	OS Development Series
;*******************************************************

org	0x100000			; Kernel starts at 1 MB

bits	32				; 32 bit code

jmp	Entry				; jump to entry point

Ram: dd 0

%include "terminal.s"
%include "sysinfo.s"

Entry:

	;-------------------------------;
	;   Set registers
	;-------------------------------;

    mov eax, [edx + BootInfo.ram]
    mov dword [Ram], eax
	mov	ax, 0x10		; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	esp, 90000h		; stack begins from 90000h

	;---------------------------------------;
	;   Jump to terminal
	;---------------------------------------;

	mov 	eax, 0
	mov	edx, 0
	call terminal

	;---------------------------------------;
	;   Stop execution
	;---------------------------------------;

	cli
	hlt

AllocPtr: dd 0   ; points to the next free section of memory
MemAlloc: db 0      ; dynamic memory allocation occurs from here until 0xB7FFE