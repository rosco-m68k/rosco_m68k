;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is low-level UART stuff and exception handlers for the
; MC68901 serial driver.
;------------------------------------------------------------
    include "../../../shared/rosco_m68k_public.asm"
    include "../stage1/rosco_m68k_private.asm"

    section .text

; TODO Fix these for r2x, or remove them!
; Enable the transmitter
ENABLE_XMIT::
    ifd REVISION1X
    bset.b  #0,MFP_TSR
    endif
    rts

; Disable the transmitter
DISABLE_XMIT::
    ifd REVISION1X
    bclr.b  #0,MFP_TSR
    endif
    rts

; Enable the receiver
ENABLE_RECV::
    ifd REVISION1X
    bset.b  #0,MFP_RSR
    endif 
    rts

; Disable the receiver
DISABLE_RECV::
    ifd REVISION1X
    bclr.b  #0,MFP_RSR
    endif
    rts

