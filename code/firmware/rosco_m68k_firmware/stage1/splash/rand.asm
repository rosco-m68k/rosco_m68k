; Source: http://www.6502.org/users/mycorner/68k/prng/index.html
;
; RND(n), 32 bit Galois version. make n=0 for 19th next number in
; sequence or n<>0 to get 19th next number in sequence after seed n.	
; This version of the PRNG uses the Galois method and a sample of
; 65536 bytes produced gives the following values.
;
; Entropy = 7.997442 bits per byte
; Optimum compression would reduce these 65536 bytes by 0 percent
;
; Chi square distribution for 65536 samples is 232.01, and
; randomly would exceed this value 75.00 percent of the time
;
; Arithmetic mean value of data bytes is 127.6724, 127.5 = random
; Monte Carlo value for Pi is 3.122871269, error 0.60 percent
; Serial correlation coefficient is -0.000370, uncorrelated = 0.0

    section .text
srand::
    MOVE.l  4(A7),Prng32        ; Store seed
    RTS
     
rand::
	MOVEQ	#$AF-$100,d1	    ; set EOR value
	MOVEQ	#18,d2		        ; do this 19 times
	MOVE.l	Prng32,d0	        ; get current 
Ninc0:
	ADD.l	d0,d0		        ; shift left 1 bit
	BCC.s	Ninc1		        ; branch if bit 32 not set

	EOR.b	d1,d0		        ; do galois LFSR feedback
Ninc1
	DBF	d2,Ninc0	            ; loop

	MOVE.l	d0,Prng32	        ; save back to seed word
	RTS

    section .bss
Prng32
	ds.l	1		            ; random number store