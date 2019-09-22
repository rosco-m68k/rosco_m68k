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
; Atomic acquire for spinlock
;------------------------------------------------------------
    section .text
    
; Stub for calling SPINLOCK_ACQUIRE from C
SPINLOCK_ACQUIRE_C::
    move.l  (4,A7),A0                 ; Get Spinlock* from the stack into A0

; Expects A0 to point to spinlock
SPINLOCK_ACQUIRE::
    tas.b   (A0)                      ; Can we lock?
    bne     SPINLOCK_ACQUIRE          ; Spin if not
    rts                               ; We have the lock; Off to the races...


; Stub for calling SPINLOCK_RELEASE from C
SPINLOCK_RELEASE_C::
    move.l  (4,A7),A0                 ; Get Spinlock* from the stack into A0

; Expects A0 to point to spinlock
SPINLOCK_RELEASE::
    clr.b   (A0)                      ; Clear the lock
    rts

