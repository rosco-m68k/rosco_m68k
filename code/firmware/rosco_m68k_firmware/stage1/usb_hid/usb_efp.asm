;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|          firmware
;------------------------------------------------------------
; Copyright (c)2024 The rosco_m68k OSP
; See top-level LICENSE.md for licence information.
;
; EFP handlers for USB HID keyboard
;------------------------------------------------------------

    include "../../../shared/rosco_m68k_public.asm"

    section .text

INSTALL_USB_HID_HANDLERS::
    move.l  #.USB_HID_CHECK,EFP_CHECKINPUT
    move.l  #.USB_HID_INPUT,EFP_INPUTCHAR
    rts

.USB_HID_CHECK:
    movem.l D1/A0-A1,-(A7)
    jsr     usb_input_keyboard_check_char
    movem.l (A7)+,D1/A0-A1
    rts
    
.USB_HID_INPUT:
    movem.l D1/A0-A1,-(A7)
    jsr     usb_input_keyboard_recv_char
    movem.l (A7)+,D1/A0-A1
    rts


