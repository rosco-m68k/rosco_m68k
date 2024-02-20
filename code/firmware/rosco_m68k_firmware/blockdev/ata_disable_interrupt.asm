;
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|
; ------------------------------------------------------------
; Copyright (c) 2023 Ross Bamford & Contributors
; MIT License
;
; ASM interrupt disable with bus error check for probing
; ------------------------------------------------------------

                section .text

ATA_REG_WR_DEVICE_CTL   equ     28

; Try to disable the ATA interrupt.
;
; Will set BERR_FLAG if no ATA device is installed.
;
TRY_DISABLE_ATA_INTERRUPT::
    move.l  A0,-(A7)                            ; Save regs
    move.l  8(A7),A0                            ; Get argument pointer

    jsr     INSTALL_TEMP_BERR_HANDLER           ; Install temp bus error handler
    move.l  #.POST_WRITE,BERR_CONT_ADDR         ; Set up continue addr for 68000

    move.w  #$0002,ATA_REG_WR_DEVICE_CTL(A0)    ; Try to disable IDE interrupt

.POST_WRITE:
    jsr     RESTORE_BERR_HANDLER                ; Restore the bus error handler
    move.l  (A7)+,A0                            ; Restore regs
    rts


