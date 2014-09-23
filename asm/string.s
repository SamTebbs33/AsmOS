;--------------------------------------------------;
; String library
;
;   Functions for the manipulation of null-terminated strings
;
;   * StrCmp(str1 esi, str2 edi) -> bool bl
;       - Checks if the two strings are equal
;   * StrLen(str edi) -> bl length
;       - Computes the length of string starting at address str1
;	* StrCopy(str edi, dest esi)
;       - Copies the str to the address
;	* StrAppend(str1 edi, str2 esi)
;       - Appends str2 to the end of str1
;	* StrClear(str edi)
;       - Clears the string
;	* StrSetCh(str1 esi, ch bl, int eax)
;       - Sets the character at int of str to ch
;	* StrSetLast(str1 esi, ch bl)
;       - Sets the last character to ch
;	* StrTrim(str edi)
;       - Trims the trailing spaces off the end of the string
;	* StrLower(str edi)
;       - Converts the string to lower case
;	* StrUpper(str edi)
;       - Converts the string to upper case
;	* StrSplit(str edi, char bl)
;       - Splits the string by the char
;       - Stores resulting lengths in SplitStrsLen
;       - Stores resulting strings in SplitStrs
;--------------------------------------------------;

;**************************************************;
;   StrCmp(str1 esi, str2 edi) -> carry
;   Checks if the two strings are equal
;**************************************************;

MsgIs: db "Is", 0x00

StrCmp:
    xor edx, edx
    .loop:
        mov al, [esi + edx]
        mov bl, [edi + edx]
        inc edx
        cmp al, bl
        jne .notEqual
        cmp al, 0
        je .equal
        jmp .loop
    .notEqual:
        clc
        ret
    .equal:
        stc
        ret

;**************************************************;
;	StrLen(str edi) -> bl length
;   Computes the length of string starting at address str1
;**************************************************;

StrLen:
    sub ecx, ecx    ; Set ecx to 0
    sub al, al      ; Set al to 0, scasb will now look for 0
    not ecx         ; Set ecx to 4,294,967,295
    cld
    repne scasb     ; Goes from EDI and looks for 0
    not ecx
    dec ecx         ; Length is now in ecx
    mov bl, cl
    ret

;**************************************************;
;	StrCopy(str edi, dest esi)
;   Copies the str to the address
;**************************************************;

StrCopy:
    pusha
    cmp byte [edi], 0
    je .done
    .loop:
        mov eax, [edi]          ; Move val at edi to eax
        mov [esi], eax          ; Mov eax to
        cmp byte [eax], 0
        je .done
        inc esi
        inc edi
        jmp .loop
    .done:
        popa
        ret

;**************************************************;
;	StrAppend(str1 edi, str2 esi)
;   Appends str2 to the end of str1
;**************************************************;

StrAppend:
    pusha
    .loop:
        mov eax, [edi]
        cmp eax, 0
        je .done
        inc esi
        jmp .loop
    .done:
        call StrCopy
        popa
        ret

;**************************************************;
;	StrAppendCh(str1 edi, ch bl)
;   Appends ch to the end of str1
;**************************************************;

StrAppendCh:
    pusha
    .loop:
        mov eax, [esi]
        cmp eax, 0
        je .done
        inc esi
        jmp .loop
    .done:
        mov byte [esi], bl
        mov byte [esi+1], 0
        popa
        ret

;**************************************************;
;	StrSetCh(str1 esi, ch bl, int eax)
;   Sets the character at int of str to ch
;**************************************************;

StrSetCh:
    mov byte [esi+eax], 0
    ret

;**************************************************;
;	StrSetLast(str1 esi, ch bl)
;   Sets the last character to ch
;**************************************************;

StrSetLast:
    pusha
    xor eax, eax
    .loop:
        mov eax, [esi]
        cmp eax, 0
        je .found
        inc esi
        jmp .loop
    .found:
        dec esi
        mov [esi], bl
        popa
        ret

;**************************************************;
;	StrClear(str edi)
;   Clears the string
;**************************************************;

StrClear:
    pusha
    .loop:
        mov eax, [edi]
        cmp eax, 0
        je .done
        mov byte [edi], 0
        inc edi
        jmp .loop
    .done:
        popa
        ret

;**************************************************;
;	StrTrim(str edi)
;   Trims the trailing spaces off the end of the string
;**************************************************;

StrTrim:
    pusha
    xor ebx, ebx
    mov esi, edi            ; move address to esi
    call StrLen
    cmp bl, 0               ; if length is 0, return
    je .done
    dec bl                  ; decrease the length and add to esi in order to start at end of string
    add esi, ebx
    .loop:
        cmp esi, edi        ; if at the beginning of the string, return
        je .done
        mov eax, [esi]      ; if the character at esi is not a space, return
        cmp eax, ' '
        jne .done
        mov byte [esi], 0   ; set the character to a 0
        dec esi             ; move to previous character
        jmp .loop
    .done:
        popa
        ret

;**************************************************;
;	StrLower(str edi)
;   Converts the string to lower case
;**************************************************;

StrLower:
    pusha
    .loop:
        mov al, byte [edi]
        cmp al, 0
        je .done
        cmp al, 64
        jg .greater
        inc edi
        jmp .loop
        .greater:
            cmp al, 90
            jg .retLoop
            add al, 32
            mov byte [edi], al
        .retLoop:
            inc edi
            jmp .loop
    .done:
        popa
        ret

;**************************************************;
;	StrUpper(str edi)
;   Converts the string to upper case
;**************************************************;

StrUpper:
    pusha
    .loop:
        mov al, byte [edi]
        cmp al, 0
        je .done
        cmp al, 96
        jg .greater
        inc edi
        jmp .loop
        .greater:
            cmp al, 122
            jg .retLoop
            sub al, 32
            mov byte [edi], al
        .retLoop:
            inc edi
            jmp .loop
    .done:
        popa
        ret

;**************************************************;
;	StrSplit(str edi, char bl)
;   Splits the string by the char and returns the 
;   results in SplitStrs and their lengths in SplitStrsLen
;   For example, when splitting "hello there sam" by " "
;   StrSplit = "h", "e", "l", "l", "o", 0, "t", "h", "e", "r", "e", 0, "s", "a", "m"
;   StrSplitLen = 5, 5, 3
;   Delimiters inside speech marks are ingnored
;**************************************************;

StrSplit:
    pusha
    xor al, al              ; al = len (current lenngth of split string)
    xor ah, ah              ; ah = num (current number of split strings)
    xor ecx, ecx            ; ch = [edi] (current char)
                            ; cl = c (counter)
    mov edx, SplitStrs       ; edx = mem (address to store at)
    mov esi, SplitStrsLen    ; esi = memLen (address to store lengths at)
    mov bh, 0xFF               ; bh = add (determines if a string should be added)
    .loop:
        mov ch, byte [edi]  ; if at the end of the string, return
        cmp ch, 0
        je .done

        cmp ch, bl          ; if ch == bl
        jne .noSplit        ; else jump ahead

        cmp bh, 0xFF        ; if bh == FF
        jne .addToStr        ; else jump ahead

        mov byte [esi], al  ; store string length
        mov al, 0
        inc esi             ; increment memLen pointer so it points to the location at which to put lengths
        inc ah              ; increase number
        mov byte [edx], 0   ; end current string
        inc edx             ; increment memory pointer
        jmp .incLoop

    .noSplit:
        cmp ch, '"'
        jne .addToStr
        not bh
        jmp .incLoop
    .addToStr:
        mov byte [edx], ch  ; add char to current string
        inc edx             ; increment memory pointer
        inc al
        cmp bh, 0xFF
    .incLoop:
        inc cl
        cmp cl, 254         ; if current counter exceeds max string length, return
        je .done
        inc edi
        jmp .loop
    .done:
        mov byte [esi], al  ; store new length
        mov byte [edx], 0   ; end current string
        popa
        ret

StrToInt:
    xor eax, eax
    push ecx
    .loop:
        movzx ecx, byte [edi]
        inc edi
        cmp ecx, '0'
        jb .done
        cmp ecx, '9'
        ja .done
        sub ecx, '0'
        imul eax, 10
        add eax, ecx
        jmp .loop
    .done:
        pop ecx
        ret

ClearSplitStrs:
    pusha
    cld
    mov edi, SplitStrsLen
    mov cx, 382
    mov al, 0
    repne stosb
    popa
    ret

SplitStrsLen: db 0
times 127 db 0
SplitStrs: db 0
times 254 db 0

