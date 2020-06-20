;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; Basic virtual text consoles implementation
;
; A "virtual console" is simply seven function pointers,
; which look like the following:
;
;   PUTCHAR(D0.B)   - Put D0.B to the console
;   PUTSZ(A0)       - Put SZ str pointed to by A0 to console
;   D0.B = GETCHAR  - Blocking get char, return in D0.B
;   D0.B = NBGETCHAR- Non-blocking get char, return in D0.B (where supported)
;   D0.B = CHARAVAIL- Is character available? D0.B = 1 for yes, 0 for no
;   CLRSCR          - Clear screen (where supported)
;   GOTOXY(D0.W)    - Goto X=LO(D0.W), Y=HI(D0.W) (where supported)
;
; A console *must* define all these functions, however where 
; "where supported" is stated above, they may be no-op if
; applicable.
;
; These consoles are for use within the firmware only, and 
; there is *no requirement* for them to be usable from user
; mode code. Console structures should *not* be passed back
; to user code!
;
; Eventually a kernel will expand this concept out with 
; proper character devices and multiple consoles (in user
; mode). This is here only to provide basic, swappable output
; at the lowest level (i.e. for the FW TRAP #14 handlers). 
;------------------------------------------------------------

    section .text

CON_PUTCHAR::
    jmp     (DEFAULT_CONSOLE)
    






    section .data

DEFAULT_CONSOLE   dcb.l     2,0
