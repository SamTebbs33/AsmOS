
;*******************************************************
;
;	Stage2.asm
;		Stage2 Bootloader
;
;	OS Development Series
;*******************************************************

bits	16

; Remember the memory map-- 0x500 through 0x7bff is unused above the BIOS data area.
; We are loaded at 0x500 (0x50:0)

org 0x500

[map symbols kernel.map]

jmp	main				; go to start

;*******************************************************
;	Preprocessor directives
;*******************************************************

%include "boot/Gdt.s"			; Gdt routines
%include "boot/A20.s"			; A20 enabling
%include "boot/Fat12.s"			; FAT12 driver. Kinda :)
%include "boot/common.s"

;*******************************************************
;	Data Section
;*******************************************************

LoadingMsg db 0x0D, 0x0A, "Searching for Operating System...", 0x00
msgFailure db 0x0D, 0x0A, "*** FATAL: MISSING OR CURRUPT KRNL.SYS. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0x00
Ram: db 0
times 3 db 0
MsgSetBootInfo: db "SetBootInf",0x00

struc	MemoryMapEntry
	.baseAddress resq	1	; base address of address range
	.length		resq	1	; length of address range in bytes
	.type		resd	1	; type of address range
	.acpi_null	resd	1	; reserved
endstruc

struc multiboot_info
	.flags		resd	1	; required
	.memoryLo	resd	1	; memory size. Present if flags[0] is set
	.memoryHi	resd	1
	.bootDevice	resd	1	; boot device. Present if flags[1] is set
	.cmdLine	resd	1	; kernel command line. Present if flags[2] is set
	.mods_count	resd	1	; number of modules loaded along with kernel. present if flags[3] is set
	.mods_addr	resd	1
	.syms0		resd	1	; symbol table info. present if flags[4] or flags[5] is set
	.syms1		resd	1
	.syms2		resd	1
	.mmap_length	resd	1	; memory map. Present if flags[6] is set
	.mmap_addr	resd	1
	.drives_length	resd	1	; phys address of first drive structure. present if flags[7] is set
	.drives_addr	resd	1
	.config_table	resd	1	; ROM configuation table. present if flags[8] is set
	.bootloader_name resd	1	; Bootloader name. present if flags[9] is set
	.apm_table	resd	1	; advanced power management (apm) table. present if flags[10] is set
	.vbe_control_info resd	1	; video bios extension (vbe). present if flags[11] is set
	.vbe_mode_info	resd	1
	.vbe_mode	resw	1
	.vbe_interface_seg resw	1
	.vbe_interface_off resw	1
	.vbe_interface_len resw	1
endstruc

bootinfo: istruc multiboot_info
at multiboot_info.flags, dd 65
at multiboot_info.mmap_length, dd 1
iend

MemMapAddr: times 768 db 0      ; allow for 32 MemoryMapEntries, each 24 bytes

;************************************************;
;	Prints a string
;	DS=>SI: 0 terminated string
;************************************************;
Print:
			lodsb				; load next byte from string from SI to AL
			or	al, al			; Does AL=0?
			jz	PrintDone		; Yep, null terminator found-bail out
			mov	ah, 0eh			; Nope-Print the character
			int	10h
			jmp	Print			; Repeat until null terminator found
	PrintDone:
			ret				; we are done, so return

;*******************************************************
;	STAGE 2 ENTRY POINT
;
;		-Store BIOS information
;		-Load Kernel
;		-Install GDT; go into protected mode (pmode)
;		-Jump to Stage 3
;*******************************************************

MsgEntry: db "Boot2 entry",0x00
main:

	;-------------------------------;
	;   Setup segments and stack	;
	;-------------------------------;

	cli				; clear interrupts
	xor	eax, eax			; null segments
	mov	ds, ax
	mov	es, ax
	mov	ax, 0x0			; stack begins at 0x9000-0xffff
	mov	ss, ax
	mov	sp, 0xFFFF
	sti				; enable interrupts

    call SetBootInfo

	;-------------------------------;
	;   Install our GDT		;
	;-------------------------------;

	call	InstallGDT		; install our GDT

	;-------------------------------;
	;   Enable A20			;
	;-------------------------------;

	call	EnableA20_KKbrd_Out

        ;-------------------------------;
        ; Initialize filesystem		;
        ;-------------------------------;

	call	LoadRoot		; Load root directory table

        ;-------------------------------;
        ; Load Kernel			;
        ;-------------------------------;

	mov	ebx, 0			; BX:BP points to buffer to load to
    	mov	bp, IMAGE_RMODE_BASE
	mov	si, ImageName		; our file to load
	call	LoadFile		; load our file
	mov	dword [ImageSize], ecx	; save size of kernel
	cmp	ax, 0			; Test for success
	je	EnterStage3		; yep--onto Stage 3!
	mov	si, msgFailure		; Nope--print error
	mov	ah, 0
	int     0x16                    ; await keypress
	int     0x19                    ; warm boot computer
	cli				; If we get here, something really went wong
	hlt

	;-------------------------------;
	;   Go into pmode		;
	;-------------------------------;

EnterStage3:

    xor eax, eax
	cli				; clear interrupts
	mov	eax, cr0		; set bit 0 in cr0--enter pmode
	or	eax, 1
	mov	cr0, eax
	jmp	CODE_DESC:Stage3	; far jump to fix CS. Remember that the code selector is 0x8!

	; Note: Do NOT re-enable interrupts! Doing so will triple fault!
	; We will fix this in Stage 3.

SetBootInfo:        ;TODO: Add memory error checking for bx = 0 and ax = -1
    push esi
    push edi
    push eax
    push ebx
    push bp
    xor esi, esi
    xor edi, edi
    mov esi, MemMapAddr
    call BiosGetMemoryMap
    mov dword [bootinfo + 40], ebp
    call BiosGetMemorySize64MB
    mov dword [bootinfo + multiboot_info.memoryLo], eax
    mov dword [bootinfo + multiboot_info.memoryHi], ebx
    mov dword [bootinfo + multiboot_info.mmap_addr], MemMapAddr
    mov dword [bootinfo + multiboot_info.flags], 65
    pop bp
    pop ebx
    pop eax
    pop edi
    pop esi
    ret

;---------------------------------------------
;	Get memory map from bios
;	/in es:di->destination buffer for entries
;	/ret bp=entry count
;---------------------------------------------

MsgMemMap: db "MemMap",0x00
MsgError: db "Error", 0x00
BiosGetMemoryMap:
	pushad
	xor	ebx, ebx
	xor	bp, bp			; number of entries stored here
	mov	edx, 'PAMS'		; 'SMAP'
	mov	eax, 0xe820
	mov	ecx, 24			; memory map entry struct is 24 bytes
	int	0x15			; get first entry
	jc	.error	
	cmp	eax, 'PAMS'		; bios returns SMAP in eax
	jne	.error
	test	ebx, ebx		; if ebx=0 then list is one entry long; bail out
	je	.error
	jmp	.start
.next_entry:
	mov	edx, 'PAMS'		; some bios's trash this register
	mov	ecx, 24			; entry is 24 bytes
	mov	eax, 0xe820
	int	0x15			; get next entry
.start:
	jcxz	.skip_entry		; if actual returned bytes is 0, skip entry
.notext:
	mov	ecx, [esi + MemoryMapEntry.length]	; get length (low dword)
	test	ecx, ecx		; if length is 0 skip it
	jne	short .good_entry
	mov	ecx, [esi + MemoryMapEntry.length + 4]; get length (upper dword)
	jecxz	.skip_entry		; if length is 0 skip it
.good_entry:
	inc	bp			; increment entry count
	add	esi, 24			; point di to next entry in buffer
.skip_entry:
	cmp	ebx, 0			; if ebx return is 0, list is done
	jne	.next_entry		; get next entry
	jmp	.done
.error:
    mov si, MsgError
    call Print
	stc
.done:
	popad
	ret

;---------------------------------------------
;	Get memory size for >64M configuations
;	ret\ ax=KB between 1MB and 16MB
;	ret\ bx=number of 64K blocks above 16MB
;	ret\ bx=0 and ax= -1 on error
;---------------------------------------------
 
BiosGetMemorySize64MB:
	push	ecx
	push	edx
	xor	ecx, ecx		;clear all registers. This is needed for testing later
	xor	edx, edx
	mov	ax, 0xe801
	int	0x15	
	jc	.error
	cmp	ah, 0x86		;unsupported function
	je	.error
	cmp	ah, 0x80		;invalid command
	je	.error
	jcxz	.use_ax			;bios may have stored it in ax,bx or cx,dx. test if cx is 0
	mov	ax, cx			;its not, so it should contain mem size; store it
	mov	bx, dx

.use_ax:
	pop	edx			;mem size is in ax and bx already, return it
	pop	ecx
	ret
 
.error:
	mov	ax, -1
	mov	bx, 0
	pop	edx
	pop	ecx
	ret


;******************************************************
;	ENTRY POINT FOR STAGE 3
;******************************************************

bits 32

Stage3:

	;-------------------------------;
	;   Set registers		;
	;-------------------------------;

	mov	ax, DATA_DESC	; set data segments to data selector (0x10)
	mov	ds, ax
	mov	ss, ax
	mov	es, ax
	mov	esp, 90000h		; stack begins from 90000h

	;-------------------------------;
	; Copy kernel to 1MB		;
	;-------------------------------;

CopyImage:
  	 mov	eax, dword [ImageSize]
  	 movzx	ebx, word [bpbBytesPerSector]
  	 mul	ebx
  	 mov	ebx, 4
  	 div	ebx
   	 cld
   	 mov    esi, IMAGE_RMODE_BASE
   	 mov	edi, IMAGE_PMODE_BASE
   	 mov	ecx, eax
   	 rep	movsd                   ; copy image to its protected mode address

	;---------------------------------------;
	;   Execute Kernel and set up multiboot info
	;---------------------------------------;

    mov eax, 0x2BADB002
    mov ebx, 0
    mov edx, [ImageSize]
    mov ecx, bootinfo

	jmp	CODE_DESC:IMAGE_PMODE_BASE; jump to our kernel! Note: This assumes Kernel's entry point is at 1 MB

	;---------------------------------------;
	;   Stop execution			;
	;---------------------------------------;

	cli
	hlt