;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2019-2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; EQUates for Rosco_m68k
;------------------------------------------------------------

; Version (embedded into firmware at 0xFC0400)
; MSW is flags, LSW is split into major (MSB) and minor (LSB)
;
; Flags:
; bit 0 - 14: Reserved
; bit 15    : Snapshot version
RELEASE_VER equ     $80000101

; Memory layout
RAMBASE     equ     $0
RAMLIMIT    equ     $100000

IOBASE      equ     $F80000

ROMBASE     equ     $FC0000

; Initialisation
INIT_SSP    equ     RAMLIMIT

; MFP Location
MFPBASE     equ     IOBASE

  ifd REVISION_0
;; MFP Registers on REVISION_0 board

; MFP GPIO Registers
MFP_GPDR    equ     MFPBASE+$01
MFP_AER     equ     MFPBASE+$21
MFP_DDR     equ     MFPBASE+$11
; MFP Interrupt Controller Registers
MFP_IERA    equ     MFPBASE+$31
MFP_IERB    equ     MFPBASE+$09
MFP_IPRA    equ     MFPBASE+$29
MFP_IPRB    equ     MFPBASE+$19
MFP_ISRA    equ     MFPBASE+$39
MFP_ISRB    equ     MFPBASE+$05
MFP_IMRA    equ     MFPBASE+$25
MFP_IMRB    equ     MFPBASE+$15
MFP_VR      equ     MFPBASE+$35
; MFP Timer Registers
MFP_TACR    equ     MFPBASE+$0D
MFP_TBCR    equ     MFPBASE+$2D
MFP_TCDCR   equ     MFPBASE+$1D
MFP_TADR    equ     MFPBASE+$3D
MFP_TBDR    equ     MFPBASE+$03
MFP_TCDR    equ     MFPBASE+$23
MFP_TDDR    equ     MFPBASE+$13
; MFP USART Registers
MFP_SCR     equ     MFPBASE+$33
MFP_UCR     equ     MFPBASE+$0B
MFP_RSR     equ     MFPBASE+$2B
MFP_TSR     equ     MFPBASE+$1B
MFP_UDR     equ     MFPBASE+$3B

  else

;; MFP Registers on "fixed" boards
; MFP GPIO Registers
MFP_GPDR    equ     MFPBASE+$01
MFP_AER     equ     MFPBASE+$03
MFP_DDR     equ     MFPBASE+$05
; MFP Interrupt Controller Registers
MFP_IERA    equ     MFPBASE+$07
MFP_IERB    equ     MFPBASE+$09
MFP_IPRA    equ     MFPBASE+$0B
MFP_IPRB    equ     MFPBASE+$0D
MFP_ISRA    equ     MFPBASE+$0F
MFP_ISRB    equ     MFPBASE+$11
MFP_IMRA    equ     MFPBASE+$13
MFP_IMRB    equ     MFPBASE+$15
MFP_VR      equ     MFPBASE+$17
; MFP Timer Registers
MFP_TACR    equ     MFPBASE+$19
MFP_TBCR    equ     MFPBASE+$1B
MFP_TCDCR   equ     MFPBASE+$1D
MFP_TADR    equ     MFPBASE+$1F
MFP_TBDR    equ     MFPBASE+$21
MFP_TCDR    equ     MFPBASE+$23
MFP_TDDR    equ     MFPBASE+$25
; MFP USART Registers
MFP_SCR     equ     MFPBASE+$27
MFP_UCR     equ     MFPBASE+$29
MFP_RSR     equ     MFPBASE+$2B
MFP_TSR     equ     MFPBASE+$2D
MFP_UDR     equ     MFPBASE+$2F

  endif

; Base vector for MFP exceptions
MFP_VECBASE equ     $40

