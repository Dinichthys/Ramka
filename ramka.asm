.model tiny
.186
.code
locals ww
org 100h

VIDEOSEG    equ 0b800h

;----------MAIN-------------------
Main:
        call SetVideoseg

        mov ah, 0Ah                     ; 10 * 10  | AL - x | AH - y |
        mov al, 0Ah                     ;
        mov dx, offset String           ; Text in dx
        mov bx, offset Base             ; Base of the Frame in bx

        call DrawFrame

        call PrintText

        mov ax, 4c00h
        int 21h         ; exit

;---------------------------------

;--------------DATA---------------

String: db 'Enter the text$'

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

        mov cl, 50h             ; 50h = 80
        sub cl, al
        shr cl, 01h
        sub cl, 01h
        add al, cl
        dec al

        mov ch, 19h             ; 19h = 25
        sub ch, ah
        shr ch, 01h
        sub ch, 01h
        add ah, ch
        dec ah

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

        pop dx

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
        imul bx, bx, 50h
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
        mov cl, 4Eh
        sub cl, ch
        sub cl, 01h
        cmp dh, cl
        pop cx
        je wwFor_end

wwFor:
        inc cl
        mov dl, [bx]
        push bx
        mov bl, ch
        mov bh, 0h
        imul bx, bx, 50h
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
        imul bx, bx, 50h
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

end Main
