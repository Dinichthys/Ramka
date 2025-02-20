.model tiny
.186
.code
locals ww
org 100h

VIDEOSEG        equ 0b800h
TOP_GAP         equ 3h
LEFT_GAP        equ 3h

END_TEXT        equ 0Dh

TERMINAL_LENGTH equ 50h
TERMINAL_HEIGHT equ 19h

ARGC_INDEX      equ 80h

ARGV_INDEX      equ 82h

SEP_CHAR        equ ' '         ; 32h = ' '
END_SYM         equ 0Dh         ; 0Dh = '\r'

SHADOW_BIT      equ 00000111

;----------MAIN-------------------
Main:
        call GetArgs                    ; format: len height 'base' color (binary) 'string'
                                        ; ramka.com 20 10 123456789 01001111 Roflan Privet

        push bx
        call SetVideoseg
        pop bx

        call MakeFrame

        mov ax, 4c00h
        int 21h         ; exit

;---------------------------------

;-----------FUNCTIONS-------------

;---------------------------------
; The function used ARGV
; and set it to registers
;
; Entry:  ARGC_INDEX, ARGV_INDEX, SEP_CHAR
; Exit:   AH, AL, BX, DX, CS:FRAME_COLOR
; Destrs: CX
;---------------------------------

GetArgs     proc

        mov al, byte ptr ds:[ARGC_INDEX]

        cmp al, 0h
        je wwError

        mov bx, ARGV_INDEX

        call StoI
        push ax

        call StoI
        push ax

        push bx

        add bx, 09h
        call SkipSpace

        call StoB
        mov cs:Frame_color, al

        mov dx, bx

        pop bx

        pop ax
        mov ah, al
        pop cx
        mov al, cl

        call SetCoordinates

        ret

wwError:
        call ErrorHandle

        ret
endp

;--------------------------------


;---------------------------------
; String [BX] to number AL
;
; Entry:  BX, SEP_CHAR
; Exit:   AX
; Destrs: CX, BX (skip number with space after it)
;---------------------------------

StoI     proc

        mov ax, 0h
        mov ch, 0h
wwCond:
        mov cl, byte ptr [bx]
        cmp cl, SEP_CHAR
        je wwEnd

wwFor:
        imul ax, ax, 0Ah                ; ax = ax * 10
        sub cl, '0'
        add ax, cx
        inc bx

        jmp wwCond

wwEnd:
        call SkipSpace

        ret

endp

;--------------------------------


;---------------------------------
; String [BX] to number AL (byte in binary)
;
; Entry:  BX, SEP_CHAR
; Exit:   AX
; Destrs: CX, BX (skip number with space after it)
;---------------------------------

StoB     proc

        mov ax, 0h
        mov ch, 0h
wwCond:
        mov cl, byte ptr [bx]
        cmp cl, SEP_CHAR
        je wwEnd

wwFor:
        shl ax, 01h
        sub cl, '0'
        add ax, cx
        inc bx

        jmp wwCond

wwEnd:
        call SkipSpace

        ret

endp

;--------------------------------


;---------------------------------
; Skip spaces in [BX]
;
; Entry:  BX, SEP_CHAR
; Exit:   None
; Destrs: CX, BX (skip spaces)
;---------------------------------

SkipSpace     proc

wwCond:
        mov cl, byte ptr [bx]
        cmp cl, SEP_CHAR
        jne wwEnd

wwWhile:
        inc bx

        jmp wwCond

wwEnd:

        ret

endp

;--------------------------------


;---------------------------------
; Set coordinates to CX (CL - x, CH - y)
; from size in AX (AL - length, AH - height)
;
; Entry:  AX
; Exit:   CX
; Destrs: None
;---------------------------------

SetCoordinates     proc

    push ax

    shr al, 01h
    shr ah, 01h

    mov cl, TERMINAL_LENGTH
    shr cl, 01h
    mov ch, TERMINAL_HEIGHT
    shr ch, 01h

    sub cl, al
    sub ch, ah

    pop ax

    ret

endp

;--------------------------------


;---------------------------------
; The function used VIDEOSEG
; and set it to es
;
; Entry:  VIDEOSEG
; Exit:   None
; Destrs: BX
;---------------------------------

SetVideoseg     proc

    mov bx, VIDEOSEG
    mov es, bx
    ret

endp

;--------------------------------


;---------------------------------
; Draw the frame with text
;
; Entry:  ES, AH, AL, BX, CX, DX, CS:FRAME_COLOR
; Exit:   None
; Destrs: AX, CX, DI
;---------------------------------

MakeFrame     proc

    mov di, ax

    cmp ah, al
    jb wwLess
    ja wwMore

    mov ah, 01h
    mov al, 01h

wwCond:
    cmp di, ax
    jb wwDone

wwWhile:
    call SetCoordinates
    push dx cx bx ax
    call DrawFrame
    pop ax bx cx
    push cx bx ax
    call DrawShadow
    mov cx, 2h
    mov dx, 0h
    mov ah, 86h
    int 15h
    pop ax bx cx dx
    inc ah
    inc al
    jmp wwCond

wwDone:
    dec ah
    dec al

    call PrintText

    ret

wwLess:
    sub al, ah
    add al, 01h
    mov ah, 01h
    jmp wwCond

wwMore:
    sub ah, al
    add ah, 01h
    mov al, 01h
    jmp wwCond

endp

;--------------------------------


;---------------------------------
; The function draw the frame
; with the text pointed by DX,
; base pointed by BX,
; size in AX (AL - x, AH - y),
; coordinates in CX
; (CL - x, CH - y)
; and color in DL
;
; Entry:  ES, AH, AL, BX, CX, DX, CS:FRAME_COLOR
; Exit:   None
; Destrs: AX, CX, BX
;---------------------------------

DrawFrame     proc

    add ah, ch

    dec ah
    mov cs:Bottom_Coordinates, ah
    mov ah, cs:Frame_color

    call BaseLine
    inc ch

wwCond:
    cmp cs:Bottom_Coordinates, ch
    jbe wwEnd

wwFor:
    call BaseLine
    inc ch
    sub bx, 03h

    jmp wwCond

wwEnd:
    dec ch
    cmp cs:Bottom_Coordinates, ch
    jbe wwStop

    inc ch
    add bx, 03h
    call BaseLine

wwStop:
    ret

endp

;--------------------------------

Bottom_Coordinates db 0h

Frame_color db 0h

;---------------------------------
; The function draw the shadow of the frame
; with size in AX (AL - x, AH - y)
; and coordinates in CX (CL - x, CH - y)
;
; Entry:  ES, AH, AL, CX, CS:FRAME_COLOR
; Exit:   None
; Destrs: AX, BX
;---------------------------------

DrawShadow     proc

    push ax cx

    mov bl, ch
    mov bh, 0h
    inc bx

    imul bx, bx, TERMINAL_LENGTH
    mov ch, 0h
    add bx, cx
    mov ah, 0h
    add bx, ax

    pop cx ax

    shl bx, 01h
    inc bx                              ; bx - point on the right top element of the shadow on the screen

wwCond_Vertical:
    cmp ah, 01h
    jbe wwEnd_Vertical

wwFor_Vertical:
    mov byte ptr es:[bx], SHADOW_BIT
    add bx, TERMINAL_LENGTH * 2
    dec ah
    jmp wwCond_Vertical

wwEnd_Vertical:


wwCond_Horizontal:
    cmp al, 0h
    je wwEnd_Horizontal

wwFor_Horizontal:
    mov byte ptr es:[bx], SHADOW_BIT
    sub bx, 02h
    dec al
    jmp wwCond_Horizontal

wwEnd_Horizontal:

    ret

endp

;--------------------------------


;---------------------------------
; The function draw the line of the frame
; with coordinates in CX (CL - x, CH - y),
; color in AH, length in AL and base in [bx]
;
; Entry:  ES, CH, CL, BX, AH, AL
; Exit:   None
; Destrs: DX, BX (inc x3)
;---------------------------------

BaseLine     proc

    cld

    push dx cx ax

    mov dl, ch
    mov dh, 0h
    imul dx, dx, TERMINAL_LENGTH

    mov al, cl
    mov ah, 0h
    add dx, ax

    pop ax
    push ax
    mov cl, al
    mov ch, 0h

    shl dx, 01h                     ; dx = (ch * 80 + cl) * 2

    mov di, dx

    mov dl, al
    cmp dl, 01h
    jb wwEnd_Half_Len

    mov al, cs:[bx]
    stosw

    cmp dl, 02h
    jb wwEnd_Half_Len

    sub cx, 02h
    inc bx
    mov al, cs:[bx]
    rep stosw

    inc bx
    mov al, cs:[bx]
    stosw

    inc bx

    pop ax cx dx

    ret

wwEnd_Half_Len:
    add bx, 03h
    pop ax cx dx

    ret

endp

;--------------------------------

; -------TEXT---------

;---------------------------------
; Print the text pointed by DX
; to the frame with
; starting coordinates
; CL - x, CH - y
;
; Entry:  ES, DX, CH, CL
; Exit:   None
; Destrs: AX, BX, SI, DI
;---------------------------------

PrintText     proc

    cld

    ; mov bl, ch
    ; mov bh, 0h
    ; add bx, TOP_GAP + 1
    ; imul bx, bx, TERMINAL_LENGTH
    ; mov al, cl
    ; mov ah, 0h
    ; add bx, ax
    ; shl bx, 01h
    ; add bx, LEFT_GAP * 2 + 2            ; bx - index in memory of starting the string
    mov bx, TERMINAL_HEIGHT
    shr bx, 01h
    imul bx, bx, TERMINAL_LENGTH
    mov al, cl
    mov ah, 0h
    add bx, ax
    add bx, LEFT_GAP + 1
    shl bx, 01h

    mov di, bx
    mov si, dx

    push ds
    mov ax, cs
    mov ds, ax
    mov ax, 0h
wwCond:
    cmp byte ptr cs:[si], END_SYM
    je wwEnd
    cmp byte ptr cs:[si], 0Ah          ; \n
    je wwNewLine

wwWhile:
    inc ax
    movsb
    inc di

    jmp wwCond

wwEnd:
    pop ds

    ret

wwNewLine:
    inc si
    add di, TERMINAL_LENGTH * 2
    shl ax, 01h
    sub di, ax
    mov ax, 0h
    jmp wwCond

endp

;--------------------------------


;---------------------------------
; Error message
;
; Entry:  None
; Exit:   None
; Destrs: AH, DX
;---------------------------------

ErrorHandle     proc

        mov dx, offset ErrorMessage
        mov ah, 09h
        int 21h

        mov ax, 4c00h
        int 21h

        ret
endp

;--------------------------------

ErrorMessage: db 'You did not enter arguments for the frame$'

end Main
