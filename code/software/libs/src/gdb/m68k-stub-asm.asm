; /****************************************************************************
;  *
;  *                                  ___ ___ _  
;  *  ___ ___ ___ ___ ___       _____|  _| . | |_
;  * |  _| . |_ -|  _| . |     |     | . | . | '_|
;  * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;  *                     |_____|         libraries
;  *
;  *
;  ****************************************************************************
;  * m68k GDB remote debug stub - assembly parts
;  *
;  * This file is available in the public domain.
;  *
;  * This is a tidied up, modernised version of the assembly bits from the 
;  * standard m68k debug stub included in the GDB source. It **has** been 
;  * modified in various places to improve efficiency and fix bugs, but works
;  * in much the same was as the original (and where this is no longer the case
;  * there are comments explaining the differences).
;  *
;  * Having said that, one key difference is that 68000 support has been 
;  * entirely removed, and 68010 support has been implemented based on the 
;  * 68020 support in the original. Supporting all three was a total nightmare,
;  * and we don't officially support 68000 anyway...
;  *
;  * See comments in m68k-stub.c for original license and copyright notices.
;  ***************************************************************************/

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
catchException::
  ori.w   #$0700,sr                       ; Disable interrupts
  movem.l d0-d7/a0-a6,registers           ; Save registers
  move.l  lastFrame,a0                    ; Get lastFrame into a0

; TODO SAVE_FP_REGS();

  lea     registers,a5                    ; get address of registers
  move.w  (a7),d1                         ; get status register...
  move.w  d1,66(a5)                       ; ... and save it
  move.l  2(a7),a4                        ; save pc in a4 for later...
  move.l  a4,68(a5)                       ; ... and save it in registers[] too

  move.w  6(a7),d0                        ; Get exception format word
  move.w  d0,d2                           ; stash it for later
  andi.w  #$f000,d0                       ; mask off format type
  rol.w   #5,d0                           ; rotate into the low byte * 2
  lea     exceptionSize,a1                ; a1 points to exception stack size table...
  add.w   d0,a1                           ; ... and now, the specific entry therein
  move.w  (a1),d0                         ; get frame size from the table into d0
  move.w  d0,d3                           ; save it for later
  sub.w   d0,a0                           ; adjust save pointer (words)
  sub.w   d0,a0                           ; adjust save pointer (bytes)
  move.l  a0,a1                           ; copy save pointer
  subq.l  #1,d0                           ; predecrement loop counter

; copy the frame...
.saveFrameLoop:
  move.w  (a7)+,(a1)+                     ; copy a word
  dbf     d0,.saveFrameLoop               ; loop

; now that the stack has been cleaned,
; save the %a7 in use at time of exception
  move.l  a7,superStack                   ; save supervisor SP
  andi.w  #$2000,d1                       ; Were we in supervisor mode?
  beq     .userMode

  move.l  a7,60(a5)                       ; Yes - save A7
  bra     .a7saveDone

.userMode:
  move.l  usp,a1                          ; No - save USP
  move.l  a1,60(a5)

.a7saveDone:
  move.w  d3,-(a0)                        ; Save frame size into lastFrame

  and.l   #$fff,d2                        ; mask off vector offset from format word
  lsr.w   #2,d2                           ; divide by 4 for vector number
  move.l  d2,-(a0)                        ; save it into the new lastFrame

  move.l  a4,-(a0)                        ; Save exception PC into new lastFrame

  move.l  lastFrame,a1                    ; last frame pointer into a1
  move.l  a1,-(a0)                        ; and link into new lastFrame
  move.l  a0,lastFrame                    ; (doubly-linked)

  move.l  d2,-(a7)                        ; stack vector number for exceptionHook call
  move.l  exceptionHook,a0                ; and call it
  jsr     (a0)

  ; Both the 'idk' bits below have been lightly tested, and seem fine (we pretty much just 
  ; dump the stack frame used here later anyway) so could probably be changed... 
  ; At least bra would be faster than bsr for the returnFromException call...

  clr.l   (a7)                            ; idk why we clear this rather than popping it 🤷
  bsr     returnFromException             ; idk why this isn't just a bra / jmp either 🤨



; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; /*
;  * remcomHandler is a front end for handle_exception.  It moves the
;  * stack pointer into an area reserved for debugger use in case the
;  * breakpoint happened in supervisor mode.
;  */
remcomHandler::
  add.l   #4,a7                           ; discard return address
  move.l  (a7)+,d0                        ; Pop exception number into d0
  move.l  stackPtr,a7                     ; Switch to remcom stack area
  move.l  d0,-(a7)                        ; and push exception number

                                          ; idk why this isn't just a bra / jmp?? 😢
  bsr     handle_exception                ; (original comment - this never returns)
  rts                                     ; ... because this is never reached...



; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return_to_super::
  move.l  registers+60,a7                 ; Get new stack pointer
  move.l  lastFrame,a0                    ; Get last frame info
  bra     return_to_any

return_to_user::
  move.l  registers+60,a0                 ; Get USP from registers
  move.l  a0,usp                          ; Set USP
  move.l  superStack,a7                   ; Get original stack pointer

return_to_any::
  move.l  lastFrame,a0                    ; Get last frame info
  move.l  (a0)+,lastFrame                 ; Link in previous frame
  addq.l  #8,a0                           ; discard PC & vector num
  move.w  (a0)+,d0                        ; get number of words in CPU frame
  add.w   d0,a0                           ; Point to end of data (words)
  add.w   d0,a0                           ; Point to end of data (bytes)
  move.l  a0,a1

  ; Copy stack frame
  subq.l  #1,d0                           ; Predecrement counter
.copyUserLoop:
  move.w  -(a1),-(a7)                     ; Copy a word
  dbra    d0,.copyUserLoop                ; loop

  ; TODO Restore FP Regs?

  movem.l registers,d0-d7/a0-a6           ; Restore registers
  rte                                     ; And done



; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; /* this function is called immediately when a level 7 interrupt occurs */
; /* if the previous interrupt level was 7 then we're already servicing  */
; /* this interrupt and an rte is in order to return to the debugger.    */
debug_level7::
  move.w  d0,(a7)-                        ; Stash a0
  move.w  2(a7),d0                        ; Get SR
  andi.w  #$700,d0                        ; Is IPL 7?
  cmpi.w  #$700,d0
  beq     .already7

  move.w  (a7)+,d0                        ; No - handle as a normal exception
  bra     catchException

.already7:
  move.w  (a7)+,d0                        ; Yes - Ignore it
  rte



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Original code for save/restore FP:
;
;
;   #ifdef __HAVE_68881__
; /* do an fsave, then remember the address to begin a restore from */
; #define SAVE_FP_REGS()                    \
;     asm(" fsave   %a0@-");                \
;     asm(" fmovemx fp0-fp7,registers+72"); \
;     asm(" fmoveml fpcr/fpsr/fpi,registers+168")
; #define RESTORE_FP_REGS() \
;     asm("R(                                                 \n\
;     fmoveml  registers+168,fpcr/fpsr/fpi                    \n\
;     fmovemx  registers+72,fp0-fp7                           \n\
;     cmpl     #-1,%a0@     |  skip frestore flag set ?       \n\
;     beq      skip_frestore                                  \n\
;     frestore %a0@+                                          \n\
; skip_frestore:                                              \n\
; )")

; #else
; #define SAVE_FP_REGS()          struct no_op
; #define RESTORE_FP_REGS()       struct no_op
; #endif /* __HAVE_68881__ */
