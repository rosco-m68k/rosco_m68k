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
;* Task / scheduler related assembly code
;* ------------------------------------------------------------
;*

  section .text

TASK_NEXT   equ     $00                   ; These need to be kept in-step with
TASK_PREV   equ     $04                   ; the structs in task.h!
TASK_SIZE   equ     $08
TASK_TYPE   equ     $0C
TASK_STACK  equ     $10
TASK_PID    equ     $14
TASK_WAITS  equ     $18
TASK_PRIO   equ     $24

VEC_TIMER   equ     $114
SDB_CPUINFO equ     $41c

; Number of ticks per quantum. The scheduler will be invoked after
; this many ticks of the system timer. 
;
; A value of 1 equates to a quantum of 1/100th sec, higher 
; values make the quantum longer.
;
; Zero would give us an almost-eleven-minute quantum (it rolls over 
; to 0xFFFF0) which might be fun, but is probably too long for rosco_m68k 
; purposes 😅.
;
QUANTUM_TICKS  equ   1

; Initialise the task system.
;
; Must be called before using other functions.
;
task_init::
  move.l    a0,-(a7)
  move.l    #runnable_list_3,a0
  bsr       list_init
  move.l    #runnable_list_2,a0
  bsr       list_init
  move.l    #runnable_list_1,a0
  bsr       list_init
  move.l    #runnable_list_0,a0
  bsr       list_init
  move.l    #sleeping_list,a0
  bsr       list_init
  move.l    (a7)+,a0
  rts

; Initialise a task. This must be called on a new task structure
; before `task_yield` is used to switch to it. 
;
; It sets up the initial stack to be in the layout `task_yield` expects
; to find (or, more correctly right now, the layout the rte at the 
; end of the tick_handler will expect to find).
;
; C-callable (args on stack).
;   void tee_task(Task *task, uint32_t stack_addr, void (*entryhandler)(), void (*entrypoint)(), void (*exithandler)());
;
; Internal API.
;
task_tee::
  move.l    a0,-(a7)                      ; Save registers
  move.l    a1,-(a7)                      
  move.l    d0,-(a7)
  move.l    d1,-(a7)
  move.l    d2,-(a7)

  move.l    $18(a7),a0                    ; Get stacked Task*
  move.l    $1c(a7),a1                    ; Get stacked stack_addr
  move.l    $20(a7),d2                    ; Get stack entryhandler
  move.l    $24(a7),d0                    ; And stacked entrypoint
  move.l    $28(a7),d1                    ; And stacked exithandler

  ; The following is used if the task should ever complete and return with an rts
  move.l    d1,-(a1)                      ; If task completes, "return" to exithandler

  ; The following are used by the CPU directly, via rte
  move.w    #$45,-(a1)                    ; Format code 0000, vector 0x45
  move.l    d0,-(a1)                      ; Stack the "return address" (entrypoint)
  move.w    #$2000,-(a1)                  ; Stack SR - supervisor, interrupts enabled - Start of exception frame for rte

  ; The following are dealt with or used by task switching code itself
  move.l    d2,-(a1)                      ; Stack the entry handler "return" - The entry point for the handler
  move.w    #$2700,-(a1)                  ; Stack SR - supervisor, interrupts masked - again, task_yield sets this one up
  movem.l   d0-d7/a0-a6,-(a1)             ; Stack the GP registers - task_yield deals with these

  move.l    a1,TASK_STACK(a0)             ; Store SP in the Task

  move.l    (a7)+,d2                      ; Restore registers
  move.l    (a7)+,d1
  move.l    (a7)+,d0
  move.l    (a7)+,a1
  move.l    (a7)+,a0
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
; This next bit is kinda weird... 
;
; These trampolines are used when a task is first entered, and are 
; responsible for doing whatever setup might be needed and then jumping
; (or returning) to the appropriate place. They _can_ also be used 
; when resuming tasks, and might be a way to make that whole thing
; more flexible (see below) assuming something more elegant doesn't
; come along 🤣.
;
; This is all quite tightly coupled to task_tee, above, which is why
; it's up here next to that routine...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  

;
; Task trampoline. We use rte when starting tasks because it gives
; us an easy way to set SR to ensure interrupts are enabled (we 
; still need to call the enable_interrupts func to decrement the
; counter that will be left from when the switch was initiated). 
;
; This only matters when first starting - at all other times, tasks 
; will have been suspended with interrupts disabled and will always
; have a re-enable somewhere on their execution path.
;
task_trampoline::
  bsr     enable_interrupts
  rte


; The init trampoline is even weirder. Because init has "special requirements",
; (mainly, it doesn't want interrupts to be enabled until after things are 
; scheduled, so it can do it's work and then get out of the way) it is always
; set up with this special trampoline. 
;
; The things at play here are:
;
;   * init, like other tasks, has its initial stack set up in task_tee
;   * task_tee always sets stacks up "as if" the task was suspended in an ISR
;   * init is _never_ invoked like that, hence this nasty special case...
;
init_trampoline::
  move.l    2(a7),.entrypoint             ; Pop and store the task's entrypoint
  addq.l    #8,a7                         ; Discard the whole exception frame 
  move.l    .entrypoint,-(a7)             ; Push the entrypoint back ready for rts
  rts                                     ; And go...

  section .bss
.entrypoint   ds.l    1


  section .text
; The idle trampoline is _probably_ pointless and can likely just be merged
; with the normal task one.
; 
idle_trampoline::
  bsr     enable_interrupts
  rte


; Get the correct runnale priority queue for the task in 
; a1 into a0.
;
; Arguments:
;   a1      - The task
;
; Modifies:
;   a0      - The appropriate queue head
;
runnable_priority_queue_ptr:
  move.w  d0,-(a7)  
  move.b  TASK_PRIO(a1),d0
  and.b   #3,d0
  bne     .notzero

  move.l  #runnable_list_0,a0
  move.w  (a7)+,d0
  rts

.notzero
  cmp.b   #1,d0
  bne     .notone

  move.l  #runnable_list_1,a0
  move.w  (a7)+,d0
  rts

.notone
  cmp.b   #2,d0
  bne     .three

  move.l  #runnable_list_2,a0
  move.w  (a7)+,d0
  rts

.three
  move.l  #runnable_list_3,a0
  move.w  (a7)+,d0
  rts


; Yield to the next task in the list. Prioritised round-robin.
;
; Basically switches to the next task's stack, restores 
; registers (including SR) from there and then does a 
; "return" to the task.
;
; **must** be called with interrupts disabled.
;
; Arguments:
;   none
;
; Modifies:
;   all execution context
;
task_yield::
  bsr       suspend                       ; Suspend the current task

  cmp.l     #0,a1                         ; Never add the null task to the runnable list
  beq       task_switch_next                

  cmp.l     #tidle,a1                     ; Never add the idle task to the runnable list
  beq       task_switch_next                

  bsr       runnable_priority_queue_ptr   ; Not the idle task, so add to the end of the list
  bsr       list_add_tail

; Find and switch to the next task.
;
; Does **not** suspend the current process - likely not what
; is wanted in most cases!
;
; task_yield falls through to this.
;
; Arguments:
;   none
;
task_switch_next::
  ifd       DEBUG_SCHED                   ; Debug tracing task switches
  ifd       TRACE_SCHED
  bsr       trace_switch
  endif
  endif

  move.l    #runnable_list_3,a0           ; Starting at the priority 3 list head
  bsr       task_find_next                ; Dequeue next task
  cmp.l     #0,a1                         ; Is there one?  
  bne       switch_a1                     ; Else, switch to it

  move.l    #runnable_list_2,a0           ; Starting at the priority 2 list head
  bsr       task_find_next                ; Dequeue next task
  cmp.l     #0,a1                         ; Is there one?  
  bne       switch_a1                     ; Else, switch to it

  move.l    #runnable_list_1,a0           ; Starting at the priority 1 list head
  bsr       task_find_next                ; Dequeue next task
  cmp.l     #0,a1                         ; Is there one?  
  bne       switch_a1                     ; Else, switch to it

  move.l    #runnable_list_0,a0           ; Starting at the priority 0 list head
  bsr       task_find_next                ; Dequeue next task
  cmp.l     #0,a1                         ; Is there one?  
  bne       switch_a1                     ; Else, switch to it

  move.l    #tidle,a1                     ; Nothing runnable, so "schedule" the idle task

; Switch to the task pointed to by a1. Local to this module
;
; switch_next  falls through to this.
;
; Arguments:
;   a1    - The new task
;
switch_a1:
  move.l    a1,current_task_var           ; Store new task in the current_task variable
  move.l    TASK_STACK(a1),a7             ; Switch stacks to the new task's stack
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore GP registers
  move.w    (a7)+,sr                      ; Restore SR

                                          ; New task return address is on the stack at this point...  
  rts                                     ; return to the new task


; Suspend the current task. Stores all task context onto the stack in preparation
; for a context switch.
;
; Local to this module.
;
; Modifies:
;   a1      - returns current task
;   stack   - all context - 0x3e bytes
;
suspend:
                                          ; Callers return address is on the stack at this point...
  move.l    (a7)+,.ret_addr               ; Pop this func's return addr, and stash it
  move.w    sr,-(a7)                      ; Stack the SR
  movem.l   d0-d7/a0-a6,-(a7)             ; Stack the GP registers

  move.l    current_task_var,a1           ; Get the current Task* into a1
  move.l    a7,TASK_STACK(a1)             ; Store the SP into the Task

  move.l    .ret_addr,-(a7)               ; Unstash our return addr
  rts                                     ; and done.

  section .bss
.ret_addr    ds.l    1

  
  section .text
; Find the next runnable task from the given queue,
; remove it from the queue and return it.
;
; Arguments:
;   a0    - The list head
;
; Modifies:
;   a0    - Trashed
;   a1    - The new task, or NULL if no runnable task
;
task_find_next:
  move.l    a0,-(a7)

  move.l    a0,a1                         ; Point a1 at the tail node
  add.l     #4,a1

  move.l    TASK_NEXT(a0),a0
  cmp.l     a1,a0                         ; Is is pointing to the list tail?
  beq       .empty                        ; If not, we found our next task

  move.l    (a7)+,a0
  bsr       list_delete_head              ; Else, pop the list head into a1
  rts

.empty
  add.l     #4,a7
  move.l    #0,a1
  rts


; Wait for signals.
;
; C-callable:
;   uint32_t task_wait(uint32_t sig_mask);
;
task_wait::
  bsr       disable_interrupts            ; Single tasking...
  move.l    #.reenable_return,-(a7)       ; We need to come back to this function when signalled
  bsr       suspend                       ; Load current task, and suspend it  

  move.l    $46(a7),d0                    ; Get signal mask argument
  move.l    d0,TASK_WAITS(a1)             ; And store it in the task

  move.l    #sleeping_list,a0             ; Put current task on the sleeping list
  bsr       list_add_head

  bsr       task_switch_next              ; Switch to the runnable task

.reenable_return:
                                          ; New task return address is on the stack at this point...  
  bra       enable_interrupts             ; so enable interrupts...                                    
  rts                                     ; ... and return to the new task


; Signal a task.
;
; C-callable:
;   void task_signal(Task *task, uint32_t sig_mask);
;
; TODO this can be significantly simplified if we decide to remove the
; immediate signal switch (SIG_IMMED) build-time option...
;
task_signal::
  bsr       disable_interrupts            ; Single tasking...
  move.l    a7,.olda7                     ; Stash current sp in case we need to abort the switch
  
  move.l    #.reenable_return,-(a7)       ; When this task comes back, start it at interrupt re-enable in this func
  bsr       suspend                       ; Load current task, and suspend it

  move.l    a2,-(a7)                      ; Save a few registers in case we abort the switch
  move.l    a1,-(a7)
  move.l    d1,-(a7)
  move.l    d0,-(a7)

  move.l    $56(a7),a1                    ; Get the target task argument
  move.l    $5a(a7),d0                    ; Get the signal mask
  move.l    d0,.temp                      ; Stash signal argument for wait's return value

  move.l    sleeping_list,a0              ; Start at head of sleeping list
.loop
  cmp.l     a0,a1                         ; Is this sleeping task our target?
  beq       .check_sig                    ; Check its signal mask if so...
  cmp.l     #sleeping_tail,a0             ; Else, did we reach the end of the list?
  beq       .notfound                     ; No matching task if so...
  move.l    TASK_NEXT(a0),a0              ; Otherwise, try next task...
  bra       .loop                         ; ... and loop

.check_sig:
  and.l     TASK_WAITS(a0),d0             ; Matching task - is it waiting for the right signal(s)?
  beq       .notfound                     ; If zero, right task but wrong signals - just quit

.found:
  bsr       list_node_delete              ; Found it - remove it from the sleeping list
  move.l    TASK_STACK(a1),a2             ; Get actual signals back from temp variable...
  move.l    .temp,(a2)                    ; ... and put into D0 slot on target task's stack

  ; Not using switch_a1 etc here, we need to fiddle the registers for wait's return value...
  ifd       DEBUG_SCHED                   ; Debug tracing task switches
  ifd       TRACE_SCHED
  bsr       trace_switch
  endif
  endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Conditional - only if -DSIG_IMMED - switch immediately on signal
;; TODO this should _probably_ be removed, it's not interrupt-safe
;; but keeping it (disabled) for now just in case we decide to go
;; a different route...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ifd       SIG_IMMED
  move.l    a1,a2                         ; Save next task for a sec
  move.l    current_task_var,a1           ; Get the current task...

  move.b    TASK_PRIO(a1),d0              ; Current task priority into d0
  move.b    TASK_PRIO(a2),d1              ; Signalled task priority into d1
  cmp.b     d0,d1                         ; Compare priority of incoming vs current task
  blt       .noswitch                     ; If lower, we don't switch immediately

  ; Else, we do switch immediately - set that up
  cmp       #tidle,a1                     ; Never add the idle task to the runnable list
  beq       .do_switch

  bsr       runnable_priority_queue_ptr   ; Not the idle task, so add to the end of the list
  bsr       list_add_tail                 ; ...

.do_switch:
  move.l    a2,a1                         ; Get next task back into a1 for switch

  move.l    a1,current_task_var           ; Store new task in the current_task variable
  move.l    TASK_STACK(a1),a7             ; Switch stacks to the new task's stack  
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore GP registers, except d0 (our return value)
  move.w    (a7)+,sr                      ; Restore SR
  ; move.l    .temp,d0                      ; Set up d0 with stashed signals, to return from wait

; .reenable_return                          ; Waiting task return address is on the stack at this point...  
  bsr       enable_interrupts             ; Re-enable interrupts for multitasking
  rts                                     ; Let's go there (returning value in d0)

.noswitch:
  move.l    a2,a1                         ; Signalled task back into a1
  endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Conditional - only if -DSIG_IMMED - switch immediately on signal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  bsr       runnable_priority_queue_ptr   ; Find the right priority list for it
  bsr       list_add_head                 ; And add it to run next (in it's respective priority)

.notfound:
  move.l    (a7)+,d0                      ; No matching (waiting) task - abort switch.
  move.l    (a7)+,d1                      ; No matching (waiting) task - abort switch.
  move.l    (a7)+,a1                      ; Restore those registers...
  move.l    (a7)+,a2
  move.l    .olda7,a7                     ; ... and then restore the original SP

.reenable_return:
  bsr       enable_interrupts             ; Re-enable interrupts for multitasking
  rts

  section .bss
.temp   ds.l    1
.olda7  ds.l    1


  section .text

; Kick off the tasking. Does a whole convoluted, slightly bonkers process involving
; init tasks, entry/exit handlers and weird stack manipulation. It does work though,
; somehow, for some value of the word "work"... 💪
;
; Will never return to its caller. Once this is called, we can reclaim the boot
; context since we're in kernel land.
;
; Arguments:
;   init Task*
;
; Modifies:
;   all execution context
;
task_kick_off::
                                          ; Return address is on the stack at this point,
                                          ; We don't need it, but this stack will get discarded
                                          ; anyway so just ignore it.

  move.l    4(a7),a0                      ; Get init Task* from stack into a0
  move.l    a0,current_task_var           ; Store it in the current_task variable
  move.l    TASK_STACK(a0),a7             ; Switch stacks to the new task's stack
  movem.l   (a7)+,d0-d7/a0-a6             ; Restore GP registers
  move.w    (a7)+,sr                      ; Restore SR

  bsr       disable_interrupts            ; No interrupts for a bit (init_done will restore them later)
  
  move.l    SDB_CPUINFO,d0                ; Get CPU info from SDB
  lsr.l     #8,d0                         ; Just the CPU model bits
  lsr.l     #8,d0
  lsr.l     #8,d0
  lsr.l     #5,d0
  tst.b     d0                            ; is it 68000?
  beq       .is68000               
  
  mc68010
  movec.l   vbr,a0                        ; Not a 68000, so get VBR
  bra       .install_handler              ; And go install handler...
  mc68000

.is68000:
  move.l    #$0,a0                        ; Is a 68000, vector base is at $0

.install_handler:
  move.w    #QUANTUM_TICKS,tick_counter   ; Set up the tick counter
  move.l    VEC_TIMER(a0),saved_tick_handler
  move.l    #tick_handler,VEC_TIMER(a0)   ; Save original (for chaining), and install new tick

  rts                                     ; return to the new task


; Returns the current task in d0
;
; Arguments:
;   none
;
; Modifies
;   d0    - Current Task struct
;
task_current::
  move.l    current_task_var,d0           ; Var into d0
  rts


; Conditionally assembled, just for debug tracing
  ifd       DEBUG_SCHED
  ifd       TRACE_SCHED

trace_switch:
  movem.l   d0-d7/a0-a6,-(a7)
  bsr       debug_trace_task_switch
  movem.l   (a7)+,d0-d7/a0-a6
  rts

  endif
  endif


; This is the tick handler. It handles task switching every so often,
; and calls through to the handler that was on this vector before the 
; kernel came along (which is needed for e.g. EOI on the timer device, 
; as well as the blinkenlights...)
; 
tick_handler:
  movem.l   d0-d7/a0-a6,-(a7)
  move.w    #$45,-(a7)                    ; Set up fake exception frame for chained handler rte
  move.l    #post_jump,-(a7)
  move.w    sr,-(a7)

chain_jump:
  move.l    saved_tick_handler,a0         ; Chained handler first, to sort out the hw...
  jmp       (a0)

post_jump:
  bsr       disable_interrupts
  subq.w    #1,tick_counter               ; Decrease the tick counter by 1
  bne       .tick_handler_done            ; If it's not zero, skip the switch

.switch:
  move.w    #QUANTUM_TICKS,tick_counter   ; Otherwise, reset the counter
  bsr       task_yield                    ; And do a switch

.tick_handler_done:
  movem.l   (a7)+,d0-d7/a0-a6
  bsr       enable_interrupts
  rte


;;;;;; Variables
  section .bss
tick_counter          ds.w    1

current_task_var::    ds.l    1           ; Holds (you guessed it) the current task

runnable_list_3::                         ; The runnable list, head & tail for convenience
runnable_head_3       ds.l    1
runnable_tail_3       ds.l    2

runnable_list_2::                         ; The runnable list, head & tail for convenience
runnable_head_2       ds.l    1
runnable_tail_2       ds.l    2

runnable_list_1::                         ; The runnable list, head & tail for convenience
runnable_head_1       ds.l    1
runnable_tail_1       ds.l    2

runnable_list_0::                         ; The runnable list, head & tail for convenience
runnable_head_0       ds.l    1
runnable_tail_0       ds.l    2

sleeping_list::                           ; The sleeping list, head & tail for convenience
sleeping_head         ds.l    1
sleeping_tail         ds.l    2

saved_tick_handler    ds.l    1
