;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2024 Ross Bamford and contributors
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

    include "../../../shared/rosco_m68k_public.asm"

    section .text

; This is the exception handler...
TRAP_14_HANDLER::
    move.l  A1,-(A7)
    move.l  D1,-(A7)

    cmp.l   #18,D1                      ; Is function code in range?
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
    dc.l    .DEV_SENDCHAR               ; FC == 12 ; DEV_SENDCHAR if so...
    dc.l    .DEV_CHECKCHAR              ; FC == 13 ; DEV_CHECKCHAR if so...
    dc.l    .EPILOGUE                   ; FC == 14 ; RESERVED
    dc.l    .EPILOGUE                   ; FC == 15 ; RESERVED
    dc.l    .DEV_CTRL                   ; FC == 16 ; DEV_CTRL if so...
    dc.l    .INPUTCHAR                  ; FC == 17 ; INPUTCHAR if so...
    dc.l    .CHECKINPUT                 ; FC == 18 ; CHECKINPUT if so...
    
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
    jsr     GET_CHAR_DEVICE_COUNT
    bra.s   .EPILOGUE

; **********************************
.GET_DEVICE
    jsr     GET_CHAR_DEVICE
    bra.s   .EPILOGUE
; **********************************

.ADD_DEVICE
    jsr     ADD_CHAR_DEVICE
    bra.w   .EPILOGUE

; **********************************

.DEV_RECVCHAR
    jsr     CHAR_DEV_RECVCHAR
    bra.w   .EPILOGUE

.DEV_SENDCHAR
    jsr     CHAR_DEV_SENDCHAR
    bra.w   .EPILOGUE

.DEV_CHECKCHAR
    jsr     CHAR_DEV_CHECKCHAR
    bra.w   .EPILOGUE

.DEV_CTRL
    jsr     CHAR_DEV_CTRL
    bra.w   .EPILOGUE

.INPUTCHAR
    move.l  EFP_INPUTCHAR,A1
    jsr     (A1)
    bra.w   .EPILOGUE
    
.CHECKINPUT
    move.l  EFP_CHECKINPUT,A1
    jsr     (A1)
    bra.w   .EPILOGUE


; Wraps FW_PRINT so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINT_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    ; Fall through to FW_PRINT

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

; Wraps FW_PRINTLN so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINTLN_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    ; Fall through to FW_PRINTLN

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

; Wraps FW_PRINTCHAR so it can be called from C-land
;
; Modifies: D0 (Will hold the printed character)
FW_PRINTCHAR_C::
    move.l  (4,A7),D0                 ; Get C char from the stack into D0
    ; Fall through to FW_PRINTCHAR

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

; Wraps FW_SENDCHAR so it can be called from C-land
;
; Modifies: D0 (Will hold the sent character)
FW_SENDCHAR_C::
    move.l  (4,A7),D0                 ; Get C char from the stack into D0
    ; Fall through to FW_SENDCHAR

; Send a single character via UART
;
; Trashes: Nothing
; Modifies: Nothing
FW_SENDCHAR::
    move.l  A1,-(A7)
    move.l  EFP_SENDCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Wraps FW_RECVCHAR so it can be called from C-land
;
; Modifies: D0 (return)
FW_RECVCHAR_C::
    ; Fall through to FW_RECVCHAR

; Receive a single character via UART.
; Ignores overrun errors.
;
; Trashes: Nothing
; Modifies: D0 (return)
FW_RECVCHAR::
    move.l  A1,-(A7)
    move.l  EFP_RECVCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Wraps FW_CLRSCR so it can be called from C-land
;
; Modifies: Nothing
FW_CLRSCR_C::
    ; Fall through to FW_CLRSCR

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

; Wraps FW_MOVEXY so it can be called from C-land
;
; Modifies: D1 (Will hold the argument)
FW_MOVEXY_C::
    move.l  (4,A7),D1                 ; Get C uint16_t from the stack into D1
    ; Fall through to FW_MOVEXY

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
