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
; System calls - assembly parts
;------------------------------------------------------------
    include "../shared/equates.S"

TRAP_15_VECTOR      equ     $bc
TRAP_15_VECTOR_ADDR equ     TRAP_15_VECTOR*4

; TRAP 15 provides access to Easy68K-compatible tasks
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See README for details.
EASY68K_TRAP_15_HANDLER:
;TODO use a jump table...
    cmp.l   #0,D0                       ; FC == 0?
    bsr.w   PRINTLN_LEN                 ;   PRINTLN_LEN if so...
    cmp.l   #1,D0                       ; FC == 1?
    bsr.w   PRINT_LEN                   ;   PRINT_LEN if so...
    cmp.l   #2,D0                       ; FC == 2?
    bsr.w   READLN_STR                  ;   READLN_STR if so...
    cmp.l   #3,D0                       ; FC == 3?
    bsr.w   DISPLAYNUM_SIGNED           ;   DISPLAYNUM_SIGNED if so...
    cmp.l   #4,D0                       ; FC == 4?
    bsr.w   READLN_NUM                  ;   READLN_NUM if so...
    cmp.l   #5,D0                       ; FC == 5?
    bsr.w   READ_CHAR                   ;   READ_CHAR if so...
    cmp.l   #6,D0                       ; FC == 6?
    bsr.w   SEND_CHAR                   ;   SEND_CHAR if so...
    cmp.l   #7,D0                       ; FC == 7?
    bsr.w   CHECK_RECV                  ;   CHECK_RECV if so...
    cmp.l   #8,D0                       ; FC == 8?
    bsr.w   GET_TICKS                   ;   GET_TICKS if so...
    cmp.l   #9,D0                       ; FC == 9?
    jmp     HALT                        ;   HALT if so...
                                        ; FC == 10 - NOT IMPLEMENTED
    cmp.l   #11,D0                      ; FC == 11?
    bsr.w   MOVE_X_Y                    ;   MOVE_X_Y if so...
    cmp.l   #12,D0                      ; FC == 12?
    bsr.w   SET_ECHO                    ;   SET_ECHO if so...
    cmp.l   #13,D0                      ; FC == 13?
    bsr.w   PRINTLN_SZ                  ;   PRINTLN_SZ if so...
    cmp.l   #14,D0                      ; FC == 14?
    bsr.w   PRINT_SZ                    ;   PRINT_SZ if so...
    cmp.l   #15,D0                      ; FC == 15?
    bsr.w   DISPLAYNUM_UNSIGNED         ;   DISPLAYNUM_UNSIGNED if so...
    cmp.l   #16,D0                      ; FC == 16?
    bsr.w   SET_DISPLAY_OPTS            ;   SET_DISPLAY_OPTS if so...
    cmp.l   #17,D0                      ; FC == 17?
    bsr.w   PRINT_SZ_PRINT_NUM          ;   PRINT_SZ_PRINT_NUM if so...
    cmp.l   #18,D0                      ; FC == 17?
    bsr.w   PRINT_SZ_READ_NUM           ;   PRINT_SZ_READ_NUM if so...
                                        ; FC == 19 - NOT IMPLEMENTED
    cmp.l   #20,D0                      ; FC == 20?
    bsr.w   DISPLAYNUM_SIGNED_WIDTH     ;   DISPLAYNUM_SIGNED_WIDTH if so...
                                        ; FC == 21 - NOT IMPLEMENTED
                                        ; FC == 22 - NOT IMPLEMENTED

    rte                                 ; That's all for now...


* ************************************************************************** *
* ************************************************************************** *
; The individual handlers. Where possible we let called subs handle the return to
; the TRAP handler to save a memory cycle or two...
* ************************************************************************** *
PRINTLN_LEN:
    bsr.s   PRINT_LEN                   ; Print the string...
    lea     SZ_CRLF,A0                  ; Load CRLF...
    bsr.s   EARLY_PRINT                 ; ... and print it
    rts


* ************************************************************************** *
PRINT_LEN:
    move.w  D1,D1                       ; Init CCR
    bra.s   LOOP                        ; Start looping...

.SEND:
    move.w  (A1)+,D0                    ; Get next char and increment A1
    bsr.w   SENDCHAR                    ; Do send...

.LOOP:
    dbra    D1,SEND                     ; Go again?
    rts                                 ; Nope, we're done...


* ************************************************************************** *
READLN_STR:
    move.l  A1,-(A7)                    ; Store buffer start
    move.w  #80,D1                      ; Max len into D1 (and init CCR)
    bra.s   LOOP                        ; Start looping...

.RECV:
    bra.w   RECVCHAR                    ; Receive a character
    cmp.b   #$0D,D0                     ; Is it CR?
    beq.s   .DONE                       ; Done if so, else
    move.b  D0,(A1)+                    ; Store char in buffer and advance

.LOOP:
    dbra    D1,RECV                     ; Go again?

.DONE:
    move.w  #80,D0                      ; Compute length...
    add.w   #1,D1
    sub.w   D1,D0
    move.w  D0,D1                       ; Shuffle around to stay compatible...
    move.l  (A7)+,A1                    ; ... and restore buffer pointer
    rts


* ************************************************************************** *
DISPLAYNUM_SIGNED:
    rts


* ************************************************************************** *
READLN_NUM:
    rts


* ************************************************************************** *
READ_CHAR:
    jmp     RECVCHAR


* ************************************************************************** *
SEND_CHAR:
    jmp     SENDCHAR


* ************************************************************************** *
CHECK_RECV:
    move.b  MFP_RSR,D0                  ; Get RSR
    btst    #7,D0                       ; Is buffer_full bit set?
    bne.s   TRUE                        ; Yes - Go to set true

    move.b  #0,D1                       ; Else no - so false
    rts                                 ; And done.

.TRUE:
    move.b  #1,D1                       ; Set true
    rts                                 ; And done.


* ************************************************************************** *
GET_TICKS:
    move.w  $408,D1                     ; Get (Word-sized!) count from SDB
    rts


* ************************************************************************** *
MOVE_X_Y:
    rts


* ************************************************************************** *
SET_ECHO:
    move.b  D1,ECHO_ON

    rts


* ************************************************************************** *
PRINTLN_SZ:
    jmp     EARLY_PRINTLN


* ************************************************************************** *
PRINT_SZ:
    jmp     EARLY_PRINT


* ************************************************************************** *
DISPLAYNUM_UNSIGNED:
    rts


* ************************************************************************** *
SET_DISPLAY_OPTS:
    cmp.b   #0,D1                       ; Is D1 0?
    beq     PROMPT_OFF                  ;   Prompt disable if so, else...
    cmp.b   #1,D1                       ; Is D1 1?
    beq     PROMPT_ON                   ;   Prompt enable if so, else...
    cmp.b   #2,D1                       ; Is D1 2?
    beq     LF_OFF                      ;   Linefeed disable if so, else...
    cmp.b   #3,D1                       ; Is D1 3?
    beq     LF_ON                       ;   Linefeed enable if so, else...
    rts                                 ; Ignore.

.PROMPT_OFF:
    move.b  0,PROMPT_ON
    rts

.PROMPT_ON
    move.b  1,PROMPT_ON
    rts

.LF_OFF:
    move.b  0,LF_DISPLAY
    rts

.LF_ON:
    move.b  1,LF_DISPLAY
    rts


* ************************************************************************** *
PRINT_SZ_PRINT_NUM:
    rts


* ************************************************************************** *
PRINT_SZ_READ_NUM:
    rts


* ************************************************************************** *
DISPLAYNUM_SIGNED_WIDTH:
    rts


* ************************************************************************** *
* ************************************************************************** *
; Called to install the TRAP handlers
* ************************************************************************** *
INSTALL_EASY68K_TRAP_HANDLERS::
    move.l  EASY_68K_TRAP_15_HANDLER,TRAP_15_VECTOR
    rts


* ************************************************************************** *
* ************************************************************************** *
; Options
* ************************************************************************** *
ECHO_ON         dc.b        1
PROMPT_ON       dc.b        1
LF_DISPLAY      dc.b        1
