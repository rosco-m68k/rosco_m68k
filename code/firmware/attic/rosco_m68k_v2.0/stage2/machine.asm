;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; System call implementations 
;------------------------------------------------------------

    section .text

; Call the PRINT function of the firmware
;
; Trashes: MFP_UDR
; Modifies: Nothing
mcPrint::
    movem.l D0-D1/A0,-(A7)            ; Save regs
    move.l  (16,A7),A0                ; Get C char* from the stack into A0
    move.l  #0,D1                     ; Func code is 0
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1/A0            ; Restore regs
    rts                               ; We're done.

; Busywait for a while...
; 
; Trashes: D0
; Modifies: Nothing
mcBusywait::
    move.l  (4,A7),D0                 ; Get long delay from the stack into D0
.BUSYWAIT
    sub.l   #1,D0                     ; Keep decrementing D0...
    tst.l   D0                        ;  ... until it's zero...
    bne.s   .BUSYWAIT
    
    rts

; Disable interrupts and halt the machine
;
; Trashes: Nothing
; Modifies: Nothing
; Notes: No return
mcHalt::
    stop    #$2700
    bra.s   mcHalt

