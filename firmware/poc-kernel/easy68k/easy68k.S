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
; Easy68K-compatible syscalls from C 
;------------------------------------------------------------

    section .text

; Call the PRINTLN_LEN function (task 0)
;
; void e68PrintlnLen(char *, uint16_t)
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68PrintlnLen::
    movem.l D0-D1/A1,-(A7)            ; Save regs
    move.l  (16,A7),A1                ; Get C char* from the stack into A1
    move.l  (20,A7),D1                ; Get length into D1
    move.l  #0,D0                     ; Func code is 0
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1/A1            ; Restore regs
    rts                               ; We're done.


; Call the PRINT_LEN function (task 1)
;
; void e68PrintlnLen(char *, uint16_t)
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68PrintLen::
    movem.l D0-D1/A1,-(A7)            ; Save regs
    move.l  (16,A7),A1                ; Get C char* from the stack into A1
    move.l  (20,A7),D1                ; Get length into D1
    move.l  #1,D0                     ; Func code is 1
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1/A1            ; Restore regs
    rts                               ; We're done.


; Call the READLN_STR function (task 2)
;
; uint16_t e68ReadlnStr(char *)
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
e68ReadlnStr::
    movem.l D1/A1,-(A7)               ; Save regs
    move.l  (12,A7),A1                ; Get buffer* from the stack into A1
    move.l  #2,D0                     ; Func code is 2
    trap    #15                       ; TRAP to Easy68k firmware
    eor.l   D0,D0                     ; Zero D0...
    move.w  D1,D0                     ; ... and place return value there
    movem.l (A7)+,D1/A1               ; Restore regs
    rts                               ; We're done.


; Call the DISPLAY_NUM_SIGNED function (task 3)
;
; void e68DisplayNumSigned(int32_t);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68DisplayNumSigned::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  (12,A7),D1                ; Get num from the stack into D1
    move.l  #3,D0                     ; Func code is 3
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.
    

; Call the READLN_NUM function (task 4)
;
; uint32_t e68ReadlnNum();
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
e68ReadlnNum::
    move.l  D1,-(A7)                  ; Save D1
    move.l  #4,D0                     ; Func code is 4
    trap    #15                       ; TRAP to Easy68k firmware
    move.l  D1,D0                     ; Place return value in D0
    move.l  (A7)+,D1                  ; Restore D1
    rts                               ; We're done.


; Call the READ_CHAR function (task 5)
;
; uint8_t e68ReadChar();
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
e68ReadChar::
    move.l  D1,-(A7)                  ; Save D1
    move.l  #5,D0                     ; Func code is 5
    trap    #15                       ; TRAP to Easy68k firmware
    eor.l   D0,D0                     ; Zero D0...
    move.b  D1,D0                     ; ... and place return value there
    move.l  (A7)+,D1                  ; Restore D1
    rts                               ; We're done.


; Call the SEND_CHAR function (task 6)
;
; void e68SendChar(uint8_t chr);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68SendChar::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  (12,A7),D1                ; Get number from the stack into D1
    move.l  #6,D0                     ; Func code is 6
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.


; Call the CHECK_RECV function (task 7)
;
; bool e68CheckRecv();
;
; Trashes: Nothing
; Modifies: D0 (return)
e68CheckRecv::
    move.l  D1,-(A7)                  ; Save D1
    move.l  #7,D0                     ; Func code is 7
    trap    #15                       ; TRAP to Easy68k firmware
    eor.l   D0,D0                     ; Zero D0...
    move.b  D1,D0                     ; ... and place return value there
    move.l  (A7)+,D1                  ; Restore D1
    rts                               ; We're done.


; Call the GET_TICKS function (task 8)
;
; uint32_t e68GetTicks();
;
; Trashes: Nothing
; Modifies: D0 (return)
e68GetTicks::
    move.l  D1,-(A7)                  ; Save D1
    move.l  #8,D0                     ; Func code is 8
    trap    #15                       ; TRAP to Easy68k firmware
    move.l  D1,D0                     ; Place return value in D0
    move.l  (A7)+,D1                  ; Restore D1
    rts                               ; We're done.


; Call the HALT function (task 9)
;
; noreturn void e68Halt();
;
; Trashes: Nothing
; Modifies: Nothing
e68Halt::
    move.l  #9,D0                     ; Func code is 9
    trap    #15                       ; TRAP to Easy68k firmware
    rts                               ; (Should never reach here!)


; Call the MOVE_X_Y function (task 11) with X,Y coordinates
;
; void e68MoveXY(uint8_t x, uint8_t y);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68MoveXY::
    movem.l D0-D1,-(A7)               ; Save regs
    eor.l   D1,D1                     ; Zero D1
    move.l  (12,A7),D0                ; Get X from the stack into D0
    move.b  D0,D1                     ; Move X bytesize into D1
    lsl.w   #8,D1                     ; Shift X to high byte
    move.l  (16,A7),D0                ; Get Y from stack into D0
    move.b  D0,D1                     ; Move Y bytesize into D1
    move.l  #11,D0                    ; Func code is 11
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.


; Call the MOVE_X_Y function (task 11) with $FF00 (Clear screen)
;
; void e68ClearScr();
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68ClearScr::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  #11,D0                    ; Func code is 11
    move.w  #$FF00,D1                 ; Special case for clear screen
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.


; Call the SET_ECHO function (task 12)
;
; void e68SetEcho(bool echo_on);
;
; Trashes: Nothing
; Modifies: D0 (return)
e68SetEcho::
    movem.l D0-D1,-(A7)               ; Save D1
    move.l  (12,A7),D1                ; Get argument from stack
    move.l  #12,D0                    ; Func code is 12
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore D1
    rts                               ; We're done.


; Call the PRINTLN_SZ function (task 13)
;
; void e68Println(char *sz);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68Println::
    movem.l D0/A1,-(A7)               ; Save regs
    move.l  (12,A7),A1                ; Get buffer* from the stack into A1
    move.l  #13,D0                    ; Func code is 13
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0/A1               ; Restore regs
    rts                               ; We're done.


; Call the PRINT_SZ function (task 14)
;
; void e68Print(char *sz);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68Print::
    movem.l D0/A1,-(A7)               ; Save regs
    move.l  (12,A7),A1                ; Get buffer* from the stack into A1
    move.l  #14,D0                    ; Func code is 14
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0/A1               ; Restore regs
    rts                               ; We're done.


; Call the DISPLAY_UNSIGNED function (task 15)
;
; void e68DisplayNumUnsigned(uint32_t num);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68DisplayNumUnsigned::
    movem.l D0-D2,-(A7)               ; Save regs
    move.l  (16,A7),D1                ; Get num from the stack into D1
    move.l  (20,A7),D2                ; Get base into D2
    move.l  #15,D0                    ; Func code is 15
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D2               ; Restore regs
    rts                               ; We're done.


; Call the SET_DISPLAY_OPT function (task 16)
;
; void e68SetDisplayOpt(uint8_t option);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68SetDisplayOpt::
    movem.l D0-D1,-(A7)               ; Save regs
    move.l  (12,A7),D1                ; Get num from the stack into D1
    move.l  #16,D0                    ; Func code is 16
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1               ; Restore regs
    rts                               ; We're done.


; Call the PRINT_STR_NUM function (task 17)
;
; void e68PrintStrNumSigned(char *str, uint32_t num);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68PrintStrNumSigned::
    movem.l D0-D1/A1,-(A7)            ; Save regs
    move.l  (16,A7),A1                ; Get str from the stack into A1
    move.l  (20,A7),D1                ; Get num into D1
    move.l  #17,D0                    ; Func code is 15
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D1/A1            ; Restore regs
    rts                               ; We're done.


; Call the PRINT_STR_READ_NUM function (task 18)
;
; uint32_t e68PrintStrReadNumSigned(char *str);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68PrintStrReadNumSigned::
    movem.l D1/A1,-(A7)               ; Save regs
    move.l  (12,A7),D1                ; Get str from the stack into A1
    move.l  #18,D0                    ; Func code is 16
    trap    #15                       ; TRAP to Easy68k firmware
    move.l  D1,D0                     ; Move result for return
    movem.l (A7)+,D1/A1               ; Restore regs
    rts                               ; We're done.


; Call the DISPLAY_SIGNED_WIDTH function (task 20)
;
; void e68PrintNumSignedWidth(uint32_t num, uint8_t width);
;
; Trashes: MFP_UDR
; Modifies: Nothing
e68PrintNumSignedWidth::
    movem.l D0-D2,-(A7)               ; Save regs
    move.l  (16,A7),D1                ; Get num from the stack into D1
    move.l  (20,A7),D2                ; Get width into D2
    move.l  #20,D0                    ; Func code is 20
    trap    #15                       ; TRAP to Easy68k firmware
    movem.l (A7)+,D0-D2               ; Restore regs
    rts                               ; We're done.

