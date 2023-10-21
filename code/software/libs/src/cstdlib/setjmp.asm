;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; setjmp/longjmp implementation. 
;
; sizeof(jmp_buf) **must** be 14 dwords, or this'll break...
;------------------------------------------------------------

setjmp::
    clr.l   d0                              ; Set up zero return in d0
    move.l  4(a7),a0                        ; Grab jmp_buf from stack
    add.l   #56,a0                          ; Point to top of it
    move.l  (a7),-(a0)                      ; Stash return address
    move.l  a7,-(a0)                        ; Stash SP
    move.w  sr,-(a0)                        ; Stash SR
    movem.l d2-d7/a2-a6,-(a0)               ; Stash GP regs
    rts                                     ; And done


longjmp::
    move.l  8(a7),d0                        ; Get return value from stack
    move.l  4(a7),a0                        ; And jmp_buf too
    tst.l   d0                              ; Is return value 0?
    bne.s   .nonzero                        ; If not, we're good
    move.l  #1,d0                           ; Otherwise, make it 1, per standard

.nonzero:
    add.l   #2,a0                           ; Skip unused word in jmp_buf
    movem.l (a0)+,d2-d7/a2-a6               ; Restore GP regs
    move.w  (a0)+,sr                        ; Restore SR
    move.l  (a0)+,a7                        ; Restore SP
    move.l  (a0)+,(a7)                      ; Replace return address with stored one
    rts                                     ; And return (from setjmp)
