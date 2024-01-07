;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|          Examples
;------------------------------------------------------------
; Copyright (c)2019-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; 68020/68030 cache control, all C-callable
;------------------------------------------------------------

    include "../../../../shared/rosco_m68k_public.asm"

    section .text
mcEnableCaches::
    move.l  SDB_CPUINFO,D0              ; Get CPU info from SDB
    and.l   #$e0000000,D0               ; Just the high three bits

    cmp.l   #$40000000,D0               ; If it's less than 020...
    blt.s   .done                       ; Don't enable caches...

    mc68020
    movec.l CACR,D0                     ; Fetch CACR
    or.l    #$00000101,D0               ; Enable data and instruction caches
                                        ; (020 does not have data cache, but
                                        ; those bits are ignored anyway).
    movec.l D0,CACR

.done:
    mc68000
    rts


mcDisableCaches::
    move.l  SDB_CPUINFO,D0              ; Get CPU info from SDB
    and.l   #$e0000000,D0               ; Just the high three bits

    cmp.l   #$40000000,D0               ; If it's less than 020...
    blt.s   .done                       ; Don't enable caches...

    mc68020
    movec.l CACR,D0                     ; Fetch CACR
    and.l   #$fffffefe,D0               ; Disable data and instruction caches
                                        ; (020 does not have data cache, but
                                        ; those bits are ignored anyway).
    movec.l D0,CACR

.done:
    mc68000
    rts


mcStoreCaches::
    move.l  SDB_CPUINFO,D0              ; Get CPU info from SDB
    and.l   #$e0000000,D0               ; Just the high three bits

    cmp.l   #$40000000,D0               ; If it's less than 020...
    blt.s   .nocache                    ; Don't enable caches...

    mc68020
    movec.l CACR,D0                     ; Fetch CACR

    mc68000
    rts

.nocache
    clr.l   D0                          ; Just return 0
    rts


mcRestoreCaches::
    move.l  SDB_CPUINFO,D0              ; Get CPU info from SDB
    and.l   #$e0000000,D0               ; Just the high three bits

    cmp.l   #$40000000,D0               ; If it's less than 020...
    blt.s   .done                       ; Don't restore caches...

    mc68020
    move.l  4(A7),D0                    ; Get CACR argument
    movec.l D0,CACR                     ; Restore it

.done:
    mc68000
    rts
    
