;*
;*------------------------------------------------------------
;*                                  ___ ___ _
;*  ___ ___ ___ ___ ___       _____|  _| . | |_
;* |  _| . |_ -|  _| . |     |     | . | . | '_|
;* |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;*                     |_____|            kernel
;* ------------------------------------------------------------
;* Copyright (c)2023 Ross Bamford and contributors
;* See top-level LICENSE.md for licence information.
;*
;* Machine related routines
;* ------------------------------------------------------------
;*

  section .text
IRQ_NEXT   equ     $00                    ; These need to be kept in-step with
IRQ_PREV   equ     $04                    ; values in list.h!
IRQ_DATA   equ     $08
IRQ_FUNC   equ     $0C

VEC_IRQ1    equ     $64
VEC_IRQ2    equ     $68
VEC_IRQ3    equ     $6C
VEC_IRQ4    equ     $70
VEC_IRQ5    equ     $74
VEC_IRQ6    equ     $78
VEC_IRQ7    equ     $7C
SDB_CPUINFO equ     $41c

halt::
  stop      #$2000
  rts


halt_and_catch_fire::
  stop      #$2700
  bra       halt_and_catch_fire


disable_interrupts::
  or.w      #$0700,sr                     ; Disable interrupts before anything else

  ifd       DEBUG_INTEN
  bsr       do_report_disable
  endif

  addq.w    #1,disable_intr_count

  ifd       DEBUG_INTEN
  bsr       do_report_disable2
  endif

  rts

enable_interrupts::
  ifd       DEBUG_INTEN
  bsr       do_report_enable
  endif

  tst.w     disable_intr_count
  beq       .noenable

  subq.w    #1,disable_intr_count
  bne       .noenable

  ifd       DEBUG_INTEN
  bsr       do_report_enabled
  bsr       do_report_enable2
  endif

  and.w     #$F0FF,sr                     ; Enable interrupts
  rts

.noenable:
  ifd       DEBUG_INTEN
  bsr       do_report_enable2
  endif

  rts

; void irq_init(void)
irq_init::
  move.l    a0,-(a7)                      ; Save registers

  move.l    #irq_1_list,a0                ; And init the chain lists...
  bsr       list_init
  move.l    #irq_2_list,a0
  bsr       list_init
  move.l    #irq_3_list,a0
  bsr       list_init
  move.l    #irq_4_list,a0
  bsr       list_init
  move.l    #irq_5_list,a0
  bsr       list_init
  move.l    #irq_6_list,a0
  bsr       list_init
  move.l    #irq_7_list,a0
  bsr       list_init

  move.l    SDB_CPUINFO,d0                ; Get CPU info from SDB
  lsr.l     #8,d0                         ; Just the CPU model bits
  lsr.l     #8,d0
  lsr.l     #8,d0
  lsr.l     #5,d0
  tst.b     d0                            ; is it 68000?
  beq       .is68000               
  
  mc68010
  movec.l   vbr,a0                        ; Not a 68000, so get VBR
  bra       .install_handlers             ; And go install handler...
  mc68000

.is68000:
  move.l    #$0,a0                        ; Is a 68000, vector base is at $0

.install_handlers:
  bsr       disable_interrupts            ; Ensure no interrupts for a sec
  move.l    VEC_IRQ1,old_irq1             ; Install the handlers
  move.l    #irq_1,VEC_IRQ1(a0)
  move.l    VEC_IRQ2,old_irq2
  move.l    #irq_2,VEC_IRQ2(a0)
  move.l    VEC_IRQ3,old_irq3
  move.l    #irq_3,VEC_IRQ3(a0)
  move.l    VEC_IRQ4,old_irq4
  move.l    #irq_4,VEC_IRQ4(a0)
  move.l    VEC_IRQ5,old_irq5
  move.l    #irq_5,VEC_IRQ5(a0)
  move.l    VEC_IRQ6,old_irq6
  move.l    #irq_6,VEC_IRQ6(a0)
  move.l    VEC_IRQ7,old_irq7
  move.l    #irq_7,VEC_IRQ7(a0)
  bsr       enable_interrupts             ; Good to go on interrupts again

  move.l    (a7)+,a0
  rts

irq_1:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #1,d0                         ; IRQ is 1...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq1,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_2:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #2,d0                         ; IRQ is 2...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq2,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_3:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #3,d0                         ; IRQ is 3...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq3,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_4:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #4,d0                         ; IRQ is 4...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq4,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_5:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #5,d0                         ; IRQ is 5...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq5,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_6:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #6,d0                         ; IRQ is 6...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq6,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


irq_7:
  movem.l   d0-d7/a0-a6,-(a7)             ; Save all registers
  move.l    #7,d0                         ; IRQ is 7...
  bsr       run_handler_chain             ; ... run handlers

  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #.post_jump,-(a7)
  move.w    sr,-(a7)

  move.l    old_irq7,a0                   ; Load the original handler
  jmp       (a0)

.post_jump:
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore all registers
  rte


; void irq_register_c(uint8_t vec, IrqHandler* handler);
irq_register_c::
  move.l    4(a7),d0                      ; Vector in d0
  move.l    8(a7),a1                      ; Handler struct pointer in a1

; Arguments:
;   d0    - IRQ number (1..7)
;   a1    - IrqHandler struct pointer
;
; Modifies:
;   d0    - trashed
;   a1    - trashed
;
irq_register::
  move.l    a0,-(a7)                      ; Save regs

  subq.l    #1,d0                         ; Make IRQ 0-based
  mulu.w    #12,d0                        ; Multiply by 12 (bytes in a List struct)
  move.l    #irq_1_list,a0                ; Get the base address of irq 1 list
  add.l     d0,a0                         ; And add d0 to get to our target list

  bsr       disable_interrupts
  bsr       list_add_tail                 ; Add this handler to the tail
  bsr       enable_interrupts

  move.l    (a7)+,a0                      ; And we're done..
  rts


; void irq_remove_c(IrqHandler* handler);
irq_remove_c::
  move.l    4(a7),a0                      ; Handler struct pointer in a0

; Arguments:
;   a0    - IrqHandler struct pointer
;
; Modifies:
;   a1    - Removed handler
;
irq_remove::
  bsr     disable_interrupts
  bra     list_node_delete                ; Just branch off to list_node_delete
  bsr     enable_interrupts
  rts

  ifd UNIT_TESTS
run_handler_chain_c::
  move.l    4(a7),d0
  endif

; Arguments:
;   d0    - IRQ number (1..7)
;
; Modifies:
;   nothing
;
run_handler_chain::
  tst.l     d0                            ; If d0 is 0, just return...
  beq       .justreturn
  cmp.l     #7,d0                         ; If it's higher than 7, just return
  bhi       .justreturn

  movem.l   d0-d1/a0-a2,-(a7)             ; Save regs

  subq.l    #1,d0                         ; Make IRQ 0-based
  mulu.w    #12,d0                        ; Multiply by 12 (bytes in a List struct)
  move.l    #irq_1_list,a0                ; Get the base address of irq 1 list
  add.l     d0,a0                         ; And add d0 to get to our target list
  move.l    a0,a1                         ; Also put into a1
  addq.l    #4,a1                         ; And point to list tail

.loop:
  move.l    (a7),d0                       ; Restore d0 (don't pop)
  move.l    IRQ_NEXT(a0),a0               ; Get next handler
  cmp.l     a1,a0                         ; Are we pointing at list tail?
  beq       .done                         ; We're done if so

  movem.l   d1/a0-a1,-(a7)                ; Save regs for potential C call
  move.l    IRQ_DATA(a0),-(a7)            ; Otherwise, push handler data onto stack
  move.l    d0,-(a7)                      ; followed by vector number
  move.l    IRQ_FUNC(a0),a2               ; Get function pointer  
  jsr       (a2)                          ; Call function
  add.l     #8,a7                         ; Restore stack
  movem.l   (a7)+,d1/a0-a1                ; Restore regs after potential C call

  tst.b     d0                            ; Did function return true?
  bne       .done                         ; We're done if so
  bra       .loop                         ; else, loop

.done:
  movem.l   (a7)+,d0-d1/a0-a2             ; Save regs
.justreturn:
  rts


  ifd       DEBUG_INTEN
do_report_disable:
  movem.l   d0-d7/a0-a6,-(a7)
  move.l    $40(a7),-(a7)
  move.w    disable_intr_count,-(a7)
  clr.w     -(a7)
  bsr       report_disable
  add.l     #8,a7
  movem.l   (a7)+,d0-d7/a0-a6
  rts

do_report_disabled:
  movem.l   d0-d7/a0-a6,-(a7)
  bsr       report_disabled
  movem.l   (a7)+,d0-d7/a0-a6
  rts

do_report_disable2:
  movem.l   d0-d7/a0-a6,-(a7)
  move.w    disable_intr_count,-(a7)
  clr.w     -(a7)
  bsr       report_disable2
  add.l     #4,a7
  movem.l   (a7)+,d0-d7/a0-a6
  rts

do_report_enable:
  movem.l   d0-d7/a0-a6,-(a7)
  move.l    $40(a7),-(a7)
  move.w    disable_intr_count,-(a7)
  clr.w     -(a7)
  bsr       report_enable
  add.l     #8,a7
  movem.l   (a7)+,d0-d7/a0-a6
  rts

do_report_enable2:
  movem.l   d0-d7/a0-a6,-(a7)
  move.w    disable_intr_count,-(a7)
  clr.w     -(a7)
  bsr       report_enable2
  add.l     #4,a7
  movem.l   (a7)+,d0-d7/a0-a6
  rts

do_report_enabled:
  movem.l   d0-d7/a0-a6,-(a7)
  bsr       report_enabled
  movem.l   (a7)+,d0-d7/a0-a6
  rts
  endif

  section .data

  section .bss
disable_intr_count::    ds.w    1

old_irq1                ds.l    1
old_irq2                ds.l    1
old_irq3                ds.l    1
old_irq4                ds.l    1
old_irq5                ds.l    1
old_irq6                ds.l    1
old_irq7                ds.l    1

irq_1_list::
irq_1_head              ds.l    1
irq_1_tail              ds.l    2
irq_2_list::
irq_2_head              ds.l    1
irq_2_tail              ds.l    2
irq_3_list::
irq_3_head              ds.l    1
irq_3_tail              ds.l    2
irq_4_list::
irq_4_head              ds.l    1
irq_4_tail              ds.l    2
irq_5_list::
irq_5_head              ds.l    1
irq_5_tail              ds.l    2
irq_6_list::
irq_6_head              ds.l    1
irq_6_tail              ds.l    2
irq_7_list::
irq_7_head              ds.l    1
irq_7_tail              ds.l    2
