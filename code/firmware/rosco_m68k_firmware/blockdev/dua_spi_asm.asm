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
DUART_INPUT     equ     DUART_BASE_MBR2+R_INPUTPORT     ; R_INPUTPORT      = GPIO input address
DUART_OUT_LO    equ     DUART_BASE_MBR2+W_OPR_SETCMD    ; W_OPR_SETCMD     = GPIO output LO address
OUT_LO_OFFSET   equ     W_OPR_SETCMD-R_INPUTPORT        ; W_OPR_SETCMD     = GPIO output LO (offset from input addr) 
OUT_HI_OFFSET   equ     W_OPR_RESETCMD-W_OPR_SETCMD     ; W_OPR_RESETCMD   = GPIO output HI (offset from LO addr) 

; send byte to SPI via DUART GPIO
; void spi_send_byte(int byte) - C callable
spi_send_byte::
                move.b  4+3(sp),d0              ;   12  d0 = send byte
                movem.l d2-d5,-(a7)             ;12+32  save regs
                move.l  #DUART_OUT_LO,a0        ;   12  a0 = output LO
                lea.l   OUT_HI_OFFSET(a0),a1    ;    8  a1 = output HI
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_COPI,d2            ;    4  d2 = COPI bit mask
                moveq.l #SPI_SCK|SPI_COPI,d3    ;    4  d3 = SCK|COPI bit mask
                                                ;       d4 = temp (COPI LO)
                                                ;       d5 = temp (COPI HI)

            rept    8
; send bits 7...0
                add.b   d0,d0                   ;    4  shift MSB to carry
                scs     d5                      ;  4/6  temp set to 0 or 0xff based on carry
                and.b   d2,d5                   ;    4  isolate COPI HI bit to output
                move.b  d5,d4                   ;    4  copy COPI HI bit
                eor.b   d3,d4                   ;    4  set SCK LO and invert COPI for LO bit 
                move.b  d4,(a0)                 ;    8  output SCK LO and COPI LO (if send bit LO)
                move.b  d5,(a1)                 ;    8  output COPI HI (if send bit HI)
                move.b  d1,(a1)                 ;    8  output SCK HI
            endr

                movem.l (a7)+,d2-d5             ;12+32  restore regs
spi_sb_rts:     rts

; send count bytes from buffer to SPI via DUART GPIO
; void spi_send_buffer(void* data, int count) - C callable
spi_send_buffer::
                move.l  8(sp),d0                ;   16  d0 = byte count  
                ble.s   spi_sb_rts              ; 8/10  done if <= 0

                move.l  4(sp),a0                ;   16  a0 = data buffer
                movem.l d2-d6/a2,-(a7)          ;12+48  save regs
                move.l  #DUART_OUT_LO,a1        ;   12  a1 = output LO
                lea.l   OUT_HI_OFFSET(a1),a2    ;    8  a2 = output HI
                moveq.l #SPI_SCK,d2             ;    4  d2 = SCK bit mask
                moveq.l #SPI_COPI,d3            ;    4  d3 = COPI bit mask
                moveq.l #SPI_SCK|SPI_COPI,d4    ;    4  d4 = SCK|COPI bit mask
                                                ;       d5 = temp COPI LO
                                                ;       d6 = temp COPI HI
                move.b  #RED_LED,(a1)           ;   12  RED LED on (active LO)

.spi_sb_loop:   move.b  (a0)+,d1                ;    8  load send byte

                rept    8
; send bits 7...0
                add.b   d1,d1                   ;    4  shift MSB to carry
                scs     d6                      ;  4/6  temp set to 0 or 0xff based on carry
                and.b   d3,d6                   ;    4  isolate COPI HI bit to output
                move.b  d6,d5                   ;    4  copy COPI HI bit
                eor.b   d4,d5                   ;    4  set SCK LO and invert COPI for LO bit 
                move.b  d5,(a1)                 ;    8  output SCK LO and COPI LO (if send bit LO)
                move.b  d6,(a2)                 ;    8  output COPI HI (if send bit HI)
                move.b  d2,(a2)                 ;    8  output SCK HI

                endr

                subq.l  #1,d0
                bne     .spi_sb_loop  

                move.b  #RED_LED,(a2)           ;   12  RED LED off (active LO)
                movem.l (a7)+,d2-d6/a2          ;12+48  restore regs
                rts

; read byte from DUART GPIO SPI
; int spi_read_byte(void) - C callable
spi_read_byte::
                movem.l d2-d3/a2,-(a7)          ;12+24  save regs
                move.l  #DUART_INPUT,a0         ;    12 a0 = input
                lea.l   OUT_LO_OFFSET(a0),a1    ;    8  a1 = output LO
                lea.l   OUT_HI_OFFSET(a1),a2    ;    8  a2 = output HI
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_CIPO_B,d2          ;    4  d2 = CIPO bit number
                                                ;       d3 = temp

; read bit 7
                moveq.l #0,d0                   ;    4  clear read byte
                move.b  d1,(a1)                 ;    8  output SCK LO
                btst.b  d2,(a0)                 ;    8  test input CIPO bit
                sne     d3                      ;  4/6  temp set to 0 or 0xff based on CIPO bit
                sub.b   d3,d0                   ;    4  set low bit of read byte by subtracting 0 or -1
                move.b  d1,(a2)                 ;    8  output SCK HI

            rept    7
; read bits 6...0
                add.b   d0,d0                   ;    4  shift read byte left
                move.b  d1,(a1)                 ;    8  output SCK LO
                btst.b  d2,(a0)                 ;    8  test input CIPO bit
                sne     d3                      ;  4/6  temp set to 0 or 0xff based on CIPO bit
                sub.b   d3,d0                   ;    4  set low bit of read byte by subtracting 0 or -1
                move.b  d1,(a2)                 ;    8  output SCK HI
            endr
                movem.l (a7)+,d2-d3/a2          ;12+24  restore regs
                                                ;       d0 = result read byte
spi_rb_rts:     rts

; read count bytes into buffer from DUART GPIO SPI
; void spi_read_buffer(void* data, int count) - C callable
spi_read_buffer::
                move.l  8(sp),d0                ;   12  load count  
                ble.s   spi_rb_rts              ; 8/10  rts if <= 0

                move.l  4(sp),a0                ;   12  load data buffer
                movem.l d2-d4/a2-a3,-(a7)       ;12+40  save regs
                move.l  #DUART_INPUT,a1         ;    12 a1 = input
                lea.l   OUT_LO_OFFSET(a1),a2    ;    8  a2 = output LO
                lea.l   OUT_HI_OFFSET(a2),a3    ;    8  a3 = output HI
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_CIPO_B,d2          ;    4  d2 = CIPO bit num
                                                ;       d3 = temp bit
                                                ;       d4 = temp byte
                move.b  #RED_LED,(a2)           ;   12  RED LED on (active LO)
.spi_rb_loop:
            rept    8
; read bits 7...0
                add.b   d4,d4                   ;    4  shift read byte left
                move.b  d1,(a2)                 ;    8  set SCK LO
                btst.b  d2,(a1)                 ;    8  read input CIPO bit
                sne     d3                      ;  4/6  d3 = 0 or -1
                sub.b   d3,d4                   ;    4  set low bit of read byte
                move.b  d1,(a3)                 ;    8  set SCK HI
            endr

                move.b  d4,(a0)+                ;    8  save read byte
                subq.l  #1,d0                   ;    8  decrement count
                bne.s   .spi_rb_loop            ; 8/10  loop if not zero

                move.b  #RED_LED,(a3)           ;   12  RED LED off (active LO)
                movem.l (a7)+,d2-d4/a2-a3       ;12+40  restore regs
                rts

            ifd WIP_UNTESTED_CODE               ; untested below, ignore

; exchange byte with DUART GPIO SPI
; int spi_exchange_byte(int byte) - C callable
spi_exchange_byte::
                move.b  4+3(sp),d0              ;   12  d0 = send byte
                movem.l d2-d6/a2,-(a7)          ;12+48  save regs
                move.l  #DUART_INPUT,a0         ;    12 a0 = input
                lea.l   OUT_LO_OFFSET(a0),a1    ;    8  a1 = output LO
                lea.l   OUT_HI_OFFSET(a1),a2    ;    8  a2 = output HI
                moveq.l #SPI_SCK,d1             ;    4  d1 = SCK bit mask
                moveq.l #SPI_COPI,d2            ;    4  d2 = COPI bit mask
                moveq.l #SPI_SCK|SPI_COPI,d3    ;    4  d3 = SCK|COPI bit mask
                moveq.l #SPI_CIPO_B,d4          ;    4  d4 = CIPO bit number
                                                ;       d5 = temp (COPI LO)
                                                ;       d6 = temp (COPI HI)

            rept    8
; exchange bits 7...0
                add.b   d0,d0                   ;    4  shift MSB to carry
                scs     d6                      ;  4/6  temp set to 0 or 0xff based on carry
                and.b   d2,d6                   ;    4  isolate COPI HI bit to output
                move.b  d6,d5                   ;    4  copy COPI HI bit
                eor.b   d3,d5                   ;    4  set SCK LO and invert COPI for LO bit 
                move.b  d5,(a1)                 ;    8  output SCK LO and COPI LO (if send bit LO)
                btst.b  d4,(a0)                 ;    8  read input CIPO bit
                sne     d6                      ;  4/6  temp set to 0 or 0xff based on CIPO bit
                sub.b   d6,d0                   ;    4  set low bit of read byte by subtracting 0 or -1
                move.b  d6,(a2)                 ;    8  output COPI HI (if send bit HI)
                move.b  d1,(a2)                 ;    8  output SCK HI
            endr

                movem.l (a7)+,d2-d6/a2          ;12+48  restore regs
spi_eb_rts:     rts

            endif
