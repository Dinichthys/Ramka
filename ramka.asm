.model tiny
.code
.locals ww
org 100h

VIDEOSEG    equ 0b800h

;----------MAIN-------------------
Main:
        call SetVideoseg

        mov ah, 0Ah                     ; 10 * 5
        mov al, 05h                     ;
        mov dx, offset String           ; Text in dx
        mov bx, offset Base             ; Base of the Frame in bx

        call Frame


        mov ax, 4c00h
        int 21h         ; exit

;---------------------------------

String: db 'Enter the text$'

Base: db '@-@|=|@-@'

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

Frame     proc

        push dx

        mov cl, 50h - al        ; 50h = 80
        shr cl
        add al, cl

        mov ch, 19h - ah         ; 19h = 25
        shr ch
        add ah, ch

        call BaseLine
        inc ch

wwCond_1:
        cmp ah, ch
        je wwEnd_1:

wwFor_1:
        call BaseLine
        inc ch
        sub bx, 03h

        jmp wwCond_1

wwEnd_1:

        add bx, 03h
        call BaseLine

        pop dx

        ret

endp

;--------------------------------


;---------------------------------
; The function draw the frame line
; with coordinates in CX (CL - x, CH - y)
;
; Entry:  ES, CH, CL, BX
; Exit:   None
; Destrs: DX, BX (inc x3)
;---------------------------------

BaseLine     proc

        mov dl, [bx]
        mov byte ptr es:[cl * 2 + ch * 2 * 80], dl

        mov dh, cl
        inc bx

wwCond:
        cmp dh, 80 - cl
        je wwFor_1_end

wwFor:
        inc cl
        mov dl, [bx]
        mov byte ptr es:[cl * 2 + ch * 2 * 80], dl

        jmp wwCond_1

wwFor_end:
        inc bx

        mov dl, [bx]
        mov byte ptr es:[cl * 2 + ch * 2 * 80], dl

        mov cl, dh
        inc bx

        ret

endp

;--------------------------------

end Main
