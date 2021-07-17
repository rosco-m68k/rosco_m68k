; *************************************************************
; Copyright (c) 2020 You (you@youremail.com)
; *************************************************************
;
    section .text                     ; This is normal code

kmain::
    lea.l   HELLO,A0                  ; Get the address of the message
    move.l  A0,-(A7)                  ; Push it on the stack
    jsr     mcPrintln                 ; Call mcPrintln (from the machine lib)
    addq.l  #4,A7                     ; Clean up the stack (important!)
    rts                               ; And return

                                      ; At this point, the machine will reboot.
                                      ; Don't return from kmain if you don't want
                                      ; to reboot the machine!

HELLO   dc.b    "Hello, world! 😃", 0 ; Our message 
