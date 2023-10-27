;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|        Translator
;------------------------------------------------------------
; Copyright (c)2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is the main bootstrap code for the translator 
; system. It does the minimum necessary to implement
; the translation layer.
;------------------------------------------------------------
    include "rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    section .text

VECTORS:
    dc.l    $100000                     ; 00: Stack (top of on-board RAM)
    dc.l    START                       ; 01: Initial PC (start of ROM code)

    dc.l    BUS_ERROR_HANDLER           ; 02: Bus Error
    dc.l    ADDRESS_ERROR_HANDLER       ; 03: Address Error
    dc.l    ILLEGAL_INSTRUCTION_HANDLER ; 04: Illegal Instruction
    dc.l    GENERIC_HANDLER             ; 05: Divide by Zero
    dc.l    GENERIC_HANDLER             ; 06: CHK Instruction
    dc.l    GENERIC_HANDLER             ; 07: TRAPV Instruction
    dc.l    GENERIC_HANDLER             ; 08: Privilege Violation
    dc.l    GENERIC_HANDLER             ; 09: Trace
    dc.l    GENERIC_HANDLER             ; 0A: Line 1010 Emulator
    dc.l    GENERIC_HANDLER             ; 0B: Line 1111 Emulator
    dc.l    GENERIC_HANDLER             ; 0C: Reserved
    dc.l    GENERIC_HANDLER             ; 0D: Reserved
    dc.l    GENERIC_HANDLER             ; 0E: Format error (MC68010 Only)
    dc.l    GENERIC_HANDLER             ; 0F: Uninitialized Vector

    dcb.l   8,GENERIC_HANDLER           ; 10-17: Reserved

    dc.l    GENERIC_HANDLER             ; 18: Spurious Interrupt

    dcb.l   7,GENERIC_HANDLER           ; 19-1F: Level 1-7 Autovectors
    dcb.l   13,GENERIC_HANDLER          ; 20-2C: TRAP Handlers (unused)
    dc.l    TRAP_13_HANDLER             ; 2D: TRAP#13 handler
    dc.l    TRAP_14_HANDLER             ; 2E: TRAP#14 handler
    dc.l    EASY68K_TRAP_15_HANDLER     ; 2F: TRAP#15 handler
    dcb.l   16,GENERIC_HANDLER          ; 30-3F: Remaining Reserved vectors
    dcb.l   4,GENERIC_HANDLER           ; 40-43: MFP GPIO #0-3 (Not used)
    dc.l    GENERIC_HANDLER             ; 44: MFP Timer D (Interrupt not used)
    dc.l    TICK_HANDLER                ; 45: MFP Timer C (System tick)
    dcb.l   2,GENERIC_HANDLER           ; 46-47: MFP GPIO #4-5 (Not used)
    dc.l    GENERIC_HANDLER             ; 48: MFP Timer B (Not used)
    dc.l    GENERIC_HANDLER             ; 49: Transmitter error (Not used)
    dc.l    GENERIC_HANDLER             ; 4A: Transmitter empty (Replaced later)
    dc.l    GENERIC_HANDLER             ; 4B: Receiver error (Replaced later)
    dc.l    GENERIC_HANDLER             ; 4C: Receiver buffer full (Replaced later)
    dc.l    GENERIC_HANDLER             ; 4D: Timer A (Not used)
    dcb.l   2,GENERIC_HANDLER           ; 4E-4F: MFP GPIO #6-7 (Not used)
    dcb.l   176,GENERIC_HANDLER         ; 50-FF: Unused user vectors
VECTORS_END:
VECTORS_COUNT   equ     256

VERSION:
    dc.l    RELEASE_VER                 ; Embed the release version in ROM


START::
    or.w    #$0700,SR                   ; Disable interrupts for now

    ; Copy exception vectors table to RAM at VECTORS_LOAD (0x00000000).
    ; VBR defaults to that location anyway for 68000 compatibility.
    lea     (VECTORS),A0                ; Vectors in ROM into A0 (source)
    lea     (VECTORS_LOAD),A1           ; Vectors in RAM into A1 (destination)
    move.l  #VECTORS_COUNT,D0           ; Count into D0 (DBcc only uses word size)
    bra     .ISR_COPY_START             ; Jump to DBcc to start loop
.ISR_COPY_LOOP:
    move.l  (A0)+,(A1)+                 ; Copy long source to dest, with postincrement.
.ISR_COPY_START:
    dbf     D0,.ISR_COPY_LOOP           ; Decrement D0 and loop if not negative, ignore cc

    ; HACK! Replace reset vector for when program exits...
    move.l  #XL_EXIT,4                  
    
    bsr.w   INITSDB                     ; Initialise System Data Block
    bsr.w   INITEFPT                    ; Initialise Extension Function Pointer Table
    bsr.w   INITDEVS                    ; Initialise device blocks
    bsr.w   INITMEMCOUNT                ; Initialise memory count in SDB

    ; set up easy68k constants
    ; Make sure these are consistent with main.cpp
ECHO_ON             equ     $410
PROMPT_ON           equ     $411
LF_DISPLAY          equ     $412

    move.b  #1,ECHO_ON
    move.b  #1,PROMPT_ON
    move.b  #1,LF_DISPLAY
    ; end of easy68k setup

    ifnd NO_BANNER
    ifnd LATE_BANNER 
    bsr.s   PRINT_BANNER
    endif
    endif

    and.w   #$F2FF,SR                   ; Enable interrupts (except video)

    jsr    $40000                      ; Init C land, calls through to main1

    jmp    HALT

; main1 is noreturn, so That's All, Folks(tm).


;------------------------------------------------------------
; Subroutines
;
; Show banner
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
    ifnd NO_BANNER  
    ifd LATE_BANNER
PRINT_BANNER::
    else
PRINT_BANNER:
    endif
    lea.l   SZ_BANNER0,A0               ; Load first string into A0
    move.l  EFP_PRINTLN,A3              ; Load function into A3
    
    jsr     (A3)                        ; Print all the banner lines
    
    rts                                 ; We're done
    endif


; Initialise System Data Block
;
INITSDB:
    move.l  #$B105D47A,SDB_MAGIC        ; Magic
    move.l  #$C001C001,SDB_STATUS       ; OK OSHI Code
    move.w  #50,SDB_TICKCNT             ; Heartbeat flash counter at 50 (1 per second)
    move.w  #$FF00,SDB_SYSFLAGS         ; Initial system flags word (enable LEDs and CTS)
    move.b  #0,SDB_INTFLAGS             ; Initial internal flags
    move.l  #0,SDB_UPTICKS              ; Zero upticks
    move.l  #RAMLIMIT,SDB_MEMSIZE       ; Default memory size
    move.l  #0,SDB_UARTBASE             ; Clear before UART detection

    jsr     INIT_CPU_TYPE

    rts
    

; Initialise Extension Function Pointer Table
;
INITEFPT:
    ; Basic IO Routines
    move.l  #XL_PRINT,EFP_PRINT
    move.l  #XL_PRINTLN,EFP_PRINTLN
    move.l  #XL_PRINTCHAR,EFP_PRINTCHAR
    move.l  #EFP_DUMMY_NOOP,EFP_SENDCHAR
    move.l  #XL_RECVCHAR,EFP_RECVCHAR
    move.l  #EFP_DUMMY_NOOP,EFP_CLRSCR
    move.l  #EFP_DUMMY_NOOP,EFP_MOVEXY
    move.l  #EFP_DUMMY_NOOP,EFP_SETCURSOR
    move.l  #XL_CHECKCHAR,EFP_CHECKCHAR

    ; Block Device IO Routines - SD
    move.l  #XL_SD_INIT,EFP_SD_INIT
    move.l  #XL_SD_READ,EFP_SD_READ
    move.l  #XL_SD_WRITE,EFP_SD_WRITE
    move.l  #XL_SD_REGISTER,EFP_SD_REG

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
    move.l  #START,EFP_PROGLOADER       ; This shouldn't be called until replaced
    move.l  #XL_EXIT,EFP_PROG_EXIT

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

XL_PRINT:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F0,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_PRINTLN:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F1,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_PRINTCHAR:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F2,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_EXIT:
    ; No need to save anything here, we're about to be killed...
    move.l  #$F0F0F0F3,D7
    move.l  #$AA55AA55,D6
    illegal
XL_CHECKCHAR:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F4,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_RECVCHAR:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F5,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_SD_INIT:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F6,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_SD_READ:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F7,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_SD_WRITE:
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  #$F0F0F0F8,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    rts
XL_SD_REGISTER:
    clr.l   d0
    rts


; Initialize device blocks
INITDEVS:
    clr.w   DEVICE_COUNT    
    move.w  #C_NUM_DEVICES,D0
    lsl.w   #3,D0
    lea.l   DEVICE_BLOCKS,A0
    bra.s   .START

.LOOP:
    clr.l   (A0)+

.START:
    dbra.w  D0,.LOOP
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

    move.b  #0,BERR_FLAG                ; Zero bus error flag
    move.l  $8,BERR_SAVED               ; Save the original bus error handler
    move.l  #BERR_HANDLER,$8            ; Install temporary bus error handler
    move.l  #.BLOCKSIZE,A0
.LOOP
    move.l  #.TESTVALUE,(A0)
    move.l  (A0),D0

    tst.b   BERR_FLAG                   ; Was there a bus error?
    bne.s   .DONE                       ; Fail fast if so...

    cmp.l   #.TESTVALUE,D0              ; Did we get test value back?
    bne.s   .DONE                       ; Fail fast if not...

    cmp.l   #.MEMTOP,A0                 ; Are we at the top of memory?
    beq.s   .DONE                       ; We're done if so...

    add.l   #.BLOCKSIZE,A0              ; Failing all that...
    bra.s   .LOOP                       ; ... continue testing.

.DONE
    move.l  BERR_SAVED,$8               ; Restore bus error handler
    move.l  A0,SDB_MEMSIZE
    rts


; Temporary bus error handler
BERR_HANDLER::
    move.l  D0,-(A7)
    move.w  ($A,A7),D0                  ; Get format
    and.w   #$F000,D0                   ; Mask vector
    cmp.w   #$8000,D0                   ; Is it an 010 BERR frame?
    bne.w   .NOT010                     ; May be a longer (later CPU) frame if not
                                        ; For 020, this would be either A000 or B000 -
                                        ; for our purposes, they are equivalent. 
                                        ; TODO this might need checking again on later
                                        ; CPUs!

    move.w  ($C,A7),D0                  ; If we're here, it's an 010 frame...                
    bset    #15,D0                      ; ... so just set the RR (rerun) flag
    move.w  D0,($C,A7)
    bra.s   .DONE 

.NOT010:
    cmp.w   #$A000,D0                   ; Is it an 020 BERR frame?
    beq.w   .IS020 
    cmp.w   #$B000,D0
    beq.w   .IS020 

    ; If we're here, assume it's a 68000.
    ; We can't return from a bus error, signal error.
    move.l  (A7)+,D0
    jmp     BUS_ERROR_HANDLER

.IS020
    move.w  ($E,A7),D0                  ; If we're here, it's an 020 frame...                
    bclr    #8,D0                       ; ... we only care about data faults here... Hopefully :D
    move.w  D0,($E,A7)    

.DONE
    move.b  #1,BERR_FLAG
    move.l  (A7)+,D0
    rte


; Convenience to install temporary BERR handler from C
; Zeroes bus error flag (at BERR_FLAG) and stores old handler
; for a subsequent RESTORE_BERR_HANDLER.
INSTALL_TEMP_BERR_HANDLER::
    move.b  #0,BERR_FLAG                ; Zero bus error flag

    move.l  $8,BERR_SAVED               ; Save the original bus error handler
    move.l  #BERR_HANDLER,$8            ; Install temporary bus error handler
    rts


; Convenience to restore BERR handler from C, after a
; call to INSTALL_TEM_BERR_HANDLER.
RESTORE_BERR_HANDLER::
    move.l  BERR_SAVED,$8               ; Restore bus error handler
    rts

    
;------------------------------------------------------------
; Routines for include/machine.h
HALT::
    stop    #$2700
    bra.s   HALT


SET_INTR::
    ; TODO Not yet implemented
    rts


; Call busywait from C code...
BUSYWAIT_C::
    move.l  (4,A7),D0
    jmp     BUSYWAIT


; Busywait - expects a delay in D0, returns when D0 gets to 0 
;
; Trashes: D0
BUSYWAIT::
    sub.l   #1,D0
    tst.l   D0
    bne.s   BUSYWAIT
    rts


;------------------------------------------------------------
; Exception handlers   
BUS_ERROR_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.l  #$2BADC0DE,SDB_STATUS
    stop    #$2700
    bra.s   BUS_ERROR_HANDLER


ADDRESS_ERROR_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.l  #$2BADDEAD,SDB_STATUS
    bra.s   BUS_ERROR_HANDLER


ILLEGAL_INSTRUCTION_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.l  #$2BADF00D,SDB_STATUS
    bra.s   BUS_ERROR_HANDLER


TICK_HANDLER:
    move.l  #$0071C70C,SDB_STATUS
    add.l   #1,SDB_UPTICKS
    rte


GENERIC_HANDLER:
    move.l  #$2BADB105,SDB_STATUS
    rte


;------------------------------------------------------------
; Char devices
    section .early_data
DEVICE_COUNT::  dc.w    0
DEVICE_BLOCKS:: ds.b    C_DEVICE_SIZE*C_NUM_DEVICES

; Consts 
    section .rodata

SZ_BANNER0      dc.b    $D, $A, $1B, "[1;33m"
SZ_BANNER1      dc.b    "                                 ___ ___ _   ", $D, $A
SZ_BANNER2      dc.b    " ___ ___ ___ ___ ___       _____|  _| . | |_ ", $D, $A
SZ_BANNER3      dc.b    "|  _| . |_ -|  _| . |     |     | . | . | '_|", $D, $A
SZ_BANNER4      dc.b    "|_| |___|___|___|___|_____|_|_|_|___|___|_,_|", $D, $A
SZ_BANNER5      dc.b    "                    |_____|", $1B, "[1;37m  Classic ", $1B, "[1;30m2.30.DEV", $1B, "[0m", $D, $A, 0

SZ_CRLF::       dc.b    $D, $A, 0
