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

; This is the stub exception handler. It does nothing more that
; JSR to our C exception handler. It's needed to make the stack
; behave as GCC expects.
BERR_HANDLER:
    jsr     berr_handler_c
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
 
