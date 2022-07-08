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
; System call implementations 
;------------------------------------------------------------


; Call the PRINT function of the firmware
;
; Trashes: MFP_UDR
; Modifies: Nothing
    section .text.mcPrint
mcPrint::
    movem.l D0-D1/A0,-(A7)            ; Save regs
    move.l  (16,A7),A0                ; Get C char* from the stack into A0
    move.l  #0,D1                     ; Func code is 0 PRINT
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1/A0            ; Restore regs
    rts                               ; We're done.

; Call the PRINTLN function of the firmware
;
; Trashes: MFP_UDR
; Modifies: Nothing
    section .text.mcPrintln
mcPrintln::
    movem.l D0-D1/A0,-(A7)            ; Save regs
    move.l  (16,A7),A0                ; Get C char* from the stack into A0
    move.l  #1,D1                     ; Func code is 1 PRINTLN
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1/A0            ; Restore regs
    rts                               ; We're done.

; Call the PRINTCHAR function of the firmware
;
; Trashes: MFP_UDR
; Modifies: Nothing
    section .text.mcPrintchar
mcPrintchar::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  (12,A7),D0                ; Get C char from the stack into D0
    move.l  #4,D1                     ; Func code is 4 PRINTCHAR
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.

; Call the SETCURSOR function of the firmware
;
; Trashes:  -
; Modifies: - (does not)
    section .text.mcSetcursor
mcSetcursor::
    move.l  D1,-(A7)                  ; Save regs
    move.l  (8,A7),D0                 ; Get C bool into D0 (0=cursor off/cursor on)
    move.l  #5,D1                     ; Func code is 4 SETCURSOR
    trap    #14                       ; TRAP to firmware
    move.l  (A7)+,D1                  ; Restore regs
    rts                               ; We're done.

; Call the SENDCHAR function of the firmware
;
; Trashes: MFP_UDR
; Modifies: Nothing
    section .text.mcSendchar
mcSendchar::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  (12,A7),D0                ; Get C char from the stack into D0
    move.l  #2,D1                     ; Func code is 2 SENDCHAR
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.

; Call the RECVCHAR function of the firmware
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
    section .text.mcReadchar
mcReadchar::
    move.l  D1,-(A7)                  ; Save regs
    move.l  #3,D1                     ; Func code is 3 RECVCHAR
    trap    #14                       ; TRAP to firmware
    move.l  (A7)+,D1                  ; Restore regs
    rts                               ; We're done.

; Call the CHECKCHAR function of the firmware
;
; Trashes: Nothing (MFP_UDR?)
; Modifies: D0 (return)
    section .text.mcCheckchar
mcCheckchar::
    move.l  D1,-(A7)                  ; Save regs
    move.l  #6,D1                     ; Func code is 6 CHECKCHAR
    trap    #14                       ; TRAP to firmware
    ext.w   D0                        ; extend D0.B return for C
    ext.l   D0
    move.l  (A7)+,D1                  ; Restore regs
    rts                               ; We're done.

; Busywait for a while...
; 
; Trashes: D0
; Modifies: Nothing
    section .text.mcBusywait
mcBusywait::
    move.l  (4,A7),D0                 ; Get C delay count from the stack into D0
.BUSYWAIT
    sub.l   #1,D0                     ; Keep decrementing D0...
    tst.l   D0                        ;  ... until it's zero...
    bne.s   .BUSYWAIT
    
    rts

; Delay for n 10ms timer ticks
; 
; Trashes: D0
; Modifies: Nothing
    section .text.mcDelaymsec10
mcDelaymsec10::
    move.l  (4,A7),D0                 ; Get 10ms delay count from the stack into D0
    add.l   _TIMER_100HZ.w,D0         ; add to current timer counter for time finished
.DELAYWAIT
    cmp.l   _TIMER_100HZ.w,D0         ; compare current time with time finished
    bcc.s   .DELAYWAIT                ;  ... while it's < (unsigned)
    
    rts

; Disable interrupts and return previous priority mask
;
; Trashes: Nothing
; Modifies: D0 (return), SR
    section .text.mcDisableInterrupts
mcDisableInterrupts::
    move.w  SR,D0                       ; Copy current SR into D0
    ori.w   #$0700,SR                   ; Disable all maskable interrupts
    lsr.w   #8,D0                       ; Shift interrupt mask for returning
    andi.b  #$07,D0                     ; Only keep interrupt mask bits
    rts

; Enable interrupts with a new priority mask
;
; Trashes: Nothing
; Modifies: SR
    section .text.mcEnableInterrupts
mcEnableInterrupts::
    movem.l D0-D1,-(A7)                 ; Save regs
    move.l  (12,A7),D0                  ; Get C uint8_t from stack into D0
    lsl.w   #8,D0                       ; Shift interrupt mask to location in SR
    andi.w  #$0700,D0                   ; Only keep interrupt mask bits set in D0
    move.w  SR,D1                       ; Copy current SR into D1
    andi.w  #$F8FF,D1                   ; Mask out existing interrupt mask in D1
    or.w    D0,D1                       ; Set interrupt mask in D1 from D0
    move.w  D1,SR                       ; Update SR from D1
    movem.l (A7)+,D0-D1                 ; Restore regs
    rts

; Disable interrupts and halt the machine
;
; Trashes: Nothing
; Modifies: Nothing
; Notes: No return
    section .text.mcHalt
mcHalt::
    stop    #$2700
    bra.s   mcHalt


; Determine if character device support is in the firmware
;
; Trashes: Nothing
; Modifies: D0 (return - 0 if unsupported, or any other value if supported)
    section .text.mcCheckDeviceSupport
mcCheckDeviceSupport::
    move.l  D1,-(A7)
    move.l  #7,D1
    trap    #14
    cmp.l   #$1234FEDC,D0
    beq.s   .done

    clr.l   D0

.done
    move.l  (A7)+,D1
    rts


; Get character device count from the firmware
;
; Trashes: Nothing
; Modifies: D0 (return)
    section .text.mcGetDeviceCount
mcGetDeviceCount::
    move.l  D1,-(A7)
    move.l  #8,D1
    trap    #14
    move.l  (A7)+,D1
    rts


; Get character device from the firmware
;
; Trashes: D0
; Modifies: A0 (return)
    section .text.mcGetDevice
mcGetDevice::
    move.l  D1,-(A7)
    move.l  8(A7),D0
    move.l  #9,D1
    trap    #14

    ; Despite what the GCC docs seem to say, pointers are also
    ; expected to be returned in D0, and not A0 🤷
    move.l  A0,D0
    move.l  (A7)+,D1
    rts


; Call device check function
;
; Trashes: A0
; Modifies: D0 (return)
    section .text.mcCheckDevice
mcCheckDevice::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    move.l  #12,D1
    trap    #14
    move.l  (A7)+,D1
    rts


; Call device receive function
;
; Trashes: A0
; Modifies: D0 (return)
    section .text.mcReadDevice
mcReadDevice::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    move.l  #10,D1
    trap    #14
    move.l  (A7)+,D1
    rts


; Call device receive function
;
; Trashes: D0, A0
; Modifies: Nothing
    section .text.mcSendDevice
mcSendDevice::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    move.l  12(A7),D0
    move.l  #11,D1
    trap    #14
    move.l  (A7)+,D1
    rts

; Call device add function
;
; Trashes: A0
; Modifies: D0 (return)
    section .text.mcAddDevice
mcAddDevice::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    move.l  #13,D1
    trap    #14
    move.l  (A7)+,D1
    rts


