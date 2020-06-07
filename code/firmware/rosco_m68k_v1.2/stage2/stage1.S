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
; Call-backs from stage 2 to stage 1. Relies on undocumented
; usage of the reseved SDB bytes. Not guaranteed to work once
; stage 2 is done!
;------------------------------------------------------------
    section .text

; Wraps EARLY_PRINT so it can be called from C-land
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
;
; It's cheaper size-wise to just duplicate this here...
EARLY_PRINT_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bsr.s   EARLY_PRINT               ; Call EARLY_PRINT
    rts                               ; We're done.

; PRINT null-terminated string pointed to by A0
;
; Only used during early init; Buffered serial driver will take
; over the UART later on...
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINT::
    move.l  A1,-(A7)
    move.l  $410,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts
    
; PRINT null-terminated string pointed to by A0 followed by CRLF.
;
; Only used during early init; Buffered serial driver will take
; over the UART later on...
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINTLN::
    move.l  A1,-(A7)
    move.l  $414,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts
     
HALT::
    move.l  A1,-(A7)
    move.l  $418,A1
    jmp     (A1)
    move.l  (A7)+,A1
    rts
