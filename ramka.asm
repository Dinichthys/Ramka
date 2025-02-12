.model tiny
.186
.code
locals ww
org 100h

VIDEOSEG        equ 0b800h
TOP_GAP         equ 3h
LEFT_GAP        equ 3h

END_TEXT        equ 0Dh

HORIZON_TER     equ 50h
VERTICAL_TER    equ 19h

ARGC_INDEX      equ 80h

ARGV_INDEX      equ 82h

SEP_CHAR        equ ' '         ; 32h = ' '
END_SYM         equ 0Dh         ; 0Dh = '\r'

;----------MAIN-------------------
Main:
        call GetArgs                    ; format: x y 'base' 'string'

        push bx
        call SetVideoseg
        pop bx

        ; mov ah, 0Bh                     ; 10 * 10  | AL - x | AH - y |
        ; mov al, 30h                     ;
        ; mov dx, offset String           ; Text in dx
        ; mov bx, offset Base             ; Base of the Frame in bx

        call DrawFrame

        mov ax, 4c00h
        int 21h         ; exit

;---------------------------------

;--------------DATA---------------

String: db 'I am inside the box', 0Ah, 0Ah, 0Ah, '                 please, help me', END_TEXT

Base: db '@-@|=|@-@'

;---------------------------------

;-----------FUNCTIONS-------------

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
; The function used ARGV
; and set it to registers
;
; Entry:  ARGC_INDEX, ARGV_INDEX, SEP_CHAR
; Exit:   AH, AL, BX, DX
; Destrs: None
;---------------------------------

GetArgs     proc

        mov al, byte ptr ds:[ARGC_INDEX]

wwIf:
        cmp al, 0h
        je wwError

        mov bx, ARGV_INDEX

        call StoI
        push ax

        call StoI
        push ax

        mov cx, bx

wwCond_1:
        mov dl, byte ptr [bx]
        cmp dl, SEP_CHAR
        je wwStopSkipping

wwCond_2:
        cmp dl, END_SYM
        je wwError

wwWhile:
        inc bx

        jmp wwCond_1

wwStopSkipping:

        inc bx
        mov dx, bx

        mov bx, cx

        pop ax
        mov ah, al
        pop cx
        mov al, cl

        ret
wwError:
        call ErrorHandle

        ret
endp

;--------------------------------


;---------------------------------
; String [CX] to number AL
;
; Entry:  BX, SEP_CHAR
; Exit:   AX
; Destrs: CX, BX (skip number with space after it)
;---------------------------------

StoI     proc

        mov al, 0h
        mov ah, 0h
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
        inc bx

        ret

endp

;--------------------------------


;---------------------------------
; The function draw the frame
; with the text pointed by DX
; and base pointed by BX
; and size in AX (AL - x, AH - y)
;
; Entry:  ES, AH, AL, BX, DX
; Exit:   None
; Destrs: CX
;---------------------------------

DrawFrame     proc

        push dx

        mov cl, HORIZON_TER             ; 50h = 80
        sub cl, al
        shr cl, 01h
        add al, cl
        dec al

        mov ch, VERTICAL_TER             ; 19h = 25
        sub ch, ah
        shr ch, 01h
        add ah, ch
        dec ah

        push cx                 ; Save the starting coordinates

        push ax
        call BaseLine
        pop ax
        inc ch

wwCond:
        cmp ah, ch
        je wwEnd

wwFor:
        push ax
        call BaseLine
        pop ax
        inc ch
        sub bx, 03h

        jmp wwCond

wwEnd:

        add bx, 03h
        push ax
        call BaseLine
        pop ax

        pop cx
        pop dx

        push ax
        call PrintText
        pop ax

        ret

endp

;--------------------------------


;---------------------------------
; The function draw the line of the frame
; with coordinates in CX (CL - x, CH - y)
;
; Entry:  ES, CH, CL, BX, WIDTH_STR
; Exit:   None
; Destrs: AX, DX, BX (inc x3)
;---------------------------------

BaseLine     proc

        mov dl, [bx]
        push bx
        mov bl, ch
        mov bh, 0h
        imul bx, bx, HORIZON_TER
        mov al, cl
        mov ah, 0h
        add bx, ax
        shl bx, 01h                     ; bx = (ch * 80 + cl) * 2
        mov byte ptr es:[bx], dl
        pop bx

        mov dh, cl
        inc bx

wwCond:
        push cx
        mov ch, cl
        mov cl, HORIZON_TER
        dec cl
        dec cl
        sub cl, ch
        sub cl, 01h
        cmp dh, cl                      ; compare gaps from left and right border
        pop cx
        je wwFor_end

wwFor:
        inc cl
        mov dl, [bx]
        push bx
        mov bl, ch
        mov bh, 0h
        imul bx, bx, HORIZON_TER
        mov al, cl
        mov ah, 0h
        add bx, ax
        shl bx, 01h                     ; bx = (ch * 80 + cl) * 2
        mov byte ptr es:[bx], dl
        pop bx

        jmp wwCond

wwFor_end:
        inc bx

        mov dl, [bx]
        push bx
        mov bl, ch
        mov bh, 0h
        imul bx, bx, HORIZON_TER
        mov al, cl
        mov ah, 0h
        add bx, ax
        shl bx, 01h                     ; bx = (ch * 80 + cl) * 2
        mov byte ptr es:[bx], dl
        pop bx

        mov cl, dh
        inc bx

        ret

endp

;--------------------------------


;---------------------------------
; Print the text pointed by DX
; to the frame with
; starting coordinates
; CL - x, CH - y
;
; Entry:  ES, DX, CH, CL
; Exit:   None
; Destrs: AX, BX
;---------------------------------

PrintText     proc

        mov bl, ch
        mov bh, 0h
        add bx, TOP_GAP
        imul bx, bx, HORIZON_TER
        shl bx, 01h
        mov al, cl
        mov ah, 0h
        shl ax, 01h
        add bx, ax                      ; bx - index in memory of starting the string
        add bx, LEFT_GAP * 2

        push si
        mov si, dx

        mov ah, 0h
wwCond:
        cmp byte ptr [si], END_TEXT
        je wwEnd
        cmp byte ptr [si], 0Ah          ; \n
        je wwNewLine

wwWhile:
        inc ah
        mov al, byte ptr [si]
        mov byte ptr es:[bx], al
        add bx, 02h
        inc si

        jmp wwCond

wwEnd:

        pop si
        ret

wwNewLine:
        inc si
        add bx, horizon_ter * 2
        shl ah, 01h
        sub bl, ah
        mov ah, 0h
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

ErrorMessage: db 'You did not print arguments for the frame$'

end Main
