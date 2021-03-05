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

TRAP_15_VECTOR      equ     $2f
TRAP_15_VECTOR_ADDR equ     TRAP_15_VECTOR*4

; Globals
ECHO_ON             equ     $410
PROMPT_ON           equ     $411
LF_DISPLAY          equ     $412
RESERVED            equ     $413


; TRAP 15 provides access to Easy68K-compatible tasks
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See README for details.
EASY68K_TRAP_15_HANDLER:
    move.l  D0,-(A7)                    ; Save function code
    
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
    dc.l    EPILOGUE                    ; FC == 10 (NOT IMPLEMENTED)
    dc.l    MOVE_X_Y                    ; FC == 11
    dc.l    SET_ECHO                    ; FC == 12
    dc.l    PRINTLN_SZ                  ; FC == 13
    dc.l    PRINT_SZ                    ; FC == 14
    dc.l    DISPLAYNUM_UNSIGNED         ; FC == 15
    dc.l    SET_DISPLAY_OPTS            ; DC == 16
    dc.l    PRINT_SZ_PRINT_NUM          ; DC == 17
    dc.l    PRINT_SZ_READ_NUM           ; DC == 18
    dc.l    EPILOGUE                    ; DC == 19 (NOT IMPLEMENTED)
    dc.l    DISPLAYNUM_SIGNED_WIDTH     ; DC == 20

; N.B. If changing this EPILOGUE, be sure to change EPILOGUE2 at the bottom
; of the file to match!
EPILOGUE:
    move.l  (A7)+,D0                    ; Restore function code
    rte

* ************************************************************************** *
* ************************************************************************** *
; The individual handlers. They should jump back toEPILOGUE once complete
; so that the stack / registers can be restored.
* ************************************************************************** *
PRINTLN_LEN:
    bsr.s   PRINT_LEN_IMPL              ; Print the string...
    lea     SZ_CRLF,A0                  ; Load CRLF...
    bsr.w   FW_PRINT                    ; ... and print it
    bra.s   EPILOGUE                   


* ************************************************************************** *
PRINT_LEN:
    bsr.s   PRINT_LEN_IMPL              ; Do the print...
    bra.s   EPILOGUE                   

; Sub used for both PRINT_LEN and PRINTLN_LEN
PRINT_LEN_IMPL:
    move.w  D1,D1                       ; Init CCR
    bra.s   .LOOP                       ; Start looping...

.SEND:
    move.b  (A1)+,D0                    ; Get next char and increment A1
    bsr.w   FW_PRINTCHAR                ; Do send...

.LOOP:
    dbra    D1,.SEND                    ; Go again?
    rts                                 ; Nope, we're done...


* ************************************************************************** *
READLN_STR:
    move.l  A1,-(A7)                    ; Store buffer start
    move.l  D2,-(A7)                    ; Store scratch register

    move.b  PROMPT_ON,D2                ; Get display prompt flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .READ                       ; Nope, skip prompt display

    lea.l   READLN_PROMPT,A0            ; Get prompt into A0...
    bsr.w   FW_PRINT                    ; ... and print it

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
    bsr.w   FW_PRINTCHAR                ; else, echo

.LOOP:
    dbra    D1,.RECV                    ; Go again?

.DONE:
    move.b  #0,(A1)+                    ; Null-terminate
    move.b  LF_DISPLAY,D2               ; Get LF_DISPLAY flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .RETURN                     ; Nope, skip CRLF...

    move.b  #$0D,D0                     ; Finish with CR...
    bsr.w   FW_PRINTCHAR
    move.b  #$0A,D0                     ; .. and LF
    bsr.w   FW_PRINTCHAR

.RETURN
    move.w  #80,D0                      ; Compute length...
    add.w   #1,D1
    sub.w   D1,D0
    move.w  D0,D1                       ; Shuffle around to stay compatible...
    move.l  (A7)+,D2                    ; ... restore scratch reg
    move.l  (A7)+,A1                    ; ... and buffer pointer
    bra.w   EPILOGUE                   


* ************************************************************************** *
DISPLAYNUM_SIGNED:
    move.l  D1,-(A7)                    ; Stack argument...
    bsr.w   print_signed                ; ... and call
    addq    #4,A7                       ; Cleanup stack
    bra.w   EPILOGUE                   


* ************************************************************************** *
READLN_NUM:
    bsr.s   READLN_NUM_IMPL
    bra.w   EPILOGUE                   

READLN_NUM_IMPL:
    move.l  D2,-(A7)                    ; Save scratch registers
    move.l  D3,-(A7)                    ; ...

    move.b  PROMPT_ON,D2                ; Get display prompt flag
    tst.b   D2                          ; Is it non-zero?
    beq.s   .READ                       ; Nope, skip prompt display

    lea.l   READNUM_PROMPT,A0           ; Get prompt into A0...
    bsr.w   FW_PRINT                    ; ... and print it

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
    bsr.w   FW_PRINTCHAR                ; else, echo

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
    bsr.w   FW_PRINTCHAR
    move.b  #$0A,D0                     ; .. and LF
    bsr.w   FW_PRINTCHAR

.RETURN
    move.l  (A7)+,D3                    ; Restore scratch registers
    move.l  (A7)+,D2                    ; ...
    rts

* ************************************************************************** *
READ_CHAR:
    bsr.w   RECVCHAR                    ; Call RECVCHAR
    move.l  D0,D1                       ; Platform code returns in D0...
    bra.w   EPILOGUE                   


* ************************************************************************** *
SEND_CHAR:
    move.l  D1,D0                       ; Platform code expects arg in D0...
    bsr.w   SENDCHAR
    bra.w   EPILOGUE                   


* ************************************************************************** *
; TODO This is directly interfacing the the MFP - It should go through to the
; default UART instead...
CHECK_RECV:
    move.b  MFP_RSR,D0                  ; Get RSR
    btst    #7,D0                       ; Is buffer_full bit set?
    bne.s   .TRUE                       ; Yes - Go to set true

    move.b  #0,D1                       ; Else no - so false
    bra.w   EPILOGUE2                   

.TRUE:
    move.b  #1,D1                       ; Set true
    bra.w   EPILOGUE2                   


* ************************************************************************** *
GET_TICKS:
    move.w  $408,D1                     ; Get (Word-sized!) count from SDB
    bra.w   EPILOGUE2                   


* ************************************************************************** *
MOVE_X_Y:
    cmp.w   #$FF00,D1                   ; Is this a clear screen?
    beq.s   .CLRSCR                     ; Yep, go there

.MOVEXY
    bsr.w   FW_MOVEXY
    bra.w   EPILOGUE2                   

.CLRSCR
    bsr.w   FW_CLRSCR
    bra.w   EPILOGUE2                   


* ************************************************************************** *
SET_ECHO:
    move.b  D1,ECHO_ON
    bra.w   EPILOGUE2


* ************************************************************************** *
PRINTLN_SZ:
    move.l  A0,-(A7)
    move.l  A1,A0
    bsr.w   FW_PRINTLN
    move.l  A0,A1
    move.l  (A7)+,A0
    bra.w   EPILOGUE2                  


* ************************************************************************** *
PRINT_SZ:
    move.l  A0,-(A7)
    move.l  A1,A0
    bsr.w   FW_PRINT
    move.l  A0,A1
    move.l  (A7)+,A0
    bra.w   EPILOGUE2 


* ************************************************************************** *
DISPLAYNUM_UNSIGNED:
    move.l  D2,-(A7)                    ; Stack base...
    move.l  D1,-(A7)                    ; ... and number
    bsr.w   print_unsigned              ; ... and call.
    addq    #8,A7                       ; Cleanup stack
    bra.w   EPILOGUE2                  


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
    bra.s   EPILOGUE2

.PROMPT_OFF:
    move.b  0,PROMPT_ON
    bra.s   EPILOGUE2

.PROMPT_ON
    move.b  1,PROMPT_ON
    bra.s   EPILOGUE2

.LF_OFF:
    move.b  0,LF_DISPLAY
    bra.s   EPILOGUE2

.LF_ON:
    move.b  1,LF_DISPLAY
    bra.s   EPILOGUE2


* ************************************************************************** *
PRINT_SZ_PRINT_NUM:
    move.l  A0,-(A7)
    movea.l A1,A0                       ; Move arg for FW_PRINT...
    bsr.w   FW_PRINT                    ; ... and call it

    move.l  D1,-(A7)                    ; Stack number argument...
    bsr.w   print_signed                ; ... and call
    addq    #4,A7                       ; Cleanup stack
    
    move.l  (A7)+,A0
    bra.s   EPILOGUE2


* ************************************************************************** *
PRINT_SZ_READ_NUM:
    move.l  A0,-(A7)
    movea.l A1,A0                       ; Move arg for FW_PRINT...
    bsr.w   FW_PRINT                    ; ... and call it

    bsr.w   READLN_NUM_IMPL             ; Then read a number into D1
    move.l  (A7)+,A0
    bra.s   EPILOGUE2


* ************************************************************************** *
DISPLAYNUM_SIGNED_WIDTH:
    move.l  D2,-(A7)                    ; Stack width...
    move.l  D1,-(A7)                    ; ... and number
    bsr.w   print_signed_width          ; ... and call.
    addq    #8,A7                       ; Cleanup stack


EPILOGUE2:
    move.l  (A7)+,D0                    ; Restore function code
    rte

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
    move.l  A0,TRAP_15_VECTOR_ADDR
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


