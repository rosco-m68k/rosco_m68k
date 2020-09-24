*
* vim: set et ts=8 sw=8
*------------------------------------------------------------
*                                  ___ ___ _   
*  ___ ___ ___ ___ ___       _____|  _| . | |_ 
* |  _| . |_ -|  _| . |     |     | . | . | '_|
* |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
*                     |_____|                       
* ------------------------------------------------------------
* Copyright (c) 2020 Xark
* MIT License
* ------------------------------------------------------------
*

LCD_CS    = $04
LCD_CIPO  = $08
LCD_DCRS  = $10
LCD_COPI  = $20
LCD_SCK   = $40

                include "../../shared/equates.S"

                section .stext          ; "small" text segment (16-bit addresses < $8000)
                align  2
                if 0

; C callable
xspi_send_data::
                movem.l d2-d5,-(sp)
                move.l  #MFP_GPDR,a1
                moveq.l #LCD_DCRS,d2                   ; lo_0
                moveq.l #LCD_DCRS|LCD_COPI,d3          ; lo_1
                moveq.l #LCD_DCRS|LCD_SCK,d4           ; hi_0
                moveq.l #LCD_DCRS|LCD_SCK|LCD_COPI,d5  ; h1_1
                move.w  20+2(sp),d0
                bra.s   _xspi_send_byte

; C callable
xspi_send_cmd::
                movem.l d2-d5,-(sp)
                move.l  #MFP_GPDR,a1
                moveq.l #0,d2                 ; lo_0
                moveq.l #LCD_COPI,d3          ; lo_1
                moveq.l #LCD_SCK,d4           ; hi_0
                moveq.l #LCD_SCK|LCD_COPI,d5  ; h1_1
                move.w  20+2(sp),d0
                bra.s   _xspi_send_byte

; C callable
xspi_send_word_count::
                movem.l d2-d6,-(sp)
                moveq   #0,d0
                move.b  24+2(sp),d0
                swap    d0
                move.b  24+3(sp),d0

                move.l  d0,d1
                lsl.l   #4,d0
                add.l   d1,d0
                add.l   d0,d0

                move.w  28+2(sp),d6
                move.l  #MFP_GPDR,a1
                moveq.l #LCD_DCRS,d2                   ; lo_0
                moveq.l #LCD_DCRS|LCD_COPI,d3          ; lo_1
                moveq.l #LCD_DCRS|LCD_SCK,d4           ; hi_0
                moveq.l #LCD_DCRS|LCD_SCK|LCD_COPI,d5  ; h1_1

.end_loop       dbra    d6,.high_word
                movem.l (sp)+,d2-d6
                rts

.high_word
                swap    d0
                lea.l   .low_word(pc),a0            ; 8
                jmp     xspi_send_00(pc,d0.w)
.low_word
                swap    d0
                lea.l   .end_loop(pc),a0            ; 8
                jmp     xspi_send_00(pc,d0.w)

_xspi_send_byte
                move.w  d0,d1
                lsl.w   #4,d0
                add.w   d1,d0
                add.w   d0,d0
                lea     .ret(pc),a0
                jmp     xspi_send_00(pc,d0.w)
.ret
                movem.l (sp)+,d2-d5
                rts

                else

_xspi_send_byte::
                move.w  d0,d1
                lsl.w   #4,d0
                add.w   d1,d0
                add.w   d0,d0
                jmp     xspi_send_00(pc,d0.w)


_xspi_send_word::
                move.w  d0,d1
                lsr.w   #8,d0
                swap    d0
                move.b  d1,d0

                move.l  d0,d1
                lsl.l   #4,d0
                add.l   d1,d0
                add.l   d0,d0

                swap    d0
                lea.l   .ret(pc),a0                 ; 8
                jmp     xspi_send_00(pc,d0.w)
.ret
                swap    d0                        ; 4
                move.l  a2,a0                     ; 8
                jmp     xspi_send_00(pc,d0.w)


_xspi_send_word_count::
                move.w  d0,d1
                lsr.w   #8,d0
                swap    d0
                move.b  d1,d0

                move.l  d0,d1
                lsl.l   #4,d0
                add.l   d1,d0
                add.l   d0,d0

.end_loop       dbra    d6,.high_word
                jmp     (a2)

.high_word
                swap    d0
                lea.l   .low_word(pc),a0            ; 8
                jmp     xspi_send_00(pc,d0.w)
.low_word
                swap    d0
                lea.l   .end_loop(pc),a0            ; 8
                jmp     xspi_send_00(pc,d0.w)

                endif

                if 0
; C callable
xspi_send_word::
                movem.l d2-d5,-(sp)
                moveq   #0,d0
                move.b  20+3(sp),d0
                swap    d0
                move.b  20+2(sp),d0

                move.l  d0,d1
                lsl.l   #4,d0
                add.l   d1,d0
                add.l   d0,d0

                move.l  #MFP_GPDR,a1
                moveq.l #LCD_DCRS,d2                   ; lo_0
                moveq.l #LCD_DCRS|LCD_COPI,d3          ; lo_1
                moveq.l #LCD_DCRS|LCD_SCK,d4           ; hi_0
                moveq.l #LCD_DCRS|LCD_SCK|LCD_COPI,d5  ; h1_1
                lea.l   .ret(pc),a0                 ; 8
                jmp     xspi_send_00(pc,d0.w)
.ret
                swap    d0                        ; 4
                lea.l   .ret2(pc),a0                ; 8
                jmp     xspi_send_00(pc,d0.w)
.ret2
                movem.l (sp)+,d2-d5
                rts

                endif

; inline routines per value to send (34 bytes per routine)
xspi_send_00:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_01:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_02:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_03:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_04:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_05:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_06:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_07:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_08:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_09:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_0A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_0B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_0C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_0D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_0E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_0F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_10:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_11:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_12:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_13:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_14:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_15:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_16:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_17:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_18:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_19:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_1A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_1B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_1C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_1D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_1E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_1F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_20:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_21:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_22:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_23:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_24:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_25:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_26:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_27:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_28:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_29:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_2A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_2B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_2C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_2D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_2E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_2F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_30:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_31:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_32:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_33:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_34:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_35:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_36:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_37:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_38:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_39:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_3A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_3B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_3C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_3D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_3E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_3F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_40:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_41:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_42:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_43:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_44:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_45:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_46:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_47:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_48:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_49:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_4A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_4B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_4C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_4D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_4E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_4F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_50:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_51:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_52:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_53:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_54:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_55:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_56:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_57:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_58:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_59:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_5A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_5B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_5C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_5D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_5E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_5F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_60:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_61:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_62:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_63:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_64:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_65:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_66:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_67:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_68:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_69:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_6A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_6B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_6C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_6D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_6E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_6F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_70:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_71:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_72:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_73:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_74:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_75:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_76:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_77:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_78:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_79:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_7A:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_7B:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_7C:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_7D:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_7E:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_7F:
                move.b  d2,(a1)     ; b7=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_80:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_81:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_82:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_83:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_84:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_85:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_86:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_87:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_88:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_89:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_8A:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_8B:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_8C:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_8D:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_8E:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_8F:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_90:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_91:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_92:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_93:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_94:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_95:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_96:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_97:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_98:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_99:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_9A:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_9B:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_9C:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_9D:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_9E:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_9F:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_A0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_A1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_A2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_A3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_A4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_A5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_A6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_A7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_A8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_A9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_AA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_AB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_AC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_AD:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_AE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_AF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_B0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_B1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_B2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_B3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_B4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_B5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_B6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_B7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_B8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_B9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_BA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_BB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_BC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_BD:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_BE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_BF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b6=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_C0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_C1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_C2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_C3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_C4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_C5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_C6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_C7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_C8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_C9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_CA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_CB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_CC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_CD:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_CE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_CF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_D0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_D1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_D2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_D3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_D4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_D5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_D6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_D7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_D8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_D9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_DA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_DB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_DC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_DD:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_DE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_DF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b5=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_E0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_E1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_E2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_E3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_E4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_E5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_E6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_E7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_E8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_E9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_EA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_EB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_EC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_ED:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_EE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_EF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b4=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_F0:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_F1:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_F2:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_F3:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_F4:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_F5:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_F6:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_F7:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b3=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_F8:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_F9:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_FA:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_FB:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b2=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_FC:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_FD:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b1=0
                move.b  d4,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
xspi_send_FE:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d2,(a1)     ; b0=0
                move.b  d4,(a1)
                jmp     (a0)
xspi_send_FF:
                move.b  d3,(a1)     ; b7=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b6=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b5=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b4=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b3=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b2=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b1=1
                move.b  d5,(a1)
                move.b  d3,(a1)     ; b0=1
                move.b  d5,(a1)
                jmp     (a0)
