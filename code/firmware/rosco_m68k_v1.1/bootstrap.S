;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2019 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; This is the main bootstrap code for the system. 
; It sets up the exception handlers, initializes the hardware
; including the UART and system timers, sets up the basic
; info in the System Data Block, enables interrupts and 
; calls the main loader (in lmain.c).
;------------------------------------------------------------
    include "../../shared/equates.S"

    section .text
    
    org     ROMBASE
RESET:
    dc.l    RAMLIMIT                    ; 00: Stack (top of on-board RAM)
    dc.l    START                       ; 01: Initial PC (start of ROM code)
    
VECTORS:
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
    dc.l    RESERVED_HANDLER            ; 0C: Reserved
    dc.l    RESERVED_HANDLER            ; 0D: Reserved
    dc.l    GENERIC_HANDLER             ; 0E: Format error (MC68010 Only)
    dc.l    GENERIC_HANDLER             ; 0F: Uninitialized Vector
    
    dcb.l   8,RESERVED_HANDLER          ; 10-17: Reserved
    
    dc.l    GENERIC_HANDLER             ; 18: Spurious Interrupt
    
    dcb.l   7,INTERRUPT_HANDLER         ; 19-1F: Level 1-7 Autovectors
    dcb.l   14,TRAP_HANDLER             ; 20-2D: TRAP Handlers (unused)
    dc.l    TRAP_14_HANDLER             ; 2E: TRAP#14 handler
    dc.l    TRAP_HANDLER                ; 2F: TRAP#15 handler (replaced later)
    dcb.l   16,RESERVED_HANDLER         ; 30-3F: Remaining Reserved vectors
    dcb.l   4,UNMAPPED_USER_HANDLER     ; 40-43: MFP GPIO #0-3 (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 44: MFP Timer D (Interrupt not used)
    dc.l    TICK_HANDLER                ; 45: MFP Timer C (System tick)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 46-47: MFP GPIO #4-5 (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 48: MFP Timer B (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 49: Transmitter error (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 4A: Transmitter empty (Replaced later)
    dc.l    UNMAPPED_USER_HANDLER       ; 4B: Receiver error (Replaced later)
    dc.l    UNMAPPED_USER_HANDLER       ; 4C: Receiver buffer full (Replaced later)
    dc.l    UNMAPPED_USER_HANDLER       ; 4D: Timer A (Not used)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 4E-4F: MFP GPIO #6-7 (Not used)
    dcb.l   176,UNMAPPED_USER_HANDLER   ; 50-FF: Unused user vectors
    
VEC_END:
VERSION:
    dc.l    RELEASE_VER                 ; Embed the release version in ROM

; First of all, copy the exception table to RAM at 0x0.
; 68010 VBR defaults to that location anyway for 68000 compatibility.
START::
    or.w    #$0700,SR                 ; Disable interrupts for now    
    move.l  #VEC_END,A0               ; Start into A0 (source)
    move.l  #$400,A1                  ; 0x400 into A1 (destination)

.ISR_COPY_LOOP:    
    move.l  A1,D0                     ; Have we reached destination zero?
    tst.l   D0
    beq.s   .ISR_COPY_DONE            ; Halt if so
    
    move.l  -(A0),-(A1)               ; Copy long source to dest, with predecrement.
    bra.s   .ISR_COPY_LOOP            ; Next iteration

.ISR_COPY_DONE:
    bsr.w   INITMFP                   ; Initialise MC68901
    bsr.s   INITSDB                   ; Initialise System Data Block
    
    bsr.s   PRINT_BANNER

    bclr.b  #1,MFP_GPDR               ; Turn on GPIO #1 (Red LED)  
    and.w   #$F0FF,SR                 ; Enable interrupts

    jsr     linit                     ; Init C land
    jmp     main1                     ; Call stage 1 main

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
    
    bsr.s   EARLY_PRINTLN             ; Print all the banner lines
    bsr.s   EARLY_PRINTLN             ; This works because EARLY_PRINT
    bsr.s   EARLY_PRINTLN             ; leaves A0 pointing to the next
    bsr.s   EARLY_PRINTLN             ; character in memory ;-)
    bsr.s   EARLY_PRINTLN
    bsr.s   EARLY_PRINTLN
    
    rts                               ; We're done

; Wraps EARLY_PRINT so it can be called from C-land
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
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
    move.b  (A0)+,D0                  ; Get next character
    tst.b   D0                        ; Is it null?
    beq.s   .PRINT_DONE               ; ... we're done if so.

.BUFF_WAIT:
    btst.b  #7,MFP_TSR                ; Is transmit buffer empty?
    beq.s   .BUFF_WAIT                ; Busywait if not
    
    move.b  D0,MFP_UDR                ; ... otherwise, give character to the MFP
    bra.s   EARLY_PRINT               ; and loop
.PRINT_DONE:    
    rts                               ; We're done
    
; PRINT null-terminated string pointed to by A0 followed by CRLF.
;
; Only used during early init; Buffered serial driver will take
; over the UART later on...
;
; Trashes: D0, MFP_UDR
; Modifies: A0 (Will point to address after null terminator)
EARLY_PRINTLN::
    bsr.s   EARLY_PRINT               ; Print callers message
    move.l  A0,-(A7)                  ; Stash A0 to restore later
    
    lea     SZ_CRLF,A0                ; Load CRLF...
    bsr.s   EARLY_PRINT               ; ... and print it
        
    move.l  (A7)+,A0                  ; Restore A0
    rts
    
; Initialise System Data Block
;
INITSDB:
    move.l  #$B105D47A,$400           ; Magic at $400
    move.l  #$C001C001,$404           ; OK OSHI Code at $404
    move.w  #100,$408                 ; Heartbeat flash counter at 100 (1 per second)
    move.l  #0,$40C                   ; Zero upticks

    ; Undocumented - EARLY_PRINT and co for stage 2 only!
    lea     EARLY_PRINT,A0
    movea.l A0,$414
    lea     EARLY_PRINTLN,A0
    movea.l A0,$418
    lea     HALT,A0
    movea.l A0,$41C
    lea     SENDCHAR,A0
    movea.l A0,$420
    lea     RECVCHAR,A0
    movea.l A0,$424 
    rts

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
; Trashes: D0
; Modifies: MFP Regs
INITMFP:
    ; GPIOs
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    ; Timer setup - Timer D controls serial clock, C is kernel tick
    move.b  #$5C,MFP_TCDR             ; Timer C count is 92 for 50Hz (interrupt on rise and fall so 100Hz)
    move.b  #$03,MFP_TDDR             ; Timer D count is 3 for 307.2KHz, divided to 9600 baud
    move.b  #$71,MFP_TCDCR            ; Enable timer C with /200 and D with /4 prescaler
    move.b  #$01,MFP_TCDCR            ; Enable timer C with /200 and D with /4 prescaler
    
    ; USART setup
    move.b  #$88,MFP_UCR              ; /16 clock, async, 8N1
    move.b  #$05,MFP_TSR              ; Set pin state high and enable transmitter

    ; Interrupt setup - Enable timer C interrupt for kernel tick
    move.l  #MFP_VECBASE,D0           ; Set up the base MFP vector at 0x40 (first 16 user vectors)...
    or.l    #8,D0                     ; ... and set software-end-of-interrupt mode
    move.b  D0,MFP_VR                 ; ... then write to MFP vector register
    or.b    #$20,MFP_IERB             ; Enable Timer C interrupt, but leave it masked for now
                                      ; (kmain will call START_HEART later)
    
    ; Indicate success and return
    move.b  #$FE,MFP_GPDR             ; Turn on GPIO #0 (Green LED)
    rts

    
    
;------------------------------------------------------------
; Routines for include/machine.h
HALT::
    bsr.s   STOP_HEART
    stop    #$2700
    bra.s   HALT

SET_INTR::
    ; TODO Not yet implemented
    rts

START_HEART::
    bset.b  #5,MFP_IMRB               ; Unmask Timer C interrupt
    rts

STOP_HEART::
    bclr.b  #5,MFP_IMRB               ; Mask Timer C interrupt
    rts

;------------------------------------------------------------
; Exception handlers    
TICK_HANDLER:
    move.l  D0,-(A7)                  ; Save D0
    
    ; Increment upticks
    move.l  $40C,D0                   ; Read SDB dword at 12
    add.l   #1,D0                     ; Increment
    move.l  D0,$40C                   ; And write back
    
    ; Heartbeat
    move.w  $408,D0                   ; Read SDB word at 8
    tst.w   D0                        ; Is it zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 and reset counter
    bchg.b  #0,MFP_GPDR             
    move.w  #100,D0
    
.TICK_HANDLER_DONE:
    sub.w   #$1,D0                    ; Decrement counter...
    move.w  D0,$408                   ; ... and write back to SDB
    move.l  (A7)+,D0                  ; Restore D0
    move.b  #~$20,MFP_ISRB            ; Clear interrupt-in-service
    rte                               ; We're done

    
; Call busywait from C code...
BUSYWAIT_C::
    move.l  (4,A7),D0
    jmp     BUSYWAIT

; Busywait - expects a delay in D0, returns when D0 gets to 0 
;
; Trashes: D0
BUSYWAIT:
    sub.l   #1,D0
    tst.l   D0
    bne.s   BUSYWAIT
    rts

BUS_ERROR_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.b  #0,MFP_IERA
    move.b  #0,MFP_IERB

    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #100000,D0                ; Wait a while
    bsr.s   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.s   BUSYWAIT
    bra.s   BUS_ERROR_HANDLER
    
    rte                               ; Never reached

ADDRESS_ERROR_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.b  #0,MFP_IERA
    move.b  #0,MFP_IERB

    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.s   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.s   BUSYWAIT
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    bra.s   ADDRESS_ERROR_HANDLER
    
    rte                               ; Never reached

ILLEGAL_INSTRUCTION_HANDLER:
    or.w    #0700,SR                  ; Disable exceptions
    move.b  #0,MFP_IERA
    move.b  #0,MFP_IERB

    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT

    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    bra.w   ILLEGAL_INSTRUCTION_HANDLER
    
    rte                               ; Never reached

GENERIC_HANDLER:
    move.l  #$2BADB105,$404
    rte
    
RESERVED_HANDLER:
    move.l  #$0BADC0DE,$404
    rte
    
UNMAPPED_USER_HANDLER:
    move.l  #$002BAD05,$404
    rte
    
INTERRUPT_HANDLER:
    move.l  #$0BADF00D,$404
    rte

TRAP_HANDLER:
    move.l  #$C001C0DE,$404
    rte

; TODO these functions are duplicated from sx/serial.S, find a way
; to not do that (maybe dynamic link to ROM addresses...)

; Send a single character via UART
;
; Trashes: MFP_UDR
; Modifies: Nothing
SENDCHAR::
    move.l  D1,-(A7)              ; Save D1
.BEGIN
    bset.b  #7,MFP_GPDR           ; Raise (inhibit) RTS
    move.b  MFP_TSR,D1            ; Get TSR
    btst    #7,D1                 ; Is buffer empty bit set?
    beq.s   .BEGIN                ; No - loop until it is

    move.b  D0,MFP_UDR            ; Put func arg in UDR
    move.l  (A7)+,D1              ; Restore D1
    rts


; Receive a single character via UART.
; Ignores overrun errors.
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
RECVCHAR::
    bclr.b  #7,MFP_GPDR           ; Lower RTS
.BEGIN
    move.b  MFP_RSR,D0            ; Get RSR
    btst    #7,D0                 ; Is buffer_full bit set?
    bne.s   .GOTCHR               ; Yes - Go to receive character

    btst    #6,D0                 ; Else, do we have an overrun error?
    bne.s   .GOTERR               ; .. Yes - handle that
    bra.s   .BEGIN                ; .. No - Just loop

.GOTERR
    move.b  MFP_UDR,D0            ; Empty buffer
    bchg.b  #1,MFP_GPDR           ; And toggle I1
    bra.s   .BEGIN                ; And continue testing...
    
.GOTCHR
    move.b  MFP_UDR,D0            ; Get the data
    rts

; TRAP 14 provides access to some of the basic functionality
; of the firmware after the bootloader has terminated.
;
; D1 is expected to contain the function code. Other arguments
; depend on the specific function - See README for details.
TRAP_14_HANDLER:
    cmp.l   #0,D1                     ; FC == 0?
    beq.s   .PRINT                    ;   PRINT if so...
    cmp.l   #1,D1                     ; FC == 1?
    beq.s   .PRINTLN                  ;   PRINTLN if so...
    cmp.l   #2,D1                     ; FC == 2?
    beq.s   .SENDCHAR                 ;   SENDCHAR if so...
    cmp.l   #3,D1                     ; FC == 3?
    beq.s   .RECVCHAR                 ;   RECVCHAR if so...
    rte                               ; That's all for now...

.PRINT
    bsr.w   EARLY_PRINT
    rte

.PRINTLN
    bsr.w   EARLY_PRINTLN
    rte

.SENDCHAR
    bsr.w   SENDCHAR
    rte

.RECVCHAR
    bsr.w   RECVCHAR
    rte
    

;------------------------------------------------------------
; Consts 
    section .rodata

SZ_BANNER0      dc.b    $1B, "[1;33m                                 ___ ___ _   ", 0
SZ_BANNER1      dc.b    " ___ ___ ___ ___ ___       _____|  _| . | |_ ", 0
SZ_BANNER2      dc.b    "|  _| . |_ -|  _| . |     |     | . | . | '_|", 0
SZ_BANNER3      dc.b    "|_| |___|___|___|___|_____|_|_|_|___|___|_,_|", 0 
SZ_BANNER4      dc.b    "                    |_____|", $1B, "[1;37mfirmware v1.2ALPHA", $D, $A, 0
SZ_INITDONE     dc.b    $1B, "[0mHardware initialisation ", $1B, "[1;32mcomplete", $1B, "[0m; Commencing software initialisation...", 0

SZ_CRLF         dc.b    $D, $A, 0

