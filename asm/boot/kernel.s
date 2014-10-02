
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

bootInfoAddr: dw 0
totalRam: dd 0

%include "terminal.s"
%include "IDT.s"

struc MemoryMapEntry
	.baseAddress resq	1	; base address of address range
	.length		resq	1	; length of address range in bytes
	.type		resd	1	; type of address range
	.acpi_null	resd	1	; reserved
endstruc

Entry:

	;-------------------------------;
	;   Set registers
	;-------------------------------;

    setColourClr [COLOUR_LGREEN], [COLOUR_BLACK]
    mov dword [bootInfoAddr], ecx
    mov eax, dword [ecx+4]       ; low memory
    mov dword [totalRam], eax
    xor eax, eax
    mov eax, dword [ecx+8]
    mov ebx, 64
    mul ebx
    add eax, 1024                   ; add 1MB (since low mem = 1MB to 16MB)
    add dword [totalRam], eax       ; eax = low Ram + high Ram
    mov ebx, eax
    call MemInit
    call InitInterrupts
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