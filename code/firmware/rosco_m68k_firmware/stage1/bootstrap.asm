;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is the main bootstrap code for the system. 
; It sets up the exception handlers, initializes the hardware
; including the UART and system timers, sets up the basic
; info in the System Data Block, enables interrupts and 
; calls the main stage1 loader (in main1.c).
;------------------------------------------------------------
    include "../../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    section .text

VECTORS:
    dc.l    STAGE2_LOAD                 ; 00: Stack (below stage2)
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
    dc.l    GENERIC_HANDLER             ; 2D: TRAP#13 handler (replaced later)
    dc.l    TRAP_14_HANDLER             ; 2E: TRAP#14 handler
    dc.l    GENERIC_HANDLER             ; 2F: TRAP#15 handler (replaced later)
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

    ; Dummy Supervisor Data access to $X40000-$XBFFFF to exit boot mode.
    move.w  $A4FC,$040000               ; Write ILLEGAL instruction to kernel load address.

    bsr.w   INITSDB                     ; Initialise System Data Block
    bsr.w   INITEFPT                    ; Initialise Extension Function Pointer Table
    bsr.w   INITDEVS                    ; Initialise device blocks

    ifd REVISION1X 
    jsr     INITMFP                     ; Initialise MC68901
    endif
    ifnd NO_68681
    jsr     INITDUART                   ; Initialise MC68681
    endif

    bsr.w   INITMEMCOUNT                ; Initialise memory count in SDB

    ifnd NO_BANNER
    ifnd LATE_BANNER 
    bsr.s   PRINT_BANNER
    endif
    endif

    ifd REVISION1X
    ifd NO_TICK
    bset.b  #1,MFP_GPDR                 ; Turn off GPIO #1 (Red LED) as no tick to reset it later..
    else
    bclr.b  #1,MFP_GPDR                 ; Turn on GPIO #1 (Red LED)
    endif
    endif

    and.w   #$F2FF,SR                   ; Enable interrupts (except video)

    move.l  EFP_RECVCHAR,EFP_INPUTCHAR  ; Default to UART for input, may get switched to keyboard later...
    move.l  EFP_CHECKCHAR,EFP_CHECKINPUT

    jmp     linit                       ; Init C land, calls through to main1

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
    move.b  #0,SDB_XOSERABASE           ; Initial internal flags
    move.l  #0,SDB_UPTICKS              ; Zero upticks
    move.l  #RAMLIMIT,SDB_MEMSIZE       ; Default memory size
    move.l  #0,SDB_UARTBASE             ; Clear before UART detection

    jsr     INIT_CPU_TYPE

    rts
    

; Initialise Extension Function Pointer Table
;
INITEFPT:
    ; Basic IO Routines
    move.l  #EFP_DUMMY_ENDSTR,EFP_PRINT
    move.l  #EFP_DUMMY_ENDSTR,EFP_PRINTLN
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
    move.l  #START,EFP_PROGLOADER       ; This shouldn't be called until replaced
    move.l  #START,EFP_PROG_EXIT

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
EFP_DUMMY_ENDSTR::
    tst.b   (A0)+
    bne     EFP_DUMMY_ENDSTR
    rts


; Initialize device blocks
INITDEVS:
    clr.w   DEVICE_COUNT    
    move.w  #C_NUM_DEVICES,D0
    mulu.w  #(C_DEVICE_SIZE/4),D0   ; Divide by 4 because we clear long words
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

    jsr     INSTALL_TEMP_BERR_HANDLER   ; Install temporary bus error handler
    move.l  #.POST_TEST,BERR_CONT_ADDR  ; Save continuation address for 68000
    move.l  #.BLOCKSIZE,A0
.LOOP
    move.l  #.TESTVALUE,(A0)
    nop                                 ; NOP freezes instruction execution until pending...
    move.l  (A0),D0                     ; ... bus cycles complete on MC68020 and above

.POST_TEST:
    tst.b   BERR_FLAG                   ; Was there a bus error?
    bne.s   .DONE                       ; Fail fast if so...

    cmp.l   #.TESTVALUE,D0              ; Did we get test value back?
    bne.s   .DONE                       ; Fail fast if not...

    cmp.l   #EXPTOP,A0                  ; Are we at the top of memory?
    beq.s   .DONE                       ; We're done if so...

    add.l   #.BLOCKSIZE,A0              ; Failing all that...
    bra.s   .LOOP                       ; ... continue testing.

.DONE
    jsr     RESTORE_BERR_HANDLER        ; Restore bus error handler
    move.l  #1048576,SDB_MEMSIZE ;A0,SDB_MEMSIZE
    rts


; Temporary bus error handler for the MC68000 CPU
;
; Requires a return address be placed in BERR_CONT_ADDR since
; the MC68000 cannot return from bus errors.
;
BERR_HANDLER_MC68000::
    ; Set up the stack with the supplied return address for rte
    move.b  #1,BERR_FLAG
    addq.l  #8,A7
    move.l  BERR_CONT_ADDR,2(A7)
    rte


; Temporary bus error handler for other MC680x0 CPUs
;
BERR_HANDLER_MC680X0::
    move.l  D0,-(A7)
    move.w  ($A,A7),D0                  ; Get format
    and.w   #$F000,D0                   ; Mask vector

    cmp.w   #$8000,D0                   ; Is it an 010 BERR frame?
    beq.w   .IS010                      ; May be a longer (later CPU) frame if not

.NOT010
    cmp.w   #$A000,D0                   ; Is it an 020 (030) BERR frame?
    beq.w   .IS020 
    cmp.w   #$B000,D0
    beq.w   .IS020 

.NOT020
    ; If we're here, we don't support this CPU, fall back on saved BERR handler
    move.l  (A7)+,D0
    jmp     (BERR_SAVED).l

.IS010
    move.w  ($C,A7),D0                  ; If we're here, it's an 010 frame...                
    bset    #15,D0                      ; ... so just set the RR (rerun) flag to software rerun
    move.w  D0,($C,A7)
    bra.s   .DONE

.IS020
    move.w  ($E,A7),D0                  ; If we're here, it's an 020 frame...
    btst    #8,D0                       ; ... check that this is a data fault
    bne.w   .IS020_DAT
.IS020_NONDAT                           ; It's not a data fault...
    move.l  (A7)+,D0                    ; ... so fall back to the saved BERR handler
    jmp     (BERR_SAVED)
.IS020_DAT
    bclr    #8,D0                       ; Is a data fault, so clear the DF flag to skip rerun
    move.w  D0,($E,A7)    

.DONE
    move.b  #1,BERR_FLAG
    move.l  (A7)+,D0
    rte


; Install temporary BERR handler
; Zeroes bus error flag (at BERR_FLAG) and stores old handler
; for a subsequent RESTORE_BERR_HANDLER.
INSTALL_TEMP_BERR_HANDLER::
    move.b  #0,BERR_FLAG                ; Zero bus error flag
    move.l  $8,BERR_SAVED               ; Save the original bus error handler
    cmpi.b  #$20,SDB_CPUINFO+0          ; Compare the CPU model in SDB (highest 3 bits) against 1
    blt     .IS000                      ; Is it an MC68000?
.NOT000
    move.l  #BERR_HANDLER_MC680X0,$8    ; Install other MC680x0 temporary bus error handler
    rts
.IS000
    move.l  #BERR_HANDLER_MC68000,$8    ; Install MC68000 temporary bus error handler
    rts


; Restore BERR handler, after a call to INSTALL_TEMP_BERR_HANDLER.
RESTORE_BERR_HANDLER::
    move.l  BERR_SAVED,$8               ; Restore bus error handler
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
GENERIC_HANDLER::
    move.l  #$2BADB105,SDB_STATUS
    rte


;------------------------------------------------------------
; Char devices
    section .early_data
DEVICE_COUNT::      dc.w    0
DEVICE_BLOCKS::     ds.b    C_DEVICE_SIZE*C_NUM_DEVICES
BERR_CONT_ADDR::    ds.l    1

; Consts 
    section .rodata

SZ_BANNER0      dc.b    $D, $A, $1B, "[1;33m"
SZ_BANNER1      dc.b    "                                 ___ ___ _   ", $D, $A
SZ_BANNER2      dc.b    " ___ ___ ___ ___ ___       _____|  _| . | |_ ", $D, $A
SZ_BANNER3      dc.b    "|  _| . |_ -|  _| . |     |     | . | . | '_|", $D, $A
SZ_BANNER4      dc.b    "|_| |___|___|___|___|_____|_|_|_|___|___|_,_|", $D, $A
SZ_BANNER5      dc.b    "                    |_____|", $1B, "[1;37m  Classic ", $1B, "[1;30m2.50.DEV", $1B, "[0m", $D, $A, 0

SZ_CRLF::       dc.b    $D, $A, 0
