;--------------------------------------------------;
; Terminal Input / Output library
;
;   Functions for terminal input and output
;
;   * PutCh(char bl)
;       - Prints the character at the print cursor position
;   * PutL()
;       - Prints a new line and advances the cursor
;   * PutS(str ebx)
;       - Prints the string
;   * PutI(int eax)
;       - Prints the int
;   * SetColour(bkg al, charcol dl)
;       - Sets the text background and character colour
;   * MoveCur(x bl, y bh)
;       - Moves the hardware cursor to the x and y position
;   * GotoXY(x bl, y bh)
;       - Moves the print cursor to the x and y position
;   * ClrScr()
;       - Clears the screen and fills it with the current background colour
;--------------------------------------------------;

bits 32

%include "KeyMap.s"

%define		VIDMEM	0xB8000			; video memory
%define		COLS	80			; width and height of screen
%define		LINES	25
%define		CHAR_ATTRIB 0x01

PutX: db 0					; current x/y location
PutY: db 0
CurX: db 0
CurY: db 0

ColChar: db 1
ColBkg: db 0

KeyOffset: db 0

COLOUR_BLACK: db 0x00
COLOUR_DBLUE: db 0x01
COLOUR_DGREEN: db 0x02
COLOUR_LTURQUOISE: db 0x03
COLOUR_DRED: db 0x04
COLOUR_DPURPLE: db 0x05
COLOUR_DORANGE: db 0x06
COLOUR_LGREY: db 0x07
COLOUR_DGREY: db 0x08
COLOUR_LBLUE: db 0x09
COLOUR_LGREEN: db 0x0A
COLOUR_DTURQUOISE: db 0x0B
COLOUR_LRED: db 0x0C
COLOUR_LPURPLE: db 0x0D
COLOUR_YELLOW: db 0x0E
COLOUR_WHITE: db 0x0F

MsgHex: db "0x",0x00

;**************************************************;
; Macros
;**************************************************;

; print(str)
%macro print 1
    mov ebx, %1
    call PutS
%endmacro

; println(str)
%macro println 1
    print %1
    call PutL
%endmacro

; printC(char)
%macro printC 1
    mov bl, %1
    call PutCh
%endmacro

; printlnC(char)
%macro printlnC 1
    printC %1
    call PutL
%endmacro

; printI(int)
%macro printI 1
    mov eax, %1
    call PutI
%endmacro

; printlnI(int)
%macro printlnI 1
    printI %1
    call PutL
%endmacro

; printH(int)
%macro printH 1
    mov al, %1
    call PutHex
%endmacro

; printlnH(int)
%macro printlnH 1
    printH %1
    call PutL
%endmacro

%macro print8 1
    pusha
    mov ecx, 7
    .loop:
        
%endmacro

; setColour(text, background)
%macro setColour 2
    mov al, %2
    mov dl, %1
    call SetColour
%endmacro

; setColourClr(text, background)
%macro setColourClr 2
    mov al, %2
    mov dl, %1
    call SetColour
    call ClrScr
%endmacro


;**************************************************;
;	Putch32 ()
;		- Prints a character to screen
;	BL => Character to print
;**************************************************;

PutCh:

	pusha				; save registers
	mov	edi, VIDMEM		; get pointer to video memory

	;-------------------------------;
	;   Get current position	;
	;-------------------------------;

	xor	eax, eax		; clear eax

		;--------------------------------
		; Remember: currentPos = x + y * COLS! x and y are in PutX and PutY.
		; Because there are two bytes per character, COLS=number of characters in a line.
		; We have to multiply this by 2 to get number of bytes per line. This is the screen width,
		; so multiply screen with * PutY to get current line
		;--------------------------------

		mov	ecx, COLS*2		; Mode 7 has 2 bytes per char, so its COLS*2 bytes per line
		mov	al, byte [PutY]	; get y pos
		mul	ecx			; multiply y*COLS
		push	eax			; save eax--the multiplication

		;--------------------------------
		; Now y * screen width is in eax. Now, just add PutX. But, again remember that PutX is relative
		; to the current character count, not byte count. Because there are two bytes per character, we
		; have to multiply PutX by 2 first, then add it to our screen width * y.
		;--------------------------------

		mov	al, byte [PutX]	; multiply PutX by 2 because it is 2 bytes per char
		mov	cl, 2
		mul	cl
		pop	ecx			; pop y*COLS result
		add	eax, ecx

		;-------------------------------
		; Now eax contains the offset address to draw the character at, so just add it to the base address
		; of video memory (Stored in edi)
		;-------------------------------

		xor	ecx, ecx
		add	edi, eax		; add it to the base address

	;-------------------------------;
	;   Watch for new line          ;
	;-------------------------------;

	cmp	bl, 0x0A		; is it a newline character?
	je	.Row			; yep--go to next row

	;-------------------------------;
	;   Print a character           ;
	;-------------------------------;

	mov	dl, bl			; Get character
	mov	dh, [CHAR_ATTRIB]	; the character attribute
	mov	word [edi], dx		; write to video display

	;-------------------------------;
	;   Update next position        ;
	;-------------------------------;

	inc	byte [PutX]		; go to next character
	cmp	byte [PutX], COLS		; are we at the end of the line?
	je	.Row			; yep-go to next row
	jmp	.done			; nope, bail out

	;-------------------------------;
	;   Go to next row              ;
	;-------------------------------;

.Row:
	mov	byte [PutX], 1 	; go back to col 1
	inc	byte [PutY]		; go to next row
    cmp byte [PutY], LINES
    je .scroll

	;-------------------------------;
	;   Restore registers & return  ;
	;-------------------------------;

.done:
    mov bl, byte [PutX]
    mov bh, byte [PutY]
    cmp bl, 0x00
    je .done2
    call MoveCur
.done2:
    popa
    ret
.scroll:
    call Scroll
    jmp .done

;**************************************************;
;	Putl ()
;		- Prints a new line
;**************************************************;

PutL:
    printC 0x0A
	ret

;**************************************************;
;	SetColour ()
;		- Sets the text colour attribute
;	al = the background colour
;	dl = the character colour
;**************************************************;

SetColour:
    mov byte [ColChar], dl
    mov byte [ColBkg], al
	shl	al, 4
	or	ax, dx
	mov	[CHAR_ATTRIB], ax
	ret

;**************************************************;
;	Puts32 ()
;		- Prints a null terminated string
;	parm\ EBX = address of string to print
;**************************************************;

PutS:

	;-------------------------------;
	;   Store registers             ;
	;-------------------------------;

	pusha				; save registers
	push	ebx			; copy the string address
	pop	edi

.loop:

	;-------------------------------;
	;   Get character               ;
	;-------------------------------;

	mov	bl, byte [edi]		; get next character
	cmp	bl, 0			; is it 0 (Null terminator)?
	je	.done			; yep-bail out

	;-------------------------------;
	;   Print the character         ;
	;-------------------------------;

	call	PutCh		; Nope-print it out

	;-------------------------------;
	;   Go to next character        ;
	;-------------------------------;

	inc	edi			; go to next character
	jmp	.loop

.done:

	;-------------------------------;
	;   Update hardware cursor      ;
	;-------------------------------;

	; Its more efficiant to update the cursor after displaying
	; the complete string because direct VGA is slow

	mov	bh, byte [PutY]	; get current position
	mov	bl, byte [PutX]
	call	MoveCur			; update cursor

	popa				; restore registers, and return
	ret

PutI:
    pusha
    mov ecx, 0
    mov ebx, 10
    .loop:
        mov edx, 0
        div ebx
        push eax
        add dl, 48
        pop eax
        push edx
        inc ecx
        cmp eax, 0
        jnz .loop
    .loop2:
        pop edx
        printC dl
        loop .loop2
        popa
        ret
; int val in al

PutHexDigit:
    pusha
    and al, 0xF
    cmp al, 10
    jl .less
    add al, 55
    jmp .put
    .less:
        add al, 48
    .put:
        printC al
        popa
        ret

PutHex:
    pusha
    mov ebx, MsgHex
    call PutS
    mov bl, al
    shr al, 4
    call PutHexDigit
    mov al, bl
    call PutHexDigit
    popa
    ret


;**************************************************;
;	WaitKey ()
;		- Waits for keyboard input
;	bl = scancode
;   carry key was down
;**************************************************;

WaitKey:
    mov bl, byte [KeyOffset]
    .loop:
        in al, 0x64
        test al, 1
        jz .loop
        test al, 0x20
        jnz .loop
        in al, 0x60
        cmp al, 184
        je .noAlt
        cmp al, 170
        je .noShift
        mov bl, al
        shr al, 7
        cmp al, 0
        jne .loop
        ret
    .noShift:
        cmp bl, 0
        je .loop
        mov byte [KeyOffset], 0
        jmp .loop
    .noAlt:
        cmp bl, 0
        je .loop
        mov byte [KeyOffset], 0
        jmp .loop

;**************************************************;
;	WaitKeyAscii (key bl) -> ascii bl
;		- Waits for keyboard input
;**************************************************;

KeyToAscii:
    mov al, bl
    cmp al, 57  ; for some reason KeyMap isn't working with spaces! It prints the wrong char
    je .space
    xor ebx, ebx
    xor edx, edx
    mov dl, byte [KeyOffset]
    .asciiLoop:
        cmp byte [KEYS_CODES + ebx], 0
        je .notfound
        cmp al, byte [KEYS_CODES + ebx]
        je .found
        inc ebx
        jmp .asciiLoop
    .notfound:
        mov bl, 0
        ret
    .found:
        mov bl, byte [KEYS_ASCII + ebx + edx]
        ret
    .space:
        mov bl, ' '
        ret

;**************************************************;
;	MoveCur ()
;		- Update hardware cursor
;	parm/ bh = Y pos
;	parm/ bl = x pos
;**************************************************;

bits 32

MoveCur:

	pusha				; save registers (aren't you getting tired of this comment?)
	;-------------------------------;
	;   Get current position        ;
	;-------------------------------;

	; Here, PutX and PutY are relitave to the current position on screen, not in memory.
	; That is, we don't need to worry about the byte alignment we do when displaying characters,
	; so just follow the forumla: location = PutX + PutY * COLS

	xor	eax, eax
	mov	ecx, COLS
    mov byte [CurX], bl
    mov byte [CurY], bh
	mov	al, bh			; get y pos
	mul	ecx             ; multiply y*COLS
	add	al, bl			; Now add x
	mov	ebx, eax

	;--------------------------------------;
	;   Set low byte index to VGA register ;
	;--------------------------------------;

	mov	al, 0x0f
	mov	dx, 0x03D4
	out	dx, al

	mov	al, bl
	mov	dx, 0x03D5
	out	dx, al			; low byte

	;---------------------------------------;
	;   Set high byte index to VGA register ;
	;---------------------------------------;

	xor	eax, eax

	mov	al, 0x0e
	mov	dx, 0x03D4
	out	dx, al

	mov	al, bh
	mov	dx, 0x03D5
	out	dx, al			; high byte

	popa
	ret

;**************************************************;
;	ClrScr32 ()
;		- Clears screen
;**************************************************;

bits 32

ClrScr:

	pusha
	cld
	mov	edi, VIDMEM
	mov	cx, 2000
	mov	ah, [CHAR_ATTRIB]
	mov	al, ' '
	rep	stosw
	mov	byte [PutX], 0
	mov	byte [PutY], 0
	popa
	ret

;**************************************************;
;	GotoXY ()
;		- Set current X/Y location
;	parm\	AL=X position
;	parm\	AH=Y position
;**************************************************;

bits 32

GotoXY:
	pusha
	mov	byte [PutX], bl		; just set the current position
	mov	byte [PutY], bh
    call MoveCur
	popa
	ret

BackSpace:
    mov bl, byte [PutX]
    sub bl, 1
    mov bh, byte [PutY]
    call GotoXY
    printC 0
    mov bl, byte [PutX]
    sub bl, 1
    mov bh, byte [PutY]
    call GotoXY
    ret

Scroll:
    pusha
    mov bl, byte [CHAR_ATTRIB]
    mov esi, VIDMEM
    mov dl, 2       ; edx = cols * 2
    mov al, COLS
    mul dl
    mov dl, al
    xor eax, eax
    mov cl, 1       ; cl = y
    .loop:
        mov al, byte [esi+edx]
        mov byte [esi+edx], ' '
        mov byte [esi], al
        add esi, 2
        inc ch
        cmp ch, COLS
        je .nextY
        jmp .loop
    .nextY:
        inc cl
        cmp cl, LINES
        jl .loop
    .done:
        dec byte [PutY]
        popa
        ret




