;
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|
; ------------------------------------------------------------
; Copyright (c) 2022 Xark
; MIT License
;
; Asm implementation based on C code by Ross Bamford
; ------------------------------------------------------------
;

                include "../../shared/rosco_m68k_public.asm"
                section .text

; Default rosco 2.x SPI pins
SPI_CS_B        equ     2       ; Output port pin
SPI_SCK_B       equ     4       ; Output port pin
SPI_COPI_B      equ     6       ; Output port pin
SPI_CIPO_B      equ     2       ; Input port pin
SPI_CS1_B       equ     7       ; Output port pin

RED_LED_B       equ     3       ; Output port pin

; calculate bit values for bit positions
SPI_CS          equ     (1<<SPI_CS_B)
SPI_CS1         equ     (1<<SPI_CS1_B)
SPI_SCK         equ     (1<<SPI_SCK_B)
SPI_COPI        equ     (1<<SPI_COPI_B)
SPI_CIPO        equ     (1<<SPI_CIPO_B)
RED_LED         equ     (1<<RED_LED_B)

; NOTE: Since DUART GPIO is active-low, use register aliases for DUART ports to be less confusing
; DUART base address in SDB_UARTBASE.w
DUART_OUT_LO    equ     W_OPR_SETCMD        ; W_OPR_SETCMD     = SET OUTPUT LO
DUART_OUT_HI    equ     W_OPR_RESETCMD      ; W_OPR_RESETCMD   = OUT OUTPUT HI
DUART_INPUT     equ     R_INPUTPORT         ; R_INPUTPORT      = READ INPUT

; read byte from DUART GPIO SPI
; int spi_read_byte(void) - C callable
spi_read_byte::
                movem.l d2-d3/a2,-(a7)          ;12+24  save d2,d3,a2
                move.l  SDB_UARTBASE.w,a0       ;   16  a0 = DUART base addr
                lea.l   DUART_OUT_LO(a0),a1     ;    8  a1 = OUTPUT LO
                lea.l   DUART_OUT_HI(a0),a2     ;    8  a2 = OUTPUT HI
                lea.l   DUART_INPUT(a0),a0      ;    8  a0 = INPUT
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_CIPO_B,d2          ;    4  d2 = CIPO bit num

; bit 7
                moveq.l #0,d0                   ;    4  clear read byte
                move.b  d1,(a1)                 ;    8  set SCK LO
                btst.b  d2,(a0)                 ;    8  read input CIPO bit
                sne     d3                      ;  4/6  d3 = 0 or -1
                sub.b   d3,d0                   ;    4  set low bit of read byte
                move.b  d1,(a2)                 ;    8  set SCK HI

                rept    7
; bit 6...0
                add.b   d0,d0                   ;    4  shift read byte left
                move.b  d1,(a1)                 ;    8  set SCK LO
                btst.b  d2,(a0)                 ;    8  read input CIPO bit
                sne     d3                      ;  4/6  d3 = 0 or -1
                sub.b   d3,d0                   ;    4  set low bit of read byte
                move.b  d1,(a2)                 ;    8  set SCK HI

                endr

                movem.l (a7)+,d2-d3/a2          ;12+24  restore d2,d3,a2
spi_rb_rts:     rts

; read byte from DUART GPIO SPI (C callable: int spi_read_byte(void))
; void spi_read_buffer(void* data, int count) - C callable
spi_read_buffer::
                move.l  8(sp),d0                ;   12  load count  
                ble.s   spi_rb_rts              ; 8/10  rts if <= 0

                move.l  4(sp),a0                ;   12  load data buffer
                movem.l d2-d4/a2-a3,-(a7)       ;12+24  save d2,d3,a2,a3
                move.l  SDB_UARTBASE.w,a1       ;   16  a1 = DUART base addr
                lea.l   DUART_OUT_LO(a1),a2     ;    8  a2 = GPIO OUT LO
                lea.l   DUART_OUT_HI(a1),a3     ;    8  a3 = GPIO OUT HI
                lea.l   DUART_INPUT(a1),a1      ;    8  a1 = GPIO INPUT
                move.b  #RED_LED,(a2)           ;   12  RED LED on
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_CIPO_B,d2          ;    4  d2 = CIPO bit num
                                                ;       d3 = temp bit (0 or -1)
                                                ;       d4 = temp byte
.spi_rb_loop:
; bit 7
                moveq.l #0,d4                   ;    4  clear read byte
                move.b  d1,(a2)                 ;    8  set SCK LO
                btst.b  d2,(a1)                 ;    8  read input CIPO bit
                sne     d3                      ;  4/6  d3 = 0 or -1
                sub.b   d3,d4                   ;    4  set low bit of read byte
                move.b  d1,(a3)                 ;    8  set SCK HI

                rept    7
; bit 6...0
                add.b   d4,d4                   ;    4  shift read byte left
                move.b  d1,(a2)                 ;    8  set SCK LO
                btst.b  d2,(a1)                 ;    8  read input CIPO bit
                sne     d3                      ;  4/6  d3 = 0 or -1
                sub.b   d3,d4                   ;    4  set low bit of read byte
                move.b  d1,(a3)                 ;    8  set SCK HI

                endr

                move.b  d4,(a0)+
                subq.l  #1,d0
                bne.s   .spi_rb_loop  

                move.b  #RED_LED,(a3)           ;   12  RED LED off

                movem.l (a7)+,d2-d4/a2-a3          ;12+24  restore d2,d3,a2,a3
                rts
