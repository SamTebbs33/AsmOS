; Sources
;   * http:;wiki.osdev.org/Interrupt_Descriptor_Table
;   * http:;brokenthorn.com/Resources/OSDev15.html
;   * http://brokenthorn.com/Resources/OSDev16.html

ErrorDivZero: db "Division by zero",0x00
ErrorDebugger: db "Debugger",0x00
ErrorNMI: db "NMI",0x00
ErrorBreakpoint: db "Breakpoint",0x00
ErrorOverflow: db "Oveflow",0x00
ErrorBounds: db "Bounds",0x00
ErrorInvOpcode: db "Invalid opcode",0x00
ErrorCoprocessor: db "Coprocessor not available",0x00
ErrorDFault: db "Double fault",0x00
ErrorInvTask: db "Invalid task state segment",0x00
ErrorStackFault: db "Stack fault",0x00
ErrorGenProtFault: db "General portection fault",0x00
ErrorPageFault: db "Page fault",0x00
ErrorMathsFault: db "Maths fault",0x00
ErrorAlignCheck: db "Alignment check",0x00
ErrorMachCheck: db "Machine check",0x00
ErrorFlop: db "SIMD Floating point exception",0x00
ErrorUnhandled: db "Unhandled exception",0x00
InterruptFloppy: db "Floppy interrupt", 0x00

floppyIRQ: db 0
 
%define ICW_1 0x11				; 00010001 binary. Enables initialization mode and we are sending ICW 4
 
%define PIC_1_CTRL 0x20				; Primary PIC control register
%define PIC_2_CTRL 0xA0				; Secondary PIC control register
 
%define PIC_1_DATA 0x21				; Primary PIC data register
%define PIC_2_DATA 0xA1				; Secondary PIC data register
 
%define IRQ_0	0x20				; IRQs 0-7 mapped to use interrupts 0x20-0x27
%define IRQ_8	0x28				; IRQs 8-15 mapped to use interrupts 0x28-0x36

%define IRQ_TIMER IRQ_0
%define IRQ_KEYBOARD IRQ_0+1
%define IRQ_SERIAL2 IRQ_0+3
%define IRQ_SERIAL1 IRQ_0+4
%define IRQ_PARALLEL2 IRQ_0+5
%define IRQ_FLOPPY IRQ_0+6
%define IRQ_PARALLEL1 IRQ_0+7

%define IRQ_CMOSTIMER IRQ_8
%define IRQ_CGARETRACE IRQ_8+1
%define IRQ_AUXILLARY IRQ_8+4
%define IRQ_FPU IRQ_8+5
%define IRQ_HDD IRQ_8+6

%define		PIC_OCW2_MASK_L1		1		;00000001	Level 1 interrupt level
%define		PIC_OCW2_MASK_L2		2		;00000010	Level 2 interrupt level
%define		PIC_OCW2_MASK_L3		4		;00000100	Level 3 interrupt level
%define		PIC_OCW2_MASK_EOI		0x20	;00100000	End of Interrupt command
%define		PIC_OCW2_MASK_SL		0x40	;01000000	Select command
%define		PIC_OCW2_MASK_ROTATE	0x80	;10000000	Rotation command

%define		PIC_OCW3_MASK_RIS		1		;00000001
%define		PIC_OCW3_MASK_RIR		2		;00000010
%define		PIC_OCW3_MASK_MODE		4		;00000100
%define		PIC_OCW3_MASK_SMM		0x20	;00100000
%define		PIC_OCW3_MASK_ESMM		0x40	;01000000
%define		PIC_OCW3_MASK_D7		0x80	;10000000

%define PIC1_REG_COMMAND		0x20			; command register
%define PIC1_REG_STATUS			0x20			; status register
%define PIC1_REG_DATA			0x21			; data register
%define PIC1_REG_IMR			0x21			; interrupt mask register (imr)
 
%define PIC2_REG_COMMAND		0xA0			; ^ see above register names
%define PIC2_REG_STATUS			0xA0
%define PIC2_REG_DATA			0xA1
%define PIC2_REG_IMR			0xA1

%define PIC_ICW1_MASK_IC4			0x1	;00000001	; Expect ICW 4 bit
%define PIC_ICW1_MASK_SNGL			0x2	;00000010	; Single or Cascaded
%define PIC_ICW1_MASK_ADI			0x4	;00000100	; Call Address Interval
%define PIC_ICW1_MASK_LTIM			0x8	;00001000	; Operation Mode
%define PIC_ICW1_MASK_INIT			0x10	;00010000	; Initialization Command

%define PIC_ICW1_IC4_EXPECT			1	;1		;Use when setting PIC_ICW1_MASK_IC4
%define PIC_ICW1_IC4_NO			0	;0
%define PIC_ICW1_SNGL_YES			2	;10		;Use when setting PIC_ICW1_MASK_SNGL
%define PIC_ICW1_SNGL_NO			0	;00
%define PIC_ICW1_ADI_CALLINTERVAL4		4	;100		;Use when setting PIC_ICW1_MASK_ADI
%define PIC_ICW1_ADI_CALLINTERVAL8		0	;000
%define PIC_ICW1_LTIM_LEVELTRIGGERED	8	;1000		;Use when setting PIC_ICW1_MASK_LTIM
%define PIC_ICW1_LTIM_EDGETRIGGERED		0	;0000
%define PIC_ICW1_INIT_YES			0x10	;10000		;Use when setting PIC_ICW1_MASK_INIT
%define PIC_ICW1_INIT_NO			0	;00000

%define PIC_ICW4_MASK_UPM		0x1	;00000001	; Mode
%define PIC_ICW4_MASK_AEOI		0x2	;00000010	; Automatic EOI
%define PIC_ICW4_MASK_MS		0x4	;00000100	; Selects buffer type
%define PIC_ICW4_MASK_BUF		0x8	;00001000	; Buffered mode
%define PIC_ICW4_MASK_SFNM		0x10	;00010000	; Special fully-nested mode

%define PIC_ICW4_UPM_86MODE		1	;1		;Use when setting PIC_ICW4_MASK_UPM
%define PIC_ICW4_UPM_MCSMODE	0	;0
%define PIC_ICW4_AEOI_AUTOEOI	2	;10		;Use when setting PIC_ICW4_MASK_AEOI
%define PIC_ICW4_AEOI_NOAUTOEOI	0	;00
%define PIC_ICW4_MS_BUFFERMASTER	4	;100		;Use when setting PIC_ICW4_MASK_MS
%define PIC_ICW4_MS_BUFFERSLAVE	0	;000
%define PIC_ICW4_BUF_MODEYES	8	;1000		;Use when setting PIC_ICW4_MASK_BUF
%define PIC_ICW4_BUF_MODENO		0	;0000
%define PIC_ICW4_SFNM_NESTEDMODE	0x10	;10000		;Use when setting PIC_ICW4_MASK_SFNM
%define PIC_ICW4_SFNM_NOTNESTED	0	;00000

%define		PIT_OCW_MASK_BINCOUNT			1	;00000001
%define		PIT_OCW_MASK_MODE				0xE	;00001110
%define		PIT_OCW_MASK_RL				0x30	;00110000
%define		PIT_OCW_MASK_COUNTER			0xC0	;11000000

%define		PIT_OCW_BINCOUNT_BINARY	0	;0		;! Use when setting PIT_OCW_MASK_BINCOUNT
%define		PIT_OCW_BINCOUNT_BCD	1	;1
%define		PIT_OCW_MODE_TERMINALCOUNT	0	;0000		;! Use when setting PIT_OCW_MASK_MODE
%define		PIT_OCW_MODE_ONESHOT	0x2	;0010
%define		PIT_OCW_MODE_RATEGEN	0x4	;0100
%define		PIT_OCW_MODE_SQUAREWAVEGEN	0x6	;0110
%define		PIT_OCW_MODE_SOFTWARETRIG	0x8	;1000
%define		PIT_OCW_MODE_HARDWARETRIG	0xA	;1010
%define		PIT_OCW_RL_LATCH		0	;000000	;! Use when setting PIT_OCW_MASK_RL
%define		PIT_OCW_RL_LSBONLY		0x10	;010000
%define		PIT_OCW_RL_MSBONLY		0x20	;100000
%define		PIT_OCW_RL_DATA		0x30	;110000
%define		PIT_OCW_COUNTER_0		0	;00000000	;! Use when setting PIT_OCW_MASK_COUNTER
%define		PIT_OCW_COUNTER_1		0x40	;01000000
%define		PIT_OCW_COUNTER_2		0x80	;10000000

%define		PIT_REG_COUNTER0		0x40
%define		PIT_REG_COUNTER1		0x41
%define		PIT_REG_COUNTER2		0x42
%define		PIT_REG_COMMAND		0x43

pitTicks: dd 0

%macro picCommand 2
    mov ax, %1
    mov bx, %2
    call PICCommand
%endmacro

%macro picSendData 2
    mov ax, %1
    mov bx, %2
    call PICSendData
%endmacro

; ax = (%1 & ~%2) | %3
%macro andNotOr 3
    mov ax, %2
    not ax
    and ax, %2
    or ax, %3
%endmacro

%macro pitCommand 1
    out PIT_REG_COMMAND, %1
%endmacro

; data, counter port
%macro pitSendData 2
    out %2, %1
%endmacro

; counter port, ax = data
%macro pitReadData 1
    in ax, %1
%endmacro

; irq number, handler
%macro setIRQ 2
    mov eax, %1
    mov ebx, %2
    call IDT_SetGate
%endmacro

; entry = 64 bits
;
; Name      Bit     Function
; offset2    48:63  High word of the handler's offset
; P         47      can be set to 0 for unused interrupts or paging
; DPL       45:46   Descriptor priviledge level (ring 0 -> 3)
; S         44      Storage segment, 0 for interrupt gates
; Gate type 40:43   5 = 32bit task gate, 6 = 16bit interrupt gate, 7 = 16bit trap gate, 14 = 32bit interrupt gate, 15 = 32bit trap gate
; 0         32:29   must be 0
; Selector  16:31   Kernel's selector of the interrupt function. A selector's descriptor's DPL must be 0. Selector is the same as the GDT's code selector
; offset1   0:15    Low word of the handler's offset

; type
;   7                           0
; +---+---+---+---+---+---+---+---+
; | P |  DPL  | S |    GateType   |
; +---+---+---+---+---+---+---+---+

; Interrupt gates are called when a software interrupt is used
; Trap gates are called when an exception is thrown
; Hardware interrupts 0-7 are mapped to 0x08-0x0F. 8-F are mapped to 0x70-0x77 (by default, before remapping)

bits 32

struc idt_entry
   .m_baseLow      resw   1
   .m_selector      resw   1
   .m_reserved      resb   1
   .m_flags      resb   1
   .m_baseHi      resw   1
endstruc

struc idt_ptr
   .m_size         resw   1
   .m_base         resd   1
endstruc

_IDT:

%rep 256
   istruc idt_entry
      at idt_entry.m_baseLow,      dw 0
      at idt_entry.m_selector,   dw 0x8   
      at idt_entry.m_reserved,   db 0
      at idt_entry.m_flags,      db 10001110b
      at idt_entry.m_baseHi,      dw 0
   iend
%endrep

_IDT_End:
_IDT_Size   db   _IDT_End - _IDT   
_Desc_Size   db   8

_IDT_Ptr:
   istruc idt_ptr
      at idt_ptr.m_size, dw 0
      at idt_ptr.m_base, dd 0
   iend

;********************
; Installs idt
;********************

InitInterrupts:
    call PICInit
    ;call PITInit
    call HandlerInit
    call IDT_Install
    ret

IDT_Install:
   mov   word [_IDT_Ptr+idt_ptr.m_size], _IDT_Size - 1
   mov   dword [_IDT_Ptr+idt_ptr.m_base], _IDT
   lidt   [_IDT_Ptr]
   cli
   ;sti
   ret

;***********************
;   Install interrupt gate
;   EAX=>Interrupt Number
;   EBX=>Base address of ir
;***********************

IDT_SetGate:
   pusha
   mov   edx, 8
   mul   dx
   add   eax, _IDT
   mov   word [eax+idt_entry.m_baseLow], bx
   shr   ebx, 16
   mov   word [eax+idt_entry.m_baseHi], bx   
   popa
   ret

IDT_InstallDefault:
    pusha
    mov ecx, 255
    mov ebx, HandlerDef
    .loop:
        mov eax, ecx
        call IDT_SetGate
        loop .loop
    popa
    ret

; ax = command, bx = pic number (0/1)
PICCommand:
    cmp bx, 1       ; check that pic number is not greater than one
    push dx
    jg .return
    mov dx, PIC1_REG_COMMAND
    jl .do
    mov dx, PIC2_REG_COMMAND
    .do:
        out dx, ax
        pop dx
    .return:
        ret

; ax = data, bx = pic number (0/1)
PICSendData:
    cmp bx, 1       ; check that pic number is not greater than one
    push dx
    jg .return
    mov dx, PIC1_REG_DATA
    jl .do
    mov dx, PIC2_REG_DATA
    .do:
        out dx, ax
        pop dx
    .return:
        ret

; ax = data, bx = pic number (0/1)
PICReadData:
    cmp bx, 1       ; check that pic number is not greater than one
    push dx
    jg .return
    mov dx, PIC1_REG_DATA
    jl .do
    mov dx, PIC2_REG_DATA
    .do:
        in ax, dx
        pop dx
    .return:
        ret

PICInit:
    xor ax, ax
    mov ax, PIC_ICW1_MASK_INIT
    not ax
    and ax, 0
    or ax, PIC_ICW1_INIT_YES
    mov dx, PIC_ICW1_MASK_IC4
    not dx
    and ax, dx
    or ax, PIC_ICW1_IC4_EXPECT
    picCommand ax, 0
    picCommand ax, 1
    ; setting up base irq values
    picSendData IRQ_0, 0
    picSendData IRQ_8, 1
    picSendData 0x04, 0
    picSendData 0x02, 1
    mov dx, PIC_ICW4_MASK_UPM
    not dx
    and ax, dx
    or ax, PIC_ICW4_UPM_86MODE
    picSendData ax, 0
    picSendData ax, 1
    ret

; ebx = frequency, cx = counter, dx = mode
PITStartCounter:
    cmp ebx, 0
    je .return
    xor ax, ax
    andNotOr ax, PIT_OCW_MASK_MODE, dx
    andNotOr ax, PIT_OCW_MASK_RL, PIT_OCW_RL_DATA
    andNotOr ax, PIT_OCW_MASK_COUNTER, cx
    pitCommand ax
    mov eax, 1193180
    div ebx
    push eax
    and eax, 0xFF
    pitSendData eax, PIT_OCW_COUNTER_0
    pop eax
    shr eax, 8
    and eax, 0xFF
    pitSendData eax, PIT_OCW_COUNTER_0
    mov dword [pitTicks], 0
    .return:
        ret

PITInit:
    setIRQ IRQ_0, HandlerPIT
    ret

; send EOI to primary PIC
EndInterrupt
	mov	al, 0x20	; set bit 4 of OCW 2
	out	PIC1_REG_COMMAND, al	; write to primary PIC command register
    iret

HandlerInit:
    call IDT_InstallDefault
    setIRQ IRQ_FLOPPY, HandlerFloppy
    ret

HandlerDef:
    pop eax
    print ErrorUnhandled
    jmp EndInterrupt

HandlerPIT:
    inc dword [pitTicks]
    jmp EndInterrupt

HandlerFloppy:
    add esp, 12
    pushad
    cli
    println InterruptFloppy
    mov byte [floppyIRQ], 1
    picCommand PIC_OCW2_MASK_EOI, 0
    sti
    popad
    iretd

HandlerDivZero:
