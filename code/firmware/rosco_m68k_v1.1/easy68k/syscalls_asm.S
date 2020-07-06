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
; Easy68K-compatible system calls - assembly parts
;
; Note that when compiled in this code reserves an SDB
; DWORD for configuration at 0x410.
;------------------------------------------------------------
    include "../../../shared/equates.S"

    section .text

TRAP_15_VECTOR      equ     $bc
TRAP_15_VECTOR_ADDR equ     TRAP_15_VECTOR*4

; Globals
ECHO_ON             equ     $410
PROMPT_ON           equ     $411
LF_DISPLAY          equ     $412
RESERVED            equ     $413

; Wraps FW_PRINT so it can be called from C-land
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
;
; It's cheaper size-wise to just duplicate this here...
FW_PRINT_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINT                  ; Call EARLY_PRINT

; Wraps FW_PRINTLN so it can be called from C-land
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
;
; It's cheaper size-wise to just duplicate this here...
FW_PRINTLN_C::
    move.l  (4,A7),A0                 ; Get C char* from the stack into A0
    bra.s   FW_PRINTLN                ; Call EARLY_PRINT

; Firmware PRINT null-terminated string pointed to by A0
; Uses PRINT function pointed to by address $414
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
FW_PRINT::
    move.l  A1,-(A7)
    move.l  $414,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts
    
; PRINT null-terminated string pointed to by A0 followed by CRLF.
; Uses PRINTLN function pointed to by address $418
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
FW_PRINTLN::
    move.l  A1,-(A7)
    move.l  $418,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; TRAP 15 provides access to Easy68K-compatible tasks
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See README for details.
EASY68K_TRAP_15_HANDLER:
    cmp.l   #20,D0                      ; Is function code in range?
    bhi.s   .DONE                       ; Nope, leave...

    add.l   D0,D0                       ; Multiply FC...
    add.l   D0,D0                       ; ... by 4...
    move.l  JUMPTABLE(PC,D0),A0         ; ... and calc offset into table...
    jmp     (A0)                        ; ... then jump there

.DONE
    rte                                 ; That's all for now...

JUMPTABLE:
    dc.l    PRINTLN_LEN                 ; FC == 0
    dc.l    PRINT_LEN                   ; FC == 1
    dc.l    READLN_STR                  ; FC == 2
    dc.l    DISPLAYNUM_SIGNED           ; FC == 3
    dc.l    READLN_NUM                  ; FC == 4
    dc.l    READ_CHAR                   ; FC == 5
    dc.l    SEND_CHAR                   ; FC == 6
    dc.l    CHECK_RECV                  ; FC == 7
    dc.l    GET_TICKS                   ; FC == 8
    dc.l    HALT                        ; FC == 9
    dc.l    .NOT_IMPLEMENTED            ; FC == 10
    dc.l    MOVE_X_Y                    ; FC == 11
    dc.l    SET_ECHO                    ; FC == 12
    dc.l    PRINTLN_SZ                  ; FC == 13
    dc.l    PRINT_SZ                    ; FC == 14
    dc.l    DISPLAYNUM_UNSIGNED         ; FC == 15
    dc.l    SET_DISPLAY_OPTS            ; DC == 16
    dc.l    PRINT_SZ_PRINT_NUM          ; DC == 17
    dc.l    PRINT_SZ_READ_NUM           ; DC == 18
    dc.l    .NOT_IMPLEMENTED            ; DC == 19
    dc.l    DISPLAYNUM_SIGNED_WIDTH     ; DC == 20

.NOT_IMPLEMENTED:
    rte

* ************************************************************************** *
* ************************************************************************** *
; The individual handlers. These are responsible for handling the rte,
; and should not return to the main handler!
* ************************************************************************** *
PRINTLN_LEN:
    bsr.s   PRINT_LEN_IMPL              ; Print the string...
    lea     SZ_CRLF,A0                  ; Load CRLF...
    bsr.w   EARLY_PRINT                 ; ... and print it
    rte


* ************************************************************************** *
PRINT_LEN:
    bsr.s   PRINT_LEN_IMPL              ; Do the print...
    rte                                 ; ... and done.

; Sub used for both PRINT_LEN and PRINTLN_LEN
PRINT_LEN_IMPL:
    move.w  D1,D1                       ; Init CCR
    bra.s   .LOOP                       ; Start looping...

.SEND:
    move.b  (A1)+,D0                    ; Get next char and increment A1
    bsr.w   SENDCHAR                    ; Do send...

.LOOP:
    dbra    D1,.SEND                    ; Go again?
    rts                                 ; Nope, we're done...


* ************************************************************************** *
READLN_STR:
    move.l  A1,-(A7)                    ; Store buffer start

    move.b  PROMPT_ON,D2                ; Get display prompt flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .READ                       ; Nope, skip prompt display

    lea.l   READLN_PROMPT,A0            ; Get prompt into A0...
    bsr.w   EARLY_PRINT                 ; ... and print it

.READ
    move.b  ECHO_ON,D2                  ; Get echo flag into D2
    move.w  #80,D1                      ; Max len into D1 (and init CCR)
    bra.s   .LOOP                       ; Start looping...

.RECV:
    bsr.w   RECVCHAR                    ; Receive a character
    cmp.b   #$0D,D0                     ; Is it CR?
    beq.s   .DONE                       ; Done if so, else
    move.b  D0,(A1)+                    ; Store char in buffer and advance

    tst.b   D2                          ; Is echo flag non-zero?
    beq.s   .LOOP                       ; Nope, just loop...
    bsr.w   SENDCHAR                    ; else, echo

.LOOP:
    dbra    D1,.RECV                    ; Go again?

.DONE:
    move.b  #0,(A1)+                    ; Null-terminate
    move.b  LF_DISPLAY,D2               ; Get LF_DISPLAY flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .RETURN                     ; Nope, skip CRLF...

    move.b  #$0D,D0                     ; Finish with CR...
    bsr.w   SENDCHAR
    move.b  #$0A,D0                     ; .. and LF
    bsr.w   SENDCHAR

.RETURN
    move.w  #80,D0                      ; Compute length...
    add.w   #1,D1
    sub.w   D1,D0
    move.w  D0,D1                       ; Shuffle around to stay compatible...
    move.l  (A7)+,A1                    ; ... and restore buffer pointer
    rte


* ************************************************************************** *
DISPLAYNUM_SIGNED:
    move.l  D1,-(A7)                    ; Stack argument...
    bsr.w   print_signed                ; ... and call
    addq    #4,A7                       ; Cleanup stack
    rte                                 ; And done!


* ************************************************************************** *
READLN_NUM:
    bsr.s   READLN_NUM_IMPL
    rte

READLN_NUM_IMPL:
    move.b  PROMPT_ON,D2                ; Get display prompt flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .READ                       ; Nope, skip prompt display

    lea.l   READNUM_PROMPT,A0           ; Get prompt into A0...
    bsr.w   EARLY_PRINT                 ; ... and print it

.READ
    eor.l   D1,D1                       ; Zero D1 (result)

    move.w  #10,D3                      ; Max len into D3 (and init CCR)
    bra.s   .LOOP                       ; Start looping...

.RECV:
    move.b  ECHO_ON,D2                  ; Get echo flag into D2
    bsr.w   RECVCHAR                    ; Receive a character
    cmp.b   #$0D,D0                     ; Is it CR?
    beq.s   .DONE                       ; Done if so, else

    cmp.b   #'0',D0                     ; Is it less than '0'?
    bcs.b   .RECV                       ; Ignore it if so

    cmp.b   #'9',D0                     ; Is it higher than '9'?
    bhi.s   .RECV                       ; Ignore it if so

    tst.b   D2                          ; Is echo flag non-zero?
    beq.s   .ADD                        ; Nope, go to add digit
    bsr.w   SENDCHAR                    ; else, echo

.ADD
    sub.l   #'0',D0                     ; Get actual digit value
    move.l  D1,D2                       ; Store current result
    lsl.l   #2,D1                       ; Multiply D1 by 4...
    add.l   D2,D1                       ; ... add another for 5...
    lsl.l   #1,D1                       ; And double for x10
    add.l   D0,D1                       ; Then add this digit...

.LOOP:
    dbra    D3,.RECV                    ; Go again?

.DONE:
    move.b  LF_DISPLAY,D2               ; Get LF_DISPLAY flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .RETURN                     ; Nope, skip CRLF...

    move.b  #$0D,D0                     ; Finish with CR...
    bsr.w   SENDCHAR
    move.b  #$0A,D0                     ; .. and LF
    bsr.w   SENDCHAR

.RETURN
    rts

* ************************************************************************** *
READ_CHAR:
    bsr.w   RECVCHAR                    ; Call RECVCHAR
    move.l  D0,D1                       ; Platform code returns in D0...
    rte


* ************************************************************************** *
SEND_CHAR:
    move.l  D1,D0                       ; Platform code expects arg in D0...
    bsr.w   SENDCHAR
    rte


* ************************************************************************** *
CHECK_RECV:
    move.b  MFP_RSR,D0                  ; Get RSR
    btst    #7,D0                       ; Is buffer_full bit set?
    bne.s   .TRUE                       ; Yes - Go to set true

    move.b  #0,D1                       ; Else no - so false
    rte                                 ; And done.

.TRUE:
    move.b  #1,D1                       ; Set true
    rte                                 ; And done.


* ************************************************************************** *
GET_TICKS:
    move.w  $408,D1                     ; Get (Word-sized!) count from SDB
    rte


* ************************************************************************** *
; TODO this could do with cleaning up!
MOVE_X_Y:
    cmp.w   #$FF00,D1                   ; Is this a clear screen?
    beq.s   .CLRSCR                     ; Yep, go there

.MOVEXY
    move.w  D1,D2                       ; Use D2 for coords..

    lea.l   ANSI_START,A0               ; Load ANSI initiator...
    bsr.w   EARLY_PRINT                 ; ... and print it

    eor.l   D0,D0                       ; Zero D0

    move.b  D2,D0                       ; Get Y from D1 into D0
    move.l  #10,-(A7)                   ; Stack base (10)...
    move.l  D0,-(A7)                    ; ... and Y coord
    bsr.w   print_unsigned              ; ... and print

    lea.l   ANSI_SEP,A0                 ; Load separator...
    bsr.w   EARLY_PRINT                 ; ... and print it

    eor.l   D0,D0                       ; Zero D0 again

    move.w  D2,D0                       ; Get coords into D0
    lsr.w   #8,D0                       ; Shift right to get X
    move.l  D0,(A7)                     ; Replace Y on stack with X...
    bsr.w   print_unsigned              ; ... and print

    addq    #8,A7                       ; Cleanup stack

    lea.l   ANSI_XYEND,A0               ; Load XY end command
    bsr.w   EARLY_PRINT                 ; ... and print it

    rte                                 ; and done!

.CLRSCR
    lea.l   ANSI_CLR,A0                 ; Load ANSI Clear Screen...
    bsr.w   EARLY_PRINT                 ; ... and print it
    rte


* ************************************************************************** *
SET_ECHO:
    move.b  D1,ECHO_ON
    rte


* ************************************************************************** *
PRINTLN_SZ:
    movea.l A1,A0
    bsr.w   EARLY_PRINTLN
    rte


* ************************************************************************** *
PRINT_SZ:
    movea.l A1,A0
    bsr.w   EARLY_PRINT
    rte


* ************************************************************************** *
DISPLAYNUM_UNSIGNED:
    move.l  D2,-(A7)                    ; Stack base...
    move.l  D1,-(A7)                    ; ... and number
    bsr.w   print_unsigned              ; ... and call.
    addq    #8,A7                       ; Cleanup stack
    rte                                 ; Fin!


* ************************************************************************** *
SET_DISPLAY_OPTS:
    cmp.b   #0,D1                       ; Is D1 0?
    beq     .PROMPT_OFF                 ;   Prompt disable if so, else...
    cmp.b   #1,D1                       ; Is D1 1?
    beq     .PROMPT_ON                  ;   Prompt enable if so, else...
    cmp.b   #2,D1                       ; Is D1 2?
    beq     .LF_OFF                     ;   Linefeed disable if so, else...
    cmp.b   #3,D1                       ; Is D1 3?
    beq     .LF_ON                      ;   Linefeed enable if so, else...
    rte                                 ; Ignore.

.PROMPT_OFF:
    move.b  0,PROMPT_ON
    rte

.PROMPT_ON
    move.b  1,PROMPT_ON
    rte

.LF_OFF:
    move.b  0,LF_DISPLAY
    rte

.LF_ON:
    move.b  1,LF_DISPLAY
    rte


* ************************************************************************** *
PRINT_SZ_PRINT_NUM:
    movea.l A1,A0                       ; Move arg for EARLY_PRINT...
    bsr.w   EARLY_PRINT                 ; ... and call it

    move.l  D1,-(A7)                    ; Stack number argument...
    bsr.w   print_signed                ; ... and call
    addq    #4,A7                       ; Cleanup stack
    rte                                 ; And done!


* ************************************************************************** *
PRINT_SZ_READ_NUM:
    movea.l A1,A0                       ; Move arg for EARLY_PRINT...
    bsr.w   EARLY_PRINT                 ; ... and call it

    bsr.w   READLN_NUM_IMPL             ; Then read a number into D1
    rte


* ************************************************************************** *
DISPLAYNUM_SIGNED_WIDTH:
    move.l  D2,-(A7)                    ; Stack width...
    move.l  D1,-(A7)                    ; ... and number
    bsr.w   print_signed_width          ; ... and call.
    addq    #8,A7                       ; Cleanup stack
    rte                                 ; Fin!


* ************************************************************************** *
* ************************************************************************** *
; Called to install the TRAP handlers
* ************************************************************************** *
INSTALL_EASY68K_TRAP_HANDLERS::
; Initialise configuration
    move.b  #1,ECHO_ON
    move.b  #1,PROMPT_ON
    move.b  #1,LF_DISPLAY

; Install handler
    lea     EASY68K_TRAP_15_HANDLER,A0
    move.l  A0,TRAP_15_VECTOR
    rts


* ************************************************************************** *
* ************************************************************************** *
; Data
* ************************************************************************** *
; Consts...
SZ_CRLF         dc.b        $D, $A, 0
READLN_PROMPT   dc.b        "Input$> ", 0
READNUM_PROMPT  dc.b        "Input#> ", 0

; TODO Quite inefficient doing this with sz strings!
ANSI_START    dc.b        $1B, "[", 0
ANSI_CLR      dc.b        $1B, "[2J", 0
ANSI_SEP      dc.b        ";", 0
ANSI_XYEND    dc.b        "H", 0


