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

; this should be a multiple of 4 and at least ~$800 (for 1st stage)
resident_size   =       $800                    ; amount of memory to reserve

                section .text.resident_init
                align  2
; NOTE: This code assumes application uses its own non-system stack area!
resident_init::
                move.l  _EFP_SD_INIT.w,d0       ; save current loader
                move.l  d0,prev_sd_init

                lea.l   resident_begin(pc),a0
                move.l  $0.w,a1
                sub.w   #resident_size,a1       ; a1 = new init stack ptr
                move.l  a1,$0.w                 ; save new initial stack
                move.l  a1,d0
                add.l   #sd_init_hook-resident_begin,d0
                move.l  d0,_EFP_SD_INIT.w

                move.l  a1,d0
                move.w  #(resident_end-resident_begin)/4-1,d0
.copy_resident: move.l  (a0)+,(a1)+
                dbra    d0,.copy_resident                
                rts
;
; code that will remain resident in high-memory on warm-boot
;
                align   4
resident_begin:
                dc.l    $b007c0de               ; no SD boot signature

sd_init_hook:   moveq.l #1,d1                   ; message
                lea.l   sd_init_str(pc),a0
                trap    #14
                move.l  $0.w,a0                 ; restore mem top
                add.w   #resident_size,a0
                move.l  a0,$0.w
                move.l  prev_sd_init(pc),d0     ; restore sd init
                move.l  d0,_EFP_SD_INIT.w
                moveq   #-1,d0                  ; return fail
                rts

prev_sd_init:   dc.l    0
sd_init_str:    dc.b    "[SD card booting skipped]",0
                align   4
resident_end:
;
; verify code fits in reserved size
;
        if      (resident_end-resident_begin)>resident_size
        fail   "Resident code is too large"
        endif
