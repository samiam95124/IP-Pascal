                title   'IBM PC system routines'
                name    pixel
                page    55,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; IBM PC SPECIFIC SYSTEM ROUTINES                             ;
;                                                             ;
; Contains various system routines.                           ;
; To avoid various DOS oddities, the lowest level             ;
; implementation as possible is used.                         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                .386
                .model  small, c

                .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CONVERT WORD                                                ;
;                                                             ;
; Converts one word to another. Simply for type convertion.   ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

convert proc    syscall x: word
        mov     ax,x            ; get the word
        ret                     ; exit
convert endp

        end
