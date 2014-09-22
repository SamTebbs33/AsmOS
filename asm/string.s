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
;--------------------------------------------------;

;**************************************************;
;   StrCmp(str1 esi, str2 edi) -> carry
;   Checks if the two strings are equal
;**************************************************;

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
