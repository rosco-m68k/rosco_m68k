;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2022 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is the MFP code. 
; It unconditionally initializes the MFP, and provides
; I/O routines.
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    ifd REVISION1X

    section .text

; Initialise MFP
;
; Notes on MFP_TDDR value and baud-rate:
; 
; Setting 1 will give 921.6KHZ, which divides to 28800 baud
; Setting 2 will give 460.8KHz, which divides to 14400 baud
;
; However, those baud rates are non-standard (i.e. non-POSIX) and support is patchy.
; Whether they work will depend on your USB<->Serial converter and OS.
; Minicom doesn't support them, Picocom does. C-Kermit doesn't.
;
; An alternative scheme (thanks to @robg on Discord) is to replace the 3.6864MHz
; crystal with a 2.4576MHz part, and set the MFP_TDDR count to 1 - this will
; give a (standard) baud-rate of 19200 (assuming the /4 prescaler is still used).
;
; Trashes: D0
; Modifies: MFP Regs
INITMFP::
    ; GPIOs
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    ; Timer setup - Timer D controls serial clock, C is system tick
    move.b  #$B8,MFP_TCDR             ; Timer C count is 184 for 50Hz (interrupt on rise and fall so 100Hz)
    move.b  #$03,MFP_TDDR             ; Timer D count is 3 for 307.2KHz, divided to 9600 baud

    ifd NO_TICK
    move.b  #$01,MFP_TCDCR            ; Disable timer C and enable timer D with /4 prescaler
    else
    move.b  #$71,MFP_TCDCR            ; Enable timer C with /200 and D with /4 prescaler
    endif

    
    ; USART setup
    move.b  #$88,MFP_UCR              ; /16 clock, async, 8N1
    move.b  #$05,MFP_TSR              ; Set pin state high and enable transmitter

    ; Interrupt setup - Enable timer C interrupt for kernel tick
    move.l  #MFP_VECBASE,D0           ; Set up the base MFP vector at 0x40 (first 16 user vectors)...
    or.l    #8,D0                     ; ... and set software-end-of-interrupt mode
    move.b  D0,MFP_VR                 ; ... then write to MFP vector register

    ifd NO_TICK
    bset.b  #0,MFP_GPDR               ; Turn off GPIO #0 (Green LED)
    else
    or.b    #$20,MFP_IERB             ; Enable Timer C interrupt, but leave it masked for now
    endif

    move.l  #MFPBASE,SDB_UARTBASE     ; Default UART starts out as MFP, may get overwritten later... 

    ; Setup default implementations in EFP table.
    move.l  #EARLY_PRINT_MFP,EFP_PRINT
    move.l  #EARLY_PRINTLN_MFP,EFP_PRINTLN
    move.l  #SENDCHAR_MFP,EFP_PRINTCHAR
    move.l  #SENDCHAR_MFP,EFP_SENDCHAR
    move.l  #RECVCHAR_MFP,EFP_RECVCHAR
    move.l  #CHECKCHAR_MFP,EFP_CHECKCHAR
    move.l  #ANSI_MOVEXY,EFP_MOVEXY
    move.l  #ANSI_CLRSCR,EFP_CLRSCR

    rts


; PRINT null-terminated string pointed to by A0
;
; Only used directly during early init; Becomes the default implementation
; of FW_PRINT (pointed to by the EFP table) and likely replaced later.
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINT_MFP:
    move.b  (A0)+,D0                  ; Get next character
    beq.s   .PRINT_DONE               ; ... we're done if null.

.BUFF_WAIT:
    btst.b  #7,MFP_TSR                ; Is transmit buffer empty?
    beq.s   .BUFF_WAIT                ; Busywait if not
    
    move.b  D0,MFP_UDR                ; ... otherwise, give character to the MFP
    bra.s   EARLY_PRINT_MFP           ; and loop
.PRINT_DONE:    
    rts                               ; We're done
 

; PRINT null-terminated string pointed to by A0 followed by CRLF.
;
; Only used directly during early init; Becomes the default implementation
; of FW_PRINT (pointed to by the EFP table) and likely replaced later.
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINTLN_MFP:
    bsr.s   EARLY_PRINT_MFP           ; Print callers message
    move.l  A0,-(A7)                  ; Stash A0 to restore later
    
    lea     SZ_CRLF,A0                ; Load CRLF...
    bsr.s   EARLY_PRINT_MFP           ; ... and print it
        
    move.l  (A7)+,A0                  ; Restore A0
    rts


; Check if a character is ready to receive via UART
;
; Trashes: UART registers
; Modifies: D0.B (return = 0 if no character waiting, nonzero otherwise)
CHECKCHAR_MFP:
    move.b  MFP_RSR,D0            ; Get RSR
    andi.b  #$80,D0               ; And with buffer full bit
    rts


; Send a single character via UART
;
; Trashes: MFP_UDR
; Modifies: Nothing
SENDCHAR_MFP:
    move.l  D1,-(A7)              ; Save D1
    move.l  D2,-(A7)              ; Save D2

    move.b  SDB_SYSFLAGS,D2       ; Get sysflags (high byte)
    move.b  MFP_GPDR,D1           ; Get GPDR
    or.b    #$80,D1               ; Raise (inhibit) bit 7 (RTS)
    and.b   D2,D1                 ; Mask with flags
    move.b  D1,MFP_GPDR           ; Set GPDR

.BEGIN    
    move.b  MFP_TSR,D1            ; Get TSR
    btst    #7,D1                 ; Is buffer empty bit set?
    beq.s   .BEGIN                ; No - loop until it is

    move.b  D0,MFP_UDR            ; Put func arg in UDR
    move.l  (A7)+,D2              ; Restore D2
    move.l  (A7)+,D1              ; Restore D1
    rts


; Receive a single character via UART.
; Ignores overrun errors.
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
RECVCHAR_MFP:
    move.l  D1,-(A7)              ; Store D1
    move.b  SDB_SYSFLAGS,D1       ; Get sysflags (high byte)
    
    move.b  MFP_GPDR,D0           ; Get GPDR
    and.b   #$7F,D0               ; Lower bit 7 (RTS)
    and.b   D1,D0                 ; Mask with flags
    move.b  D0,MFP_GPDR           ; Set GPDR

.BEGIN
    move.b  MFP_RSR,D0            ; Get RSR
    btst    #7,D0                 ; Is buffer_full bit set?
    bne.s   .GOTCHR               ; Yes - Go to receive character

    btst    #6,D0                 ; Else, do we have an overrun error?
    bne.s   .GOTERR               ; .. Yes - handle that
    bra.s   .BEGIN                ; .. No - Just loop

.GOTERR
    move.b  MFP_UDR,D0            ; Empty buffer
    move.b  MFP_GPDR,D0           ; Get GPDR
    eor.b   #2,D0                 ; Toggle I1
    and.b   D1,D0                 ; Mask with flags
    move.b  D0,MFP_GPDR           ; Set GPDR
    bra.s   .BEGIN                ; And continue testing...
    
.GOTCHR
    move.b  MFP_UDR,D0            ; Get the data
    move.l  (A7)+,D1              ; Restore D1
    rts

    endif
