;
; vim: set et ts=8 sw=8
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|
; ------------------------------------------------------------
; Copyright (c) 2020 Xark
; MIT License
; ------------------------------------------------------------

resident_size   =       $1000                   ; amount of memory to reserve (power of 2)

                include "../../shared/rosco_m68k_public.asm"

                section .text.resident_init
                align  2
resident_init::
                or.w    #$0700,SR               ; disable all interrupts
                move.l  a7,d1                   ; get stack ptr
                add.l   #resident_size-1,d1     ; round up
                and.l   #~(resident_size-1),d1  ; align
                move.l  d1,a0                   ; a0 = current init stack ptr
                move.l  a0,a1                   ; copy to a1
                sub.l   #resident_size,a1       ; a1 = new init stack ptr
                move.l  a1,$0.w                 ; save new initial stack
                move.w  #resident_size/4-1,d0
.copy_stack:    move.l  -(a0),-(a1)
                dbra    d0,.copy_stack

                move.l  _EFP_PROGLOADER.w,d0    ; save current loader
                move.l  d0,prev_loader
                move.l  _EFP_RECVCHAR.w,d0      ; save current recvchar
                move.l  d0,prev_recvchar

                lea.l   resident_code(pc),a0
                move.l  $0.w,a1
                move.l  a1,d0
                add.l   #loader_test-resident_code,d0
                move.l  d0,_EFP_PROGLOADER.w

                move.l  a1,d0
                add.l   #recvchar_test-resident_code,d0
                move.l  d0,_EFP_RECVCHAR.w
                move.w  #(resident_end-resident_code)/4-1,d0
.copy_resident: move.l  (a0)+,(a1)+
                dbra    d0,.copy_resident                

                sub.w   #resident_size,a7       ; adjust stack ptr
                and.w   #$F0FF,sr               ; re-enable all interrupts
                rts
;
; code that will remain resident in high-memory on warm boot
;
resident_code:
                dc.l    $c0de0042              ; signature
prev_loader:    dc.l    0
prev_recvchar:  dc.l    0

loader_test:    moveq.l #1,d1
                lea.l   upload_str(pc),a0
                trap    #14

                move.l  prev_loader(pc),a0
                jmp     (a0)

recvchar_test:  ; NO MFP bchg.b  #1,MFP_GPDR             ; toggle red LED each char received
                move.l  prev_recvchar(pc),-(a7)
                rts

upload_str:     dc.b    "*** Resident rosco_m68k program loader test successful!",13,10,13,10
                dc.b    "Now calling default firmware program loader...",13,10,0
                dc.l    0
resident_end:
;
; verify code fits in reserved size
;
        if      (resident_end-resident_code)>resident_size
        fail   "Resident code is too large"
        endif
