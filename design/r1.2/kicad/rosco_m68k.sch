EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 4
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-03-05"
Rev "1.22"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
$Sheet
S 5250 3300 600  1000
U 5E53B4B8
F0 "Main_Bus" 50
F1 "Cpu_Ram_Rom.sch" 50
F2 "D[0..15]" I L 5250 4200 50 
F3 "A[1..23]" I L 5250 3400 50 
$EndSheet
$Sheet
S 6400 3300 600  1000
U 5E53B952
F0 "Glue" 50
F1 "Glue.sch" 50
F2 "A[1..23]" I L 6400 3400 50 
$EndSheet
$Sheet
S 7600 3300 600  1000
U 5E53BC83
F0 "Expansion" 50
F1 "Expansion.sch" 50
F2 "D[0..15]" I L 7600 4200 50 
F3 "A[1..23]" I L 7600 3400 50 
$EndSheet
Text Label 4100 4550 2    50   ~ 0
D[0..15]
Text Label 4100 3050 2    50   ~ 0
A[1..23]
Wire Bus Line
	5250 4200 4900 4200
Wire Bus Line
	4100 3050 4900 3050
Wire Bus Line
	4900 3050 4900 3400
Wire Bus Line
	4900 3400 5250 3400
Wire Bus Line
	4900 3050 6150 3050
Wire Bus Line
	6150 3050 6150 3400
Wire Bus Line
	6150 3400 6400 3400
Connection ~ 4900 3050
Wire Bus Line
	6150 3050 7350 3050
Wire Bus Line
	7350 3050 7350 3400
Wire Bus Line
	7350 3400 7600 3400
Connection ~ 6150 3050
Wire Bus Line
	4100 4550 4900 4550
Wire Bus Line
	4900 4200 4900 4550
Wire Bus Line
	7350 4550 4900 4550
Wire Bus Line
	7350 4200 7600 4200
Wire Bus Line
	7350 4200 7350 4550
Connection ~ 4900 4550
$EndSCHEMATC
