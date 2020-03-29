EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 6
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2020-02-25"
Rev "1"
Comp ""
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2020 Ross Bamford and Contributors"
$EndDescr
$Sheet
S 1750 2200 600  1000
U 5E53B4B8
F0 "Cpu_Ram_Rom" 50
F1 "Cpu_Ram_Rom.sch" 50
F2 "D[0..15]" I L 1750 3050 50 
F3 "A[1..23]" I L 1750 2850 50 
$EndSheet
$Sheet
S 3750 2200 600  1000
U 5E53B630
F0 "MC68901_Decoder" 50
F1 "MC68901_Decoder.sch" 50
F2 "D[0..15]" I L 3750 3050 50 
F3 "A[1..23]" I L 3750 2850 50 
$EndSheet
$Sheet
S 5750 2200 550  1000
U 5E53B810
F0 "Dtack_Boot" 50
F1 "Dtack_Boot.sch" 50
$EndSheet
$Sheet
S 7750 2200 550  1000
U 5E53B952
F0 "Clock_Reset" 50
F1 "Clock_Reset.sch" 50
$EndSheet
$Sheet
S 9750 2200 500  1000
U 5E53BC83
F0 "Expansion" 50
F1 "Expansion.sch" 50
F2 "D[0..15]" I L 9750 3050 50 
F3 "A[1..23]" I L 9750 2850 50 
$EndSheet
Text Label 1250 2500 2    50   ~ 0
D[0..15]
Wire Bus Line
	1250 2500 1250 3050
Wire Bus Line
	1250 3050 1750 3050
Wire Bus Line
	1250 3050 1250 3850
Wire Bus Line
	1250 3850 3500 3850
Wire Bus Line
	9450 3850 9450 3050
Wire Bus Line
	9450 3050 9750 3050
Connection ~ 1250 3050
Wire Bus Line
	3750 3050 3500 3050
Wire Bus Line
	3500 3050 3500 3850
Connection ~ 3500 3850
Wire Bus Line
	3500 3850 9450 3850
Text Label 1400 2300 2    50   ~ 0
A[1..23]
Wire Bus Line
	1400 2300 1400 2850
Wire Bus Line
	1400 2850 1750 2850
Wire Bus Line
	1400 2850 1400 3700
Wire Bus Line
	1400 3700 3400 3700
Wire Bus Line
	3400 3700 3400 2850
Wire Bus Line
	3400 2850 3750 2850
Connection ~ 1400 2850
Wire Bus Line
	9750 2850 9300 2850
Wire Bus Line
	9300 2850 9300 3700
Wire Bus Line
	9300 3700 3400 3700
Connection ~ 3400 3700
$EndSCHEMATC
