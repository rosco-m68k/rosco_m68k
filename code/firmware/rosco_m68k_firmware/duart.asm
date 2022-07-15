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
; This is the DUART code. 
; It detects and initializes the DUART, and provides
; I/O routines.
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    ifnd NO_68681

    section .text

; Initialise MC68681 DUART if present
;
; If an MC68681 is found, this will set D5 to 1. Otherwise, D5 will be 0.
; This is used to signal INITSDB that it should use the DUART vectors instead of
; the MFP ones.
;
; Trashes: D0, A0-A5
; Modifies: D5 (non-zero if DUART detected), MFP Regs
INITDUART::
    ifnd REVISION1X
    ; Building for r2.x mainboard, try onboard DUART first
    move.l  #DUART_BASE_MBR2,A0
    bsr.w   INITDUART_ATBASE          ; Try detect / and basic init
    tst.b   D5                        ; Did we find it?
    bne.s   .INIT_R2                  ; If yes, initialize it
    endif 

    ; Let's try the r2 DUART board...
    move.l  #DUART_BASE_R2,A0         ; Set R2 the base address
    bsr.w   INITDUART_ATBASE          ; Try detect / and basic init
    tst.b   D5                        ; Did we find it?
    beq.s   .TRY_R1                   ; If no, try the R1 instead.

.INIT_R2
    ; Else, we found an r2 (XR68C681). Set it up for 115200
    ; UART A
    move.b  #$A0,DUART_CRA(A0)        ; Enable extended TX rates
    move.b  #$80,DUART_CRA(A0)        ; Enable extended RX rates
    move.b  #$80,DUART_ACR(A0)        ; Select bit rate set 2
    move.b  #$88,DUART_CSRA(A0)       ; 115K2

    ; UART B
    move.b  #$A0,DUART_CRB(A0)        ; Enable extended TX rates
    move.b  #$80,DUART_CRB(A0)        ; Enable extended RX rates
    move.b  #$80,DUART_ACR(A0)        ; Select bit rate set 2
    move.b  #$88,DUART_CSRB(A0)       ; 115K2

    bra.s   .COMMON_INIT

.TRY_R1
    move.l  #DUART_BASE_R1,A0         ; Set the R1 base address
    bsr.w   INITDUART_ATBASE          ; Try detect / and basic init
    tst.b   D5                        ; Did we find it?
    beq.w   .DONE                     ; If no, we don't have a 68681

    ; Else, we found an r1 (MC68681). Set it up for 115200
    move.b  #$60,DUART_ACR(A0)        ; Set 0, Counter, X1/X2, /16

    ; UART A 
    move.b  DUART_CRA(A0),D0          ; Enable undocumented rates
    move.b  #$66,DUART_CSRA(A0)       ; 1200 per spec, uses counter instead

    ; UART B
    move.b  DUART_CRB(A0),D0          ; Enable undocumented rates
    move.b  #$66,DUART_CSRB(A0)       ; 1200 per spec, uses counter instead

    move.b  #0,DUART_CUR(A0)          ; Counter high: 0
    move.b  #2,DUART_CLR(A0)          ; Counter  low: 2  (115.2KHz)
    move.b  R_STARTCNTCMD(A0),D0      ; Start count

.COMMON_INIT
    move.l  A0,SDB_UARTBASE           ; Store the base address in SDB

    move.b  #$13,DUART_MR1A(A0)       ; (No RTS, RxRDY, Char, No parity, 8 bits)
    move.b  #$07,DUART_MR2A(A0)       ; (Normal, No TX CTS/RTS, 1 stop bit)
    move.b  #$13,DUART_MR1B(A0)       ; (No RTS, RxRDY, Char, No parity, 8 bits)
    move.b  #$07,DUART_MR2B(A0)       ; (Normal, No TX CTS/RTS, 1 stop bit) 
    
    ifnd REVISION1X
    move.b  #$01,W_OPR_SETCMD(A0)     ; Assert RTS from startup
    endif

    ; Debug - output clocks on OP2 for scope
    ;move.b  #%00000010,DUART_OPCR(A0)  ; RxCA (1x) on OP2, TxCA (1x) on OP3
    move.b  #%00000000,DUART_OPCR(A0)  ; All output port disabled

    move.b  #%00000101,DUART_CRA(A0)   ; Enable TX/RX port A
    move.b  #%00000101,DUART_CRB(A0)   ; Enable TX/RX port B

    ifnd REVISION1X
    ; System timer / interrupt setup
    move.b  #$F0,DUART_ACR(A0)        ; Enable timer XCLK/16
    move.b  #$45,DUART_IVR(A0)        ; Use vector 0x45

    ; Timer will run at ~100Hz: 3686400 / 16 / (1152 * 2) = 100
    move.b  #$04,DUART_CTUR(A0)       ; Counter MSB is 0x04
    move.b  #$80,DUART_CTLR(A0)       ; Counter LSB is 0x80

    move.b  R_STARTCNTCMD(A0),D0      ; Issue START COUNTER command 
    endif

    ; Setup default implementations in EFP table.
    move.l  #EARLY_PRINT_DUART,EFP_PRINT
    move.l  #EARLY_PRINTLN_DUART,EFP_PRINTLN
    move.l  #SENDCHAR_DUART,EFP_PRINTCHAR
    move.l  #SENDCHAR_DUART,EFP_SENDCHAR
    move.l  #RECVCHAR_DUART,EFP_RECVCHAR
    move.l  #ANSI_CLRSCR,EFP_CLRSCR
    move.l  #ANSI_MOVEXY,EFP_MOVEXY
    move.l  #EFP_DUMMY_NOOP,EFP_SETCURSOR
    move.l  #CHECKCHAR_DUART,EFP_CHECKCHAR

    ; Setup device blocks...
    lea.l   DEVICE_BLOCKS,A1
    move.w  DEVICE_COUNT,D0
    lsl.w   D0
    add.w   D0,A1

    ; ... UART A
    move.l  A0,(A1)+
    move.l  #D_CHECKCHAR_DUART_A,(A1)+
    move.l  #D_RECVCHAR_DUART_A,(A1)+
    move.l  #D_SENDCHAR_DUART_A,(A1)+
    move.l  #0,(A1)+                  ; Reserved
    move.l  #0,(A1)+                  ; Reserved
    move.l  #D_CTRL_DUART_A,(A1)+
    move.l  #$00000002,(A1)+          ; DUART A is device type 2, 0 flags

    ; ... UART B
    move.l  A0,(A1)+
    move.l  #D_CHECKCHAR_DUART_B,(A1)+
    move.l  #D_RECVCHAR_DUART_B,(A1)+
    move.l  #D_SENDCHAR_DUART_B,(A1)+
    move.l  #0,(A1)+                  ; Reserved
    move.l  #0,(A1)+                  ; Reserved
    move.l  #D_CTRL_DUART_B,(A1)+
    move.l  #$00000003,(A1)+          ; DUART B is device type 3, 0 flags

    addi.w  #2,DEVICE_COUNT

.DONE
    rts


; Try to initialise the DUART at the base address in A0.
INITDUART_ATBASE:
    move.b  #0,D5                     ; Indicate no MC68681 by default

    ; On r1.2, not having a 68681 will generate a bus error. We can look
    ; for this on the first access, and if we get one, just bail immediately.
    move.b  #0,BERR_FLAG              ; Zero bus error flag

    move.l  $8,BERR_SAVED             ; Save the original bus error handler
    move.l  #BERR_HANDLER,$8          ; Install temporary bus error handler

    move.b  #$0,DUART_IMR(A0)         ; Mask all interrupts

    ; If the first write generated a bus error, we may as well fail fast...
    tst.b   BERR_FLAG                 ; Was there a bus error?
    bne.s   .DONE                     ; Bail now if so...

    ; We now know that _something_ is present in the 68681 IO space, and 
    ; is capable of DTACK generation. Let's see if it looks like 68681...
    ; 
    ; IVR is a convenient register that allows both read and write. We'll check its
    ; initial value is as expected, then set ensure the initial read wasn't
    ; a fluke. Note that, with the basic 68681 board, vectored interrupts are 
    ; never used, so setting this has no effect - it's just a test. 
    ;
    ; This is hardly definitive, but should be good-enough for our purposes...
    ;
    move.b  DUART_IVR(A0),D0          ; Get IVR - Should be 0x0F at reset
    cmp.b   #$0F,D0                   
    bne.s   .DONE                     ; If not as expected, no DUART...
 
    move.b  #$50,DUART_IVR(A0)        ; To further verify, try to set IVR
    move.b  DUART_IVR(A0),D0          ; And then check it was set...
    cmp.b   #$50,D0                   ; to 0x50.
    bne.s   .DONE                     ; If not as expected, no DUART...

    ; If any of that generated a bus error, then it doesn't appear to be a 68681...
    tst.b   BERR_FLAG                 ; Was there a bus error?
    bne.s   .DONE                     ; Bail now if so...

    ; Looks like we successfully detected a 68681!
    
    ifnd REVISION1X
    move.b  #$08,W_OPR_SETCMD(A0)     ; Enable red LED on r2.x boards
    endif

    move.b  #1,D5                     ; Set D5 to indicate to INITSDB that there's a DUART present...
 .DONE:
    move.l  BERR_SAVED,$8             ; Restore bus error handler
    rts


; PRINT null-terminated string pointed to by A0 to UART A
;
; Only used directly during early init; Becomes the default implementation
; of FW_PRINT (pointed to by the EFP table) and likely replaced later.
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINT_DUART:
    move.l  A1,-(A7)                  ; Save A1...
    move.l  SDB_UARTBASE,A1           ; ... and get DUART base address

.LOOP
    move.b  (A0)+,D0                  ; Get next character
    beq.s   .PRINT_DONE               ; ... we're done if its null.

.BUFF_WAIT:
    btst.b  #3,DUART_SRA(A1)
    beq.s   .BUFF_WAIT
    move.b  D0,DUART_TBA(A1)
    
    bra.s   .LOOP                     ; and loop
.PRINT_DONE:
    move.l  (A7)+,A1                  ; Restore A1
    rts                               ; We're done


; PRINT null-terminated string pointed to by A0 followed by CRLF to UART A
; 
; Only used directly during early init; Becomes the default implementation
; of FW_PRINT (pointed to by the EFP table) and likely replaced later.
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINTLN_DUART:
    bsr.s   EARLY_PRINT_DUART         ; Print callers message
    move.l  A0,-(A7)                  ; Stash A0 to restore later
    
    lea     SZ_CRLF,A0                ; Load CRLF...
    bsr.s   EARLY_PRINT_DUART         ; ... and print it
        
    move.l  (A7)+,A0                  ; Restore A0
    rts


; Check if a character is ready to receive via UART A
;
; Trashes: UART registers
; Modifies: D0.B (return = 0 if no character waiting, nonzero otherwise)
CHECKCHAR_DUART:
    move.l  A0,-(A7)              ; Stash A0
    move.l  SDB_UARTBASE,A0       ; Get DUART base address
    move.b  DUART_SRA(A0),D0      ; Get RSR
    andi.b  #1,D0                 ; And with buffer full bit
    move.l  (A7)+,A0              ; Restore A0
    rts


; Char device handler - Check if a character is ready to receive via UART A
;
; Arguments: A0 - Should point to device block
;
; Trashes: A0, UART registers
; Modifies: D0.B (return = 0 if no character waiting, nonzero otherwise)
D_CHECKCHAR_DUART_A:
    move.l  (A0),A0               ; Get DUART base address
    move.b  DUART_SRA(A0),D0      ; Get RSR
    andi.b  #1,D0                 ; And with buffer full bit
    rts


; Char device handler - Check if a character is ready to receive via UART B
;
; Arguments: A0 - Should point to device block
;
; Trashes: A0, UART registers
; Modifies: D0.B (return = 0 if no character waiting, nonzero otherwise)
D_CHECKCHAR_DUART_B:
    move.l  (A0),A0               ; Get DUART base address
    move.b  DUART_SRB(A0),D0      ; Get RSR
    andi.b  #1,D0                 ; And with buffer full bit
    rts


; Send a single character via UART A
;
; Arguments: D0.B - Character to send
;
; Trashes: UART registers
; Modifies: Nothing
SENDCHAR_DUART:
    move.l  A0,-(A7)              ; Stash A0
    move.l  SDB_UARTBASE,A0       ; Get DUART base address
.BUSYLOOP
    btst.b  #3,DUART_SRA(A0)
    beq.s   .BUSYLOOP
    move.b  D0,DUART_TBA(A0)
    move.l  (A7)+,A0              ; Restore A0
    rts


; Char device handler - Send a single character via UART A
;
; Arguments: A0 - Should point to device block
; Arguments: D0.B - Character to send
;
; Trashes: A0, UART registers
; Modifies: Nothing
D_SENDCHAR_DUART_A:
    move.l  (A0),A0               ; Get DUART base address
.BUSYLOOP
    btst.b  #3,DUART_SRA(A0)
    beq.s   .BUSYLOOP
    move.b  D0,DUART_TBA(A0)
    rts


; Char device handler - Send a single character via UART B
;
; Arguments: A0 - Should point to device block
; Arguments: D0.B - Character to send
;
; Trashes: A0, UART registers
; Modifies: Nothing
D_SENDCHAR_DUART_B:
    move.l  (A0),A0               ; Get DUART base address
.BUSYLOOP
    btst.b  #3,DUART_SRB(A0)
    beq.s   .BUSYLOOP
    move.b  D0,DUART_TBB(A0)
    rts


; Receive a single character via UART A
; Ignores overrun errors.
;
; Trashes: UART registers
; Modifies: D0 (return)
RECVCHAR_DUART:
    move.l  A0,-(A7)              ; Stash A0
    move.l  SDB_UARTBASE,A0       ; Get DUART base address
.BUSYLOOP
    btst.b  #0,DUART_SRA(A0)
    beq.s   .BUSYLOOP
    move.b  DUART_RBA(A0),D0
    move.l  (A7)+,A0              ; Restore A0
    rts


; Char device handler - Receive a single character via UART A
; Ignores overrun errors.
;
; Arguments: A0 - Should point to device block
;
; Trashes: A0, UART registers
; Modifies: D0 (return)
D_RECVCHAR_DUART_A:
    move.l  (A0),A0               ; Get DUART base address
.BUSYLOOP
    btst.b  #0,DUART_SRA(A0)
    beq.s   .BUSYLOOP
    move.b  DUART_RBA(A0),D0
    rts


; Char device handler - Receive a single character via UART B
; Ignores overrun errors.
;
; Arguments: A0 - Should point to device block
;
; Trashes: A0, UART registers
; Modifies: D0 (return)
D_RECVCHAR_DUART_B:
    move.l  (A0),A0               ; Get DUART base address
.BUSYLOOP
    btst.b  #0,DUART_SRB(A0)
    beq.s   .BUSYLOOP
    move.b  DUART_RBB(A0),D0
    rts

; Device control handler for UART A
;
; Arguments: A0   - Should point to device block
;            D0.B - Command (Rest of D0 may be used for extra params)
;            D2.L - Command-specific parameter
;
; Trashes: A0, D2
; Modifies: D0.L (command-specific return), DUART registers
;
D_CTRL_DUART_A:
    tst.b   D0                    ; We only have command 0 so far...
    bne.s   .badcommand

    move.l  (A0),A0               ; Get DUART base address

    ; Set baudrate command - D1.B contains receiver (high nibble)
    ; and transmitter (low nibble) baud selection, taken from 
    ; Bit Rate Set 2 in Table 9 of the XR68C681 datasheet.
    move.b  D1,DUART_CSRA(A0)     ; Set DUART_CSRA with argument
    moveq.l #1,D0
    bra.s   .done

.badcommand
    clr.l   D0

.done
    rts

; Device control handler for UART B
;
; Arguments: A0   - Should point to device block
;            D0.B - Command (Rest of D0 may be used for extra params)
;            D2.L - Command-specific parameter
;
; Trashes: A0, D2
; Modifies: D0.L (command-specific return), DUART registers
;
D_CTRL_DUART_B:
    tst.b   D0                    ; We only have command 0 so far...
    bne.s   .badcommand

    move.l  (A0),A0               ; Get DUART base address

    ; Set baudrate command - D1.B contains receiver (high nibble)
    ; and transmitter (low nibble) baud selection, taken from 
    ; Bit Rate Set 2 in Table 9 of the XR68C681 datasheet.
    move.b  D1,DUART_CSRB(A0)     ; Set DUART_CSRB with argument
    moveq.l #1,D0
    bra.s   .done

.badcommand
    clr.l   D0

.done
    rts

    endif
