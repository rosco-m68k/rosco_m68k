*-----------------------------------------------------------
* Title      : rosco_m68k BIOS v2
* Written by : Ross Bamford
* Date       : 28/04/2019
* Description: Basic machine set-up and prep for a kernel
*-----------------------------------------------------------
    include "equates.x68"
    
    org     ROMBASE
RESET:
    dc.l    RAMLIMIT                    ; 00: Stack (top of on-board RAM)
    dc.l    INIT_PC                     ; 01: Initial PC (start of ROM)
    
VECTORS:
    dc.l    GENERIC_HANDLER             ; 02: Bus Error
    dc.l    GENERIC_HANDLER             ; 03: Address Error
    dc.l    GENERIC_HANDLER             ; 04: Illegal Instruction
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
    dcb.l   16,TRAP_HANDLER             ; 20-2F: TRAP Handlers
    dcb.l   16,RESERVED_HANDLER         ; Remaining Reserved vectors
    dcb.l   192,UNMAPPED_USER_HANDLER   ; User vectors
    
* First of all, copy the exception table to RAM at 0x0.
* 68010 VBR defaults to that location anyway for 68000 compatibility.
START:
    or.w    #$0700, SR      ; Disable interrupts for now    
    move.l  #START, A0      ; Start into A0 (source)
    move.l  #$400, A1       ; 0x400 into A1 (destination)

ISR_COPY_LOOP:    
    move.l  A1, D0          ; Have we reached destination zero?
    tst.l   D0
    beq.s   ISR_COPY_DONE   ; Halt if so
    
    move.l  -(A0), -(A1)    ; Copy long source to dest, with predecrement.
    bra.s   ISR_COPY_LOOP   ; Next iteration

ISR_COPY_DONE:
* Now set up the BIOS data block. This is a reserved area of RAM from 0x400
* to 0x4FF (256 bytes) that will be used to store assorted stuff.
*
* Currently, it looks like this:
*
*			typedef struct {
*				uint32_t magic;
*				uint32_t oshi_code;
*               MemoryRegion *free_list;
*               Task *task_list;
*				uint8_t reserved[240];
*			} BiosDataBlock;
*
* Where the referenced structures are stored in regular RAM, and look like:
*
*           typedef struct __MEMORY_REGION {
*               void *start;
*               uint32_t size;
*               uint32_t flags;
*               __MEMORY_REGION *next;               
*           } MemoryRegion;
*
*           typedef struct __TASK {
*               uint32_t tid;
*               uint16_t flags;
*               uint8_t priority;
*               uint8_t status;
*               uint32_t sr;
*               uint32_t sp;
*               uint32_t pc;
*               uint32_t reserved[3];
*           } Task;
*
*   
    move.l  #$B105D47A, $400                ; Magic in $400        
    move.l  #$0,        $404                ; No oshi_code yet
    move.l  #$500,      $408                ; Initial memory region at $500
    move.l  #$0,        $40C                ; No tasks yet
    
* Setup initial free memory region

    move.l  #$50F,      $500                ; Free RAM starts after this region header
    move.l  #$FFAF1,    $504                ; Up to top of RAM (1MB).
    move.l  #$0,        $508                ; Zero flags for now
    move.l  #$0,        $50C                ; This is the last region
    
* Test that we can TRAP to our TRAP_HANDLER. Should put 0xC001C0DE in the 
* BDB's oshi_code (at address $404).       
    trap    #0
    
* Show message
    lea     WAITING_MESSAGE, A1
    bsr.s   PRINTLN    

* And we're done for now.
IDLE:
    stop    #$2300
    bra.s   IDLE

* Output - Null-terminated string in A1
PRINT:
    move.l  D0, -(A7)
    move.l  #14, D0
    trap    #15
    move.l  (A7)+, D0
    rts

PRINTLN:
    move.l  D0, -(A7)
    move.l  #13, D0
    trap    #15
    move.l  (A7)+, D0
    rts

* Output D1 as hex
PRINTNUM:
    move.l  D0, -(A7)
    move.l  D2, -(A7)
    move.l  #15, D0
    move.b  #16, D2
    trap    #15
    move.l  (A7)+, D2
    move.l  (A7)+, D0
    rts    

PANIC:
    lea     OSHI_MESSAGE, A1
    bsr.s   PRINT
    move.l  $404, D1
    bsr.s   PRINTNUM
    lea     SR_STRING, A1
    bsr.s   PRINT
    eor.l   D1, D1
    move.w  4(A7), D1
    bsr.s   PRINTNUM
    lea     RET_PC_STRING, A1
    bsr.s   PRINT
    eor.l   D1, D1
    move.l  6(A7), D1
    bsr.s   PRINTNUM
    lea     EMPTY_STRING, A1
    bsr.s   PRINTLN
    rts
    
* Exception handlers    
GENERIC_HANDLER:
    move.l  #$2BADB105, $404
    bsr.s   PANIC
    rte
    
RESERVED_HANDLER:
    move.l  #$0BADC0DE, $404
    rte
    
UNMAPPED_USER_HANDLER:
    move.l  #$002BAD05, $404
    rte
    
INTERRUPT_HANDLER:
    move.l  #$0BADF00D, $404
    bsr.s   PANIC
    rte

TRAP_HANDLER:
    move.l  #$C001C0DE, $404
    rte

EMPTY_STRING:       dc.b    '', 0    
WAITING_MESSAGE:    dc.b    'Waiting for interrupts...', 0
OSHI_MESSAGE:       dc.b    'OSHI... (Unhandled Interrupt): 0x', 0
SR_STRING:          dc.b    '; SR: 0x', 0
RET_PC_STRING:      dc.b    '; RET PC: 0x', 0
    
    END    START        ; last line of source
  

*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
