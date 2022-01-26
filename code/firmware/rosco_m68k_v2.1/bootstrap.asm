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
; This is the main bootstrap code for the system. 
; It sets up the exception handlers, initializes the hardware
; including the UART and system timers, sets up the basic
; info in the System Data Block, enables interrupts and 
; calls the main stage1 loader (in main1.c).
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    section .text

SHALLOW_RESET::
    bsr.w   INITSDB
    bsr.w   INITEFP

    ifd REVISION1X 
    jsr     INITMFP                   ; Initialise MC68901
    endif
    ifnd NO_68681
    jsr     INITDUART                 ; Initialise MC68681
    endif

    bsr.w   INITMEMCOUNT              ; Initialise memory count in SDB    
    bsr.s   PRINT_BANNER

    ifd REVISION1X
    ifd NO_TICK
    bset.b  #1,MFP_GPDR               ; Turn off GPIO #1 (Red LED) as no tick to reset it later..
    else
    bclr.b  #1,MFP_GPDR               ; Turn on GPIO #1 (Red LED)
    endif
    endif

    and.w   #$F2FF,SR                 ; Enable interrupts (except video)
  
    jmp     linit                     ; Init C land, calls through to main1

; main1 is noreturn, so That's All, Folks(tm).

;------------------------------------------------------------
; Subroutines
;
; Show banner
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
PRINT_BANNER:
    lea.l   SZ_BANNER0,A0             ; Load first string into A0
    move.l  EFP_PRINTLN,A3            ; Load function into A3
    
    jsr     (A3)                      ; Print all the banner lines
    
    rts                               ; We're done


; Initialise System Data Block
;
INITSDB:
    move.l  #$B105D47A,SDB_MAGIC      ; Magic
    move.l  #$C001C001,SDB_STATUS     ; OK OSHI Code
    move.w  #50,SDB_TICKCNT           ; Heartbeat flash counter at 50 (1 per second)
    move.w  #$FF00,SDB_SYSFLAGS       ; Initial system flags word (enable LEDs and CTS)
    move.b  #0,SDB_INTFLAGS           ; Initial internal flags
    move.l  #0,SDB_UPTICKS            ; Zero upticks

    jsr     INIT_CPU_TYPE

    rts
    

; Initialise Extension Function Pointer Table
;
INITEFP:
    ; Basic IO Routines
    move.l  #EFP_DUMMY_NOOP,EFP_PRINT
    move.l  #EFP_DUMMY_NOOP,EFP_PRINTLN
    move.l  #EFP_DUMMY_NOOP,EFP_PRINTCHAR
    move.l  #EFP_DUMMY_NOOP,EFP_SENDCHAR
    move.l  #EFP_DUMMY_LOOP,EFP_RECVCHAR
    move.l  #EFP_DUMMY_NOOP,EFP_CLRSCR
    move.l  #EFP_DUMMY_NOOP,EFP_MOVEXY
    move.l  #EFP_DUMMY_NOOP,EFP_SETCURSOR
    move.l  #EFP_DUMMY_ZERO_D0B,EFP_CHECKCHAR

    ; Block Device IO Routines - SD
    move.l  #EFP_DUMMY_NEGONE_D0L,EFP_SD_INIT
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SD_READ
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SD_WRITE
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SD_REG

    ; Block Device IO Routines - SPI
    move.l  #EFP_DUMMY_NEGONE_D0L,EFP_SPI_INIT
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SPI_CS_A
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SPI_CS_D
    move.l  #EFP_DUMMY_NEGONE_D0L,EFP_SPI_XFER_B
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SPI_XFER_M
    move.l  #EFP_DUMMY_NEGONE_D0L,EFP_SPI_RECV_B    
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SPI_RECV_M
    move.l  #EFP_DUMMY_NOOP,EFP_SPI_SEND_B
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_SPI_SEND_M

    ; Block Device IO Routines - ATA
    move.l  #EFP_DUMMY_NEGONE_D0L,EFP_ATA_INIT
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_ATA_READ
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_ATA_WRITE
    move.l  #EFP_DUMMY_ZERO_D0L,EFP_ATA_IDENT

    ; System Routines
    move.l  #HALT,EFP_HALT
    move.l  #SHALLOW_RESET,EFP_PROGLOADER
    move.l  #SHALLOW_RESET,EFP_PROG_EXIT

    rts

EFP_DUMMY_NOOP::
    rts
EFP_DUMMY_LOOP::
    bra     EFP_DUMMY_LOOP
    rts
EFP_DUMMY_ZERO_D0B::
    move.b  #0,D0
    rts
EFP_DUMMY_ZERO_D0W::
    move.w  #0,D0
    rts
EFP_DUMMY_ZERO_D0L::
    move.l  #0,D0
    rts
EFP_DUMMY_NEGONE_D0B::
    move.b  #-1,D0
    rts
EFP_DUMMY_NEGONE_D0W::
    move.w  #-1,D0
    rts
EFP_DUMMY_NEGONE_D0L::
    move.l  #-1,D0
    rts


; Count size of the first block of contiguous memory,
; and store it in the SDB.
INITMEMCOUNT:
.TESTVALUE equ $12345678
.BLOCKSIZE equ $80000

    ifd REVISION1X
.MEMTOP    equ $F80000
    else
.MEMTOP    equ $E00000
    endif

    move.b  #0,BERR_FLAG              ; Zero bus error flag
    move.l  $8,BERR_SAVED             ; Save the original bus error handler
    move.l  #BERR_HANDLER,$8          ; Install temporary bus error handler
    move.l  #.BLOCKSIZE,A0
.LOOP
    move.l  #.TESTVALUE,(A0)
    move.l  (A0),D0

    tst.b   BERR_FLAG                 ; Was there a bus error?
    bne.s   .DONE                     ; Fail fast if so...

    cmp.l   #.TESTVALUE,D0            ; Did we get test value back?
    bne.s   .DONE                     ; Fail fast if not...

    cmp.l   #.MEMTOP,A0               ; Are we at the top of memory?
    beq.s   .DONE                     ; We're done if so...

    add.l   #.BLOCKSIZE,A0            ; Failing all that...
    bra.s   .LOOP                     ; ... continue testing.

.DONE
    move.l  BERR_SAVED,$8             ; Restore bus error handler
    move.l  A0,SDB_MEMSIZE
    rts

; Temporary bus error handler, in case no MC68681 is installed
BERR_HANDLER::
    move.l  D0,-(A7)
    move.w  ($A,A7),D0                ; Get format
    and.w   #$F000,D0                 ; Mask vector
    cmp.w   #$8000,D0                 ; Is it an 010 BERR frame?
    bne.w   .NOT010                   ; May be a longer (later CPU) frame if not
                                      ; For 020, this would be either A000 or B000 -
                                      ; for our purposes, they are equivalent. 
                                      ; TODO this might need checking again on later
                                      ; CPUs!

    move.w  ($C,A7),D0                ; If we're here, it's an 010 frame...                
    bset    #15,D0                    ; ... so just set the RR (rerun) flag
    move.w  D0,($C,A7)
    bra.s   .DONE 

.NOT010:
    cmp.w   #$A000,D0                 ; Is it an 020 BERR frame?
    beq.w   .IS020 
    cmp.w   #$B000,D0
    beq.w   .IS020 

    ; If we're here, assume it's a 68000.
    ; We can't return from a bus error, signal error.
    move.l  (A7)+,D0
    jmp     BUS_ERROR_HANDLER

.IS020
    move.w  ($E,A7),D0                ; If we're here, it's an 020 frame...                
    bclr    #8,D0                     ; ... we only care about data faults here... Hopefully :D
    move.w  D0,($E,A7)    

.DONE
    move.b  #1,BERR_FLAG
    move.l  (A7)+,D0
    rte
    

; Convenience to install temporary BERR handler from C
; Zeroes bus error flag (at BERR_FLAG) and stores old handler
; for a subsequent RESTORE_BERR_HANDLER.
INSTALL_TEMP_BERR_HANDLER::
    move.b  #0,BERR_FLAG              ; Zero bus error flag

    move.l  $8,BERR_SAVED             ; Save the original bus error handler
    move.l  #BERR_HANDLER,$8          ; Install temporary bus error handler
    rts

; Convenience to restore BERR handler from C, after a
; call to INSTALL_TEM_BERR_HANDLER.
RESTORE_BERR_HANDLER::
    move.l  BERR_SAVED,$8             ; Restore bus error handler
    rts

    
;------------------------------------------------------------
; Routines for include/machine.h
HALT::
    jsr     STOP_HEART
    stop    #$2700
    bra.s   HALT

SET_INTR::
    ; TODO Not yet implemented
    rts

;------------------------------------------------------------
; Exception handlers    
TICK_HANDLER::
    move.l  D0,-(A7)                  ; Save D0

    ifnd REVISION1X
    move.l  A0,-(A7)                  ; Check if this is a counter interrupt...
    move.l  SDB_UARTBASE,A0
    move.b  R_ISR(A0),D0
    btst    #3,D0   
    bne.s   .COUNTER                  ; Continue if so,
    
    move.l  (A7)+,A0                  ; Else restore regs...
    move.l  (A7)+,D0
    rte                               ; ...and bail.

.COUNTER
    endif

    move.l  D1,-(A7)                  ; Save D1

    ; Increment upticks
    move.l  SDB_UPTICKS,D0            ; Read SDB dword at 12
    add.l   #1,D0                     ; Increment
    move.l  D0,SDB_UPTICKS            ; And write back
    
    ; Heartbeat
; ============
    ifd REVISION1X
    move.w  SDB_TICKCNT,D0            ; Read SDB word at 8
    tst.w   D0                        ; Is it zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 (if allowed) 
    ; and reset counter
    move.b  SDB_SYSFLAGS,D0           ; Get sysflags (high byte)

    move.b  MFP_GPDR,D1               ; Get GPDR
    eor.b   #1,D1                     ; Toggle bit 0
    and.b   D0,D1                     ; Mask with flags
    move.b  D1,MFP_GPDR               ; Set GPDR

    move.w  #50,D0                    ; Reset counter

; ============
    else
; ============

    move.l  SDB_UARTBASE,A0           ; And fetch UART base pointer

    move.w  SDB_TICKCNT,D0            ; Read SDB word at 8
    tst.w   D0                        ; Is LSB zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 (if allowed) 
    ; and reset counter
    move.b  SDB_SYSFLAGS,D1           ; Get sysflags (high byte)
    btst    #1,D1                     ; Is sysflag bit 1 set?
    beq.s   .TICKRESET                ; bail now if not...

    move.b  SDB_INTFLAGS,D1
    tst.b   D1                        ; Is INTFLAGS zero?
    beq.s   .TURNON                   ; If so, go to turn on
    
    ; If here, LED is already on, turn it off
    move.b  #$20,W_OPR_RESETCMD(A0)   ; Turn it off
    move.b  #0,D1
    bra.s   .LEDDONE                  ; And we're done

.TURNON
    ; LED is off, turn it on
    move.b  #$20,W_OPR_SETCMD(A0)     ; Turn it on
    move.b  #1,D1
    
.LEDDONE
    move.b  D1,SDB_INTFLAGS

.TICKRESET
    move.w  #50,D0                    ; Reset counter
    
    endif
; ============

.TICK_HANDLER_DONE:

    sub.w   #$1,D0                    ; Decrement counter...
    move.w  D0,SDB_TICKCNT            ; ... and write back to SDB
    move.l  (A7)+,D1                  ; Restore D1

    ifnd REVISION1X
; ============
    move.b  R_STOPCNTCMD(A0),D0       ; Clear ISR[3]
    move.l  (A7)+,A0                  ; Restore A0
; ============
    else
; ============
    move.b  #~$20,MFP_ISRB            ; Clear interrupt-in-service
; ============
    endif
    
    move.l  (A7)+,D0                  ; Restore D0

    rte                               ; We're done

    
; Call busywait from C code...
BUSYWAIT_C::
    move.l  (4,A7),D0
    jmp     BUSYWAIT

BUS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    ifd REVISION1X
; ============
    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #100000,D0                ; Wait a while
    bsr.s   BUSYWAIT

    ifd REVISION1X
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif
    
    move.l  #200000,D0                ; Wait a while
    bsr.s   BUSYWAIT
    bra.s   BUS_ERROR_HANDLER
    
    rte                               ; Never reached

; Busywait - expects a delay in D0, returns when D0 gets to 0 
;
; Trashes: D0
BUSYWAIT:
    sub.l   #1,D0
    tst.l   D0
    bne.s   BUSYWAIT
    rts

ADDRESS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions
    
    ifd REVISION1X
; ============
    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.s   BUSYWAIT

    ifd REVISION1X
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.s   BUSYWAIT

    ifd REVISION1X    
; ============
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    ifd REVISION1X    
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif

    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    bra.s   ADDRESS_ERROR_HANDLER
    
    rte                               ; Never reached

ILLEGAL_INSTRUCTION_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    ifd REVISION1X
; ============
    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output

    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    ifd REVISION1X
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    
    ifd REVISION1X
; ============
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    ifd REVISION1X
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    
    ifd REVISION1X
; ============
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED on r2.x boards
; ============
    endif

    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    ifd REVISION1X
; ============
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
; ============
    else
; ============
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED on r2.x boards
; ============
    endif

    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    bra.w   ILLEGAL_INSTRUCTION_HANDLER
    
    rte                               ; Never reached

GENERIC_HANDLER::
    move.l  #$2BADB105,SDB_STATUS
    rte


; Convenience SEND/RECV char functions, using the EFP table.
; These are provided for use by the Easy68k syscalls.S
;
; TODO these should be moved to syscalls_asm.S!
SENDCHAR::
    move.l  A3,-(A7)
    move.l  EFP_SENDCHAR,A3
    jsr     (A3)
    move.l  (A7)+,A3
    rts

RECVCHAR::
    move.l  A3,-(A7)
    move.l  EFP_RECVCHAR,A3
    jsr     (A3)
    move.l  (A7)+,A3
    rts


;------------------------------------------------------------
; Consts 
    section .rodata

SZ_BANNER0      dc.b    $D, $A, $1B, "[1;33m                                 ___ ___ _", $D, $A
SZ_BANNER1      dc.b    " ___ ___ ___ ___ ___       _____|  _| . | |_ ", $D, $A
SZ_BANNER2      dc.b    "|  _| . |_ -|  _| . |     |     | . | . | '_|", $D, $A
SZ_BANNER3      dc.b    "|_| |___|___|___|___|_____|_|_|_|___|___|_,_|", $D, $A
SZ_BANNER4      dc.b    "                    |_____|", $1B, "[1;37m  Classic ", $1B, "[1;30m2.20.DEV", $1B, "[0m", $D, $A, 0

SZ_CRLF::       dc.b    $D, $A, 0
