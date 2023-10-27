;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; TRAP #14 handler and extended function wrappers
;
; TRAP 14 provides access to some of the basic functionality
; of the firmware after the bootloader has terminated.
;
; D1 is expected to contain the function code. Other arguments
; depend on the specific function - See README for details.
;------------------------------------------------------------

    include "rosco_m68k_public.asm"

    section .text

; This is the exception handler...
TRAP_14_HANDLER::
    move.l  A1,-(A7)
    move.l  D1,-(A7)

    cmp.l   #16,D1                      ; Is function code in range?
    bhi.s   .EPILOGUE                   ; Nope, leave...

    add.l   D1,D1                       ; Multiply FC...
    add.l   D1,D1                       ; ... by 4...
    move.l  .JUMPTABLE(PC,D1),A1        ; ... and calc offset into table...
    jmp     (A1)                        ; ... then jump there

.JUMPTABLE:
    dc.l    .PRINT                      ; FC == 0  ; PRINT if so...
    dc.l    .PRINTLN                    ; FC == 1  ; PRINTLN if so...
    dc.l    .SENDCHAR                   ; FC == 2  ; SENDCHAR if so...
    dc.l    .RECVCHAR                   ; FC == 3  ; RECVCHAR if so...
    dc.l    .PRINTCHAR                  ; FC == 4  ; PRINTCHAR if so...
    dc.l    .SETCURSOR                  ; FC == 5  ; SETCURSOR if so...
    dc.l    .CHECKCHAR                  ; FC == 6  ; CHECKCHAR if so...
    dc.l    .CHECK_DEV_SUPPORT          ; FC == 7  ; CHECK_DEV_SUPPORT if so...
    dc.l    .GET_DEVICE_COUNT           ; FC == 8  ; GET_DEVICE_COUNT if so...
    dc.l    .GET_DEVICE                 ; FC == 9  ; GET_DEVICE if so...
    dc.l    .ADD_DEVICE                 ; FC == 10 ; ADD_DEVICE if so...
    dc.l    .DEV_RECVCHAR               ; FC == 11 ; DEV_RECVCHAR if so...
    dc.l    .DEV_SENDCHAR               ; FC == 12 ; DEV_SENCCHAR if so...
    dc.l    .DEV_CHECKCHAR              ; FC == 13 ; DEV_CHECKCHAR if so...
    dc.l    .EPILOGUE                   ; FC == 14 ; RESERVED
    dc.l    .EPILOGUE                   ; FC == 15 ; RESERVED
    dc.l    .DEV_CTRL                   ; FC == 16 ; DEV_CTRL if so...
    
.EPILOGUE
    move.l  (A7)+,D1
    move.l  (A7)+,A1
    rte                                 ; That's all for now...


.PRINT
    move.l  EFP_PRINT,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.PRINTLN
    move.l  EFP_PRINTLN,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.SENDCHAR
    move.l  EFP_SENDCHAR,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.RECVCHAR
    move.l  EFP_RECVCHAR,A1
    jsr     (A1)
    bra.s   .EPILOGUE
    
.PRINTCHAR
    move.l  EFP_PRINTCHAR,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.SETCURSOR
    move.l  EFP_SETCURSOR,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.CHECKCHAR
    move.l  EFP_CHECKCHAR,A1
    jsr     (A1)
    bra.s   .EPILOGUE

.CHECK_DEV_SUPPORT
    move.l  #$1234FEDC,D0
    bra.s   .EPILOGUE

.GET_DEVICE_COUNT
    move.w  DEVICE_COUNT,D0
    bra.s   .EPILOGUE

; **********************************
.GET_DEVICE
    cmp.w   DEVICE_COUNT,D0
    bhs.s   .NO_DEVICE

    lea.l   DEVICE_BLOCKS,A1
    lsl.w   #5,D0
    add.w   D0,A1

    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+

    move.b  #1,D0
    bra.s   .EPILOGUE

.NO_DEVICE
    clr.b   D0
    bra.s   .EPILOGUE
; **********************************

.ADD_DEVICE
    move.w  DEVICE_COUNT,D0
    cmp.w   #15,D0
    bhi.w   .EPILOGUE

    lea.l   DEVICE_BLOCKS,A1
    lsl.w   #5,D0
    add.w   D0,A1

    ; Copy 32 bytes of device struct
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+

    addi.w  #1,DEVICE_COUNT
    lsr.w   #5,D0               ; Re-shift for return value

    bra.w   .EPILOGUE

; **********************************

.DEV_RECVCHAR
    move.l  8(A0),A1
    jsr     (A1)
    bra.w   .EPILOGUE

.DEV_SENDCHAR
    move.l  12(A0),A1
    jsr     (A1)
    bra.w   .EPILOGUE

.DEV_CHECKCHAR
    move.l  4(A0),A1
    jsr     (A1)
    bra.w   .EPILOGUE

.DEV_CTRL
    move.l  24(A0),A1
    jsr     (A1)
    bra.w   .EPILOGUE


; Wraps FW_PRINT so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINT_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINT                  ; Call FW_PRINT

; Wraps FW_PRINTLN so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
;
; It's cheaper size-wise to just duplicate this here...
FW_PRINTLN_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINTLN                ; Call FW_PRINTLN

; Firmware PRINT null-terminated string pointed to by A0
; Uses PRINT function pointed to by EFP table
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINT::
    move.l  A1,-(A7)
    move.l  EFP_PRINT,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts
    
; PRINT null-terminated string pointed to by A0 followed by CRLF.
; Uses PRINTLN function pointed to by EFP table
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINTLN::
    move.l  A1,-(A7)
    move.l  EFP_PRINTLN,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; PRINT a single character contained in D0.
; Uses PRINTCHAR function pointed to by EFP table.
;
; Modifies: Nothing
FW_PRINTCHAR::
    move.l  A1,-(A7)
    move.l  EFP_PRINTCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Move cursor to X,Y coordinates contained in D1.W.
; High byte is X, low byte is Y.
; Uses PRINTCHAR function pointed to by EFP table.
;
; Modifies: Nothing
FW_MOVEXY::
    move.l  A1,-(A7)
    move.l  EFP_MOVEXY,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Clear the screen.
; Uses CLRSCR function pointed to by EFP table.
;
; Modifies: Nothing
FW_CLRSCR::
    move.l  A1,-(A7)
    move.l  EFP_CLRSCR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts
