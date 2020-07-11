;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2019 Ross Bamford
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

    include "equates.S"

    section .text

; This is the exception handler...
TRAP_14_HANDLER::
    cmp.l   #0,D1                     ; FC == 0?
    beq.s   .PRINT                    ;   PRINT if so...
    cmp.l   #1,D1                     ; FC == 1?
    beq.s   .PRINTLN                  ;   PRINTLN if so...
    cmp.l   #2,D1                     ; FC == 2?
    beq.s   .SENDCHAR                 ;   SENDCHAR if so...
    cmp.l   #3,D1                     ; FC == 3?
    beq.s   .RECVCHAR                 ;   RECVCHAR if so...
    rte                               ; That's all for now...

.PRINT
    move.l  A1,-(A7)
    move.l  EFP_PRINT,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte

.PRINTLN
    move.l  A1,-(A7)
    move.l  EFP_PRINTLN,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte

.SENDCHAR
    move.l  A1,-(A7)
    move.l  EFP_SENDCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte

.RECVCHAR
    move.l  A1,-(A7)
    move.l  EFP_RECVCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte
    
; Wraps FW_PRINT so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
FW_PRINT_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINT                  ; Call EARLY_PRINT

; Wraps FW_PRINTLN so it can be called from C-land
;
; Modifies: A0 (Will point to address after null terminator)
;
; It's cheaper size-wise to just duplicate this here...
FW_PRINTLN_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINTLN                ; Call EARLY_PRINT

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
