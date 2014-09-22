
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

%include "terminal.s"

Entry:

	;-------------------------------;
	;   Set registers		;
	;-------------------------------;

	mov	ax, 0x10		; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	esp, 90000h		; stack begins from 90000h

	;---------------------------------------;
	;   Clear screen and print success	;
	;---------------------------------------;

	mov 	eax, 0
	mov	edx, 0
	call terminal

	;---------------------------------------;
	;   Stop execution			;
	;---------------------------------------;

	cli
	hlt
    
StrBuff: db 0x0A, "> ",0x00