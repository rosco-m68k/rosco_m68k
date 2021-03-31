;
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v1
; ------------------------------------------------------------
; Copyright (c)2021 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; C Exception Handling example
; ------------------------------------------------------------
;

    section .text

; This is the stub exception handler. It saves registers and 
; sets up a pointer to the stacked CPU data for the C handler
; to take as an argument, then calls the handler.
BERR_HANDLER:
    movem.l D0-D1/A0-A1,-(A7)
    lea     16(A7),A0
    move.l  A0,-(A7)
    jsr     berr_handler_c
    addq.l  #4,A7
    movem.l (A7)+,D0-D1/A0-A1
    rte


; Convenience function to install our handler
INSTALL_HANDLER::
    move.l  $8,saved
    move.l  #BERR_HANDLER,$8
    rts


; Convenience function to restore the original handler
UNINSTALL_HANDLER::
    move.l  saved,$8
    rts

    section .data
saved   ds.l    1
 
