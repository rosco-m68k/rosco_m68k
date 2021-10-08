EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr User 19128 10939
encoding utf-8
Sheet 4 5
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-10-08"
Rev "2.0"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
Wire Wire Line
	9550 2400 9650 2500
Wire Wire Line
	9550 2500 9650 2600
Wire Wire Line
	9550 2600 9650 2700
Wire Wire Line
	9550 2700 9650 2800
Wire Wire Line
	9550 2800 9650 2900
Wire Wire Line
	9550 2900 9650 3000
Wire Wire Line
	9550 3000 9650 3100
Wire Wire Line
	9550 3100 9650 3200
Wire Wire Line
	9550 3200 9650 3300
Wire Wire Line
	9550 3300 9650 3400
Wire Wire Line
	9550 3400 9650 3500
Wire Wire Line
	9550 3500 9650 3600
Wire Wire Line
	9550 3600 9650 3700
Wire Wire Line
	9550 3700 9650 3800
Wire Wire Line
	9550 3800 9650 3900
Wire Wire Line
	9550 3900 9650 4000
Wire Wire Line
	9550 4000 9650 4100
Wire Wire Line
	9550 4100 9650 4200
Wire Wire Line
	9550 4200 9650 4300
Wire Wire Line
	9550 4300 9650 4400
Wire Wire Line
	9550 4400 9650 4500
Wire Wire Line
	9550 4500 9650 4600
Wire Wire Line
	9550 4600 9650 4700
Text GLabel 10000 4800 0    47   Output ~ 0
AS
Text GLabel 10000 4900 0    47   Input ~ 0
BERR
Text GLabel 10000 5000 0    47   Output ~ 0
BG
Text GLabel 10000 5100 0    47   Input ~ 0
BGACK
Text GLabel 10000 5200 0    47   Input ~ 0
BR
Text GLabel 10000 5300 0    47   Input ~ 0
DTACK
Text GLabel 10000 5400 0    47   Output ~ 0
RW
Wire Wire Line
	10500 2500 11000 2500
Text GLabel 10500 2600 2    47   Output ~ 0
CLK
Text GLabel 10500 3200 2    47   Output ~ 0
IOSEL
Text GLabel 10500 3300 2    47   Output ~ 0
EXPSEL
Text GLabel 10500 3400 2    47   Output ~ 0
FC0
Text GLabel 10500 3500 2    47   Output ~ 0
FC1
Text GLabel 10500 3600 2    47   Output ~ 0
FC2
Text GLabel 10500 3700 2    47   Input ~ 0
IPL0
Text GLabel 10500 3800 2    47   Input ~ 0
IPL1
Text GLabel 10500 3900 2    47   Input ~ 0
IPL2
Text GLabel 10500 4000 2    47   Output ~ 0
LDS
Text GLabel 10500 4100 2    47   Output ~ 0
UDS
Text GLabel 10500 4200 2    47   BiDi ~ 0
RESET
Entry Wire Line
	9450 2300 9550 2400
Entry Wire Line
	9450 2400 9550 2500
Entry Wire Line
	9450 2500 9550 2600
Entry Wire Line
	9450 2600 9550 2700
Entry Wire Line
	9450 2700 9550 2800
Entry Wire Line
	9450 2800 9550 2900
Entry Wire Line
	9450 2900 9550 3000
Entry Wire Line
	9450 3000 9550 3100
Entry Wire Line
	9450 3100 9550 3200
Entry Wire Line
	9450 3200 9550 3300
Entry Wire Line
	9450 3300 9550 3400
Entry Wire Line
	9450 3400 9550 3500
Entry Wire Line
	9450 3500 9550 3600
Entry Wire Line
	9450 3600 9550 3700
Entry Wire Line
	9450 3700 9550 3800
Entry Wire Line
	9450 3800 9550 3900
Entry Wire Line
	9450 3900 9550 4000
Entry Wire Line
	9450 4000 9550 4100
Entry Wire Line
	9450 4100 9550 4200
Entry Wire Line
	9450 4200 9550 4300
Entry Wire Line
	9450 4300 9550 4400
Entry Wire Line
	9450 4400 9550 4500
Entry Wire Line
	9450 4500 9550 4600
Text Label 10900 5600 0    50   ~ 0
D2
Text Label 10900 5500 0    50   ~ 0
D3
Text Label 10900 5400 0    50   ~ 0
D4
Text Label 10900 5300 0    50   ~ 0
D5
Text Label 10900 5200 0    50   ~ 0
D6
Text Label 10900 5100 0    50   ~ 0
D7
Text Label 10900 5000 0    50   ~ 0
D8
Text Label 10900 4900 0    50   ~ 0
D9
Text Label 10900 4800 0    50   ~ 0
D10
Text Label 10900 4700 0    50   ~ 0
D11
Text Label 10900 4600 0    50   ~ 0
D12
Text Label 10900 4500 0    50   ~ 0
D13
Text Label 10900 4400 0    50   ~ 0
D14
Text Label 10900 4300 0    50   ~ 0
D15
Entry Wire Line
	11150 4200 11050 4300
Entry Wire Line
	11050 4400 11150 4300
Entry Wire Line
	11050 4500 11150 4400
Entry Wire Line
	11050 4600 11150 4500
Entry Wire Line
	11050 4700 11150 4600
Entry Wire Line
	11050 4800 11150 4700
Entry Wire Line
	11050 4900 11150 4800
Entry Wire Line
	11050 5000 11150 4900
Entry Wire Line
	11050 5100 11150 5000
Entry Wire Line
	11050 5200 11150 5100
Entry Wire Line
	11050 5300 11150 5200
Entry Wire Line
	11050 5400 11150 5300
Text HLabel 11250 4100 2    50   Input ~ 0
D[0..15]
Wire Bus Line
	11250 4100 11150 4100
Text Label 9650 2500 0    50   ~ 0
A1
Text Label 9650 2600 0    50   ~ 0
A2
Text Label 9650 2700 0    50   ~ 0
A3
Text Label 9650 2800 0    50   ~ 0
A4
Text Label 9650 2900 0    50   ~ 0
A5
Text Label 9650 3000 0    50   ~ 0
A6
Text Label 9650 3100 0    50   ~ 0
A7
Text Label 9650 3200 0    50   ~ 0
A8
Text Label 9650 3300 0    50   ~ 0
A9
Text Label 9650 3400 0    50   ~ 0
A10
Text Label 9650 3500 0    50   ~ 0
A11
Text Label 9650 3600 0    50   ~ 0
A12
Text Label 9650 3700 0    50   ~ 0
A13
Text Label 9650 3800 0    50   ~ 0
A14
Text Label 9650 3900 0    50   ~ 0
A15
Text Label 9650 4000 0    50   ~ 0
A16
Text Label 9650 4100 0    50   ~ 0
A17
Text Label 9650 4200 0    50   ~ 0
A18
Text Label 9650 4300 0    50   ~ 0
A19
Text Label 9650 4400 0    50   ~ 0
A20
Text Label 9650 4500 0    50   ~ 0
A21
Text Label 9650 4600 0    50   ~ 0
A22
Text Label 9650 4700 0    50   ~ 0
A23
Text HLabel 9350 2150 0    50   Input ~ 0
A[1..23]
Wire Bus Line
	9350 2150 9450 2150
$Comp
L power:VCC #PWR0151
U 1 1 5FD5B222
P 11050 1900
F 0 "#PWR0151" H 11050 1750 50  0001 C CNN
F 1 "VCC" H 11067 2073 50  0000 C CNN
F 2 "" H 11050 1900 50  0001 C CNN
F 3 "" H 11050 1900 50  0001 C CNN
	1    11050 1900
	1    0    0    -1  
$EndComp
Wire Wire Line
	11000 1900 11000 2500
$Comp
L power:GND #PWR0152
U 1 1 5FD5E976
P 11700 5550
F 0 "#PWR0152" H 11700 5300 50  0001 C CNN
F 1 "GND" H 11705 5377 50  0000 C CNN
F 2 "" H 11700 5550 50  0001 C CNN
F 3 "" H 11700 5550 50  0001 C CNN
	1    11700 5550
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB083A
P 13300 4800
AR Path="/5E53BCCF/5FDB083A" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB083A" Ref="H1"  Part="1" 
F 0 "H1" H 13300 5000 50  0000 C CNN
F 1 "MountingHole" H 13300 4925 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 13300 4800 50  0001 C CNN
F 3 "~" H 13300 4800 50  0001 C CNN
	1    13300 4800
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB0840
P 13300 5150
AR Path="/5E53BCCF/5FDB0840" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB0840" Ref="H2"  Part="1" 
F 0 "H2" H 13300 5350 50  0000 C CNN
F 1 "MountingHole" H 13300 5275 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 13300 5150 50  0001 C CNN
F 3 "~" H 13300 5150 50  0001 C CNN
	1    13300 5150
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB0846
P 13300 5500
AR Path="/5E53BCCF/5FDB0846" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB0846" Ref="H3"  Part="1" 
F 0 "H3" H 13300 5700 50  0000 C CNN
F 1 "MountingHole" H 13300 5625 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 13300 5500 50  0001 C CNN
F 3 "~" H 13300 5500 50  0001 C CNN
	1    13300 5500
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB084C
P 13300 5850
AR Path="/5E53BCCF/5FDB084C" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB084C" Ref="H4"  Part="1" 
F 0 "H4" H 13300 6050 50  0000 C CNN
F 1 "MountingHole" H 13300 5975 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 13300 5850 50  0001 C CNN
F 3 "~" H 13300 5850 50  0001 C CNN
	1    13300 5850
	1    0    0    -1  
$EndComp
Text GLabel 10500 3100 2    50   Output ~ 0
IEO
Text GLabel 11300 2800 2    50   Input ~ 0
VPA
Text GLabel 10500 3000 2    50   Output ~ 0
VMA
Text GLabel 10500 2900 2    50   Output ~ 0
E
$Comp
L Device:R R19
U 1 1 600B8632
P 11100 2300
F 0 "R19" H 11170 2346 50  0000 L CNN
F 1 "10K" H 11170 2255 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 11030 2300 50  0001 C CNN
F 3 "~" H 11100 2300 50  0001 C CNN
	1    11100 2300
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x32_Odd_Even J3
U 1 1 5EE9DB9A
P 10200 4000
F 0 "J3" H 10250 5717 50  0000 C CNN
F 1 "Conn_02x32_Odd_Even" H 10250 5626 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x32_P2.54mm_Vertical" H 10200 4000 50  0001 C CNN
F 3 "~" H 10200 4000 50  0001 C CNN
	1    10200 4000
	1    0    0    -1  
$EndComp
Entry Wire Line
	11050 5500 11150 5400
Entry Wire Line
	11050 5600 11150 5500
Entry Wire Line
	11050 5700 11150 5600
Entry Wire Line
	11050 5800 11150 5700
Wire Wire Line
	9900 5700 9900 5600
Wire Wire Line
	9900 5600 10000 5600
Wire Wire Line
	9800 5800 9800 5500
Wire Wire Line
	9800 5500 10000 5500
Text Label 11000 5700 2    50   ~ 0
D1
Text Label 11000 5800 2    50   ~ 0
D0
Wire Wire Line
	5150 6650 4250 6650
Wire Wire Line
	4250 6650 4250 6750
Wire Wire Line
	4250 6750 3750 6750
Wire Wire Line
	3750 6750 3250 6750
Connection ~ 3750 6750
Connection ~ 3250 6750
Wire Wire Line
	5150 6550 4250 6550
Wire Wire Line
	4250 6550 4250 6450
Wire Wire Line
	4250 6450 3750 6450
Wire Wire Line
	3750 6450 3250 6450
Connection ~ 3750 6450
Connection ~ 3250 6450
$Comp
L rosco_m68k-eagle-import:PINHD-1X2 JP?
U 1 1 5F55DF2F
P 5250 6650
AR Path="/5F55DF2F" Ref="JP?"  Part="1" 
AR Path="/5E53B952/5F55DF2F" Ref="JP?"  Part="1" 
AR Path="/5E53BC83/5F55DF2F" Ref="J1"  Part="1" 
F 0 "J1" H 5000 6875 59  0000 L BNN
F 1 "PWR" H 5000 6450 59  0000 L BNN
F 2 "rosco_m68k:1X02" H 5250 6650 50  0001 C CNN
F 3 "" H 5250 6650 50  0001 C CNN
F 4 "+5V" H 5350 6750 59  0001 L BNN "1"
F 5 "GND" H 5350 6650 59  0001 L BNN "2"
	1    5250 6650
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE3.5-10 C?
U 1 1 5F55DF35
P 3750 6550
AR Path="/5F55DF35" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F55DF35" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F55DF35" Ref="C21"  Part="1" 
F 0 "C21" H 3795 6569 59  0000 L BNN
F 1 "470uF" H 3795 6369 59  0000 L BNN
F 2 "rosco_m68k:E3,5-10" H 3750 6550 50  0001 C CNN
F 3 "" H 3750 6550 50  0001 C CNN
	1    3750 6550
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F55DF3B
P 3250 6550
AR Path="/5F55DF3B" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F55DF3B" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F55DF3B" Ref="C19"  Part="1" 
F 0 "C19" H 3295 6569 59  0000 L BNN
F 1 "100uF" H 3295 6369 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 3250 6550 50  0001 C CNN
F 3 "" H 3250 6550 50  0001 C CNN
	1    3250 6550
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG?
U 1 1 5F55DF41
P 3750 6450
AR Path="/5E53B952/5F55DF41" Ref="#FLG?"  Part="1" 
AR Path="/5E53BC83/5F55DF41" Ref="#FLG0101"  Part="1" 
F 0 "#FLG0101" H 3750 6525 50  0001 C CNN
F 1 "PWR_FLAG" H 3750 6600 50  0000 C CNN
F 2 "" H 3750 6450 50  0001 C CNN
F 3 "~" H 3750 6450 50  0001 C CNN
	1    3750 6450
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG?
U 1 1 5F55DF47
P 3750 6750
AR Path="/5E53B952/5F55DF47" Ref="#FLG?"  Part="1" 
AR Path="/5E53BC83/5F55DF47" Ref="#FLG0102"  Part="1" 
F 0 "#FLG0102" H 3750 6825 50  0001 C CNN
F 1 "PWR_FLAG" H 3750 6900 50  0000 C CNN
F 2 "" H 3750 6750 50  0001 C CNN
F 3 "~" H 3750 6750 50  0001 C CNN
	1    3750 6750
	-1   0    0    1   
$EndComp
$Comp
L power:VCC #PWR?
U 1 1 5F55DF4D
P 3250 6450
AR Path="/5E53B952/5F55DF4D" Ref="#PWR?"  Part="1" 
AR Path="/5E53BC83/5F55DF4D" Ref="#PWR0127"  Part="1" 
F 0 "#PWR0127" H 3250 6300 50  0001 C CNN
F 1 "VCC" H 3250 6600 50  0000 C CNN
F 2 "" H 3250 6450 50  0001 C CNN
F 3 "" H 3250 6450 50  0001 C CNN
	1    3250 6450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 5F55DF53
P 3250 6750
AR Path="/5E53B952/5F55DF53" Ref="#PWR?"  Part="1" 
AR Path="/5E53BC83/5F55DF53" Ref="#PWR0128"  Part="1" 
F 0 "#PWR0128" H 3250 6500 50  0001 C CNN
F 1 "GND" H 3250 6600 50  0000 C CNN
F 2 "" H 3250 6750 50  0001 C CNN
F 3 "" H 3250 6750 50  0001 C CNN
	1    3250 6750
	1    0    0    -1  
$EndComp
Wire Wire Line
	11050 4300 10500 4300
Wire Wire Line
	10500 4400 11050 4400
Wire Wire Line
	11050 4500 10500 4500
Wire Wire Line
	11050 4600 10500 4600
Wire Wire Line
	11050 4700 10500 4700
Wire Wire Line
	11050 4800 10500 4800
Wire Wire Line
	11050 4900 10500 4900
Wire Wire Line
	11050 5000 10500 5000
Wire Wire Line
	11050 5100 10500 5100
Wire Wire Line
	11050 5200 10500 5200
Wire Wire Line
	11050 5300 10500 5300
Wire Wire Line
	11050 5400 10500 5400
Wire Wire Line
	10500 5500 11050 5500
Wire Wire Line
	10500 5600 11050 5600
Wire Wire Line
	11050 5700 9900 5700
Wire Wire Line
	9800 5800 11050 5800
Wire Wire Line
	9650 2500 10000 2500
Wire Wire Line
	9650 2600 10000 2600
Wire Wire Line
	10000 2700 9650 2700
Wire Wire Line
	9650 2800 10000 2800
Wire Wire Line
	10000 2900 9650 2900
Wire Wire Line
	9650 3000 10000 3000
Wire Wire Line
	10000 3100 9650 3100
Wire Wire Line
	9650 3200 10000 3200
Wire Wire Line
	10000 3300 9650 3300
Wire Wire Line
	9650 3400 10000 3400
Wire Wire Line
	10000 3500 9650 3500
Wire Wire Line
	9650 3600 10000 3600
Wire Wire Line
	10000 3700 9650 3700
Wire Wire Line
	9650 3800 10000 3800
Wire Wire Line
	10000 3900 9650 3900
Wire Wire Line
	9650 4000 10000 4000
Wire Wire Line
	10000 4100 9650 4100
Wire Wire Line
	9650 4200 10000 4200
Wire Wire Line
	10000 4300 9650 4300
Wire Wire Line
	9650 4400 10000 4400
Wire Wire Line
	10000 4500 9650 4500
Wire Wire Line
	9650 4600 10000 4600
Wire Wire Line
	10000 4700 9650 4700
Wire Wire Line
	10500 2800 11100 2800
Wire Wire Line
	11100 2150 11100 1900
Wire Wire Line
	11100 1900 11050 1900
Connection ~ 11050 1900
Wire Wire Line
	11050 1900 11000 1900
Wire Wire Line
	11100 2450 11100 2800
Connection ~ 11100 2800
Wire Wire Line
	11100 2800 11300 2800
Wire Wire Line
	10500 2700 11700 2700
Wire Wire Line
	11700 2700 11700 5550
$Comp
L rosco_m68k-eagle-import:MC68901P IC?
U 2 1 5F6756DF
P 5100 8800
AR Path="/5F6756DF" Ref="IC?"  Part="2" 
AR Path="/5E53B630/5F6756DF" Ref="IC?"  Part="2" 
AR Path="/5E53B4B8/5F6756DF" Ref="IC?"  Part="2" 
AR Path="/5E53BC83/5F6756DF" Ref="IC4"  Part="2" 
F 0 "IC4" H 5050 8775 59  0000 L BNN
F 1 "MC68901P" H 4600 7100 59  0001 L BNN
F 2 "rosco_m68k:DIL48" H 5100 8800 50  0001 C CNN
F 3 "" H 5100 8800 50  0001 C CNN
	2    5100 8800
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6756E5
P 4600 8700
AR Path="/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53B630/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6756E5" Ref="C23"  Part="1" 
F 0 "C23" H 4660 8715 59  0000 L BNN
F 1 "100nF" H 4660 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 4600 8700 50  0001 C CNN
F 3 "" H 4600 8700 50  0001 C CNN
	1    4600 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6756EB
P 5450 8700
AR Path="/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53B630/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6756EB" Ref="C24"  Part="1" 
F 0 "C24" H 5510 8715 59  0000 L BNN
F 1 "100nF" H 5510 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 5450 8700 50  0001 C CNN
F 3 "" H 5450 8700 50  0001 C CNN
	1    5450 8700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3300 8200 3300 8600
Wire Wire Line
	3850 8200 3750 8200
Wire Wire Line
	3750 8400 3750 8200
Wire Wire Line
	3850 8400 3850 8200
Wire Wire Line
	3300 8900 3300 9300
Wire Wire Line
	3750 9300 3850 9300
Wire Wire Line
	3750 9000 3750 9300
Wire Wire Line
	3850 9000 3850 9300
$Comp
L rosco_m68k-eagle-import:MC68000P IC?
U 2 1 5F699F4A
P 3750 8700
AR Path="/5F699F4A" Ref="IC?"  Part="2" 
AR Path="/5E53B4B8/5F699F4A" Ref="IC?"  Part="2" 
AR Path="/5E53BC83/5F699F4A" Ref="IC1"  Part="2" 
F 0 "IC1" H 3725 8675 59  0000 L BNN
F 1 "MC68010P10" H 3250 6600 59  0001 L BNN
F 2 "rosco_m68k:DIL64" H 3750 8700 50  0001 C CNN
F 3 "" H 3750 8700 50  0001 C CNN
	2    3750 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F699F50
P 3300 8700
AR Path="/5F699F50" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F50" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F50" Ref="C20"  Part="1" 
F 0 "C20" H 3360 8715 59  0000 L BNN
F 1 "100nF" H 3360 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 3300 8700 50  0001 C CNN
F 3 "" H 3300 8700 50  0001 C CNN
	1    3300 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F699F56
P 4150 8700
AR Path="/5F699F56" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F56" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F56" Ref="C22"  Part="1" 
F 0 "C22" H 4210 8715 59  0000 L BNN
F 1 "100nF" H 4210 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 4150 8700 50  0001 C CNN
F 3 "" H 4150 8700 50  0001 C CNN
	1    4150 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F699F5C
P 1150 8700
AR Path="/5F699F5C" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F5C" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F5C" Ref="C14"  Part="1" 
F 0 "C14" H 1195 8719 59  0000 L BNN
F 1 "100uF" H 1195 8519 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 1150 8700 50  0001 C CNN
F 3 "" H 1150 8700 50  0001 C CNN
	1    1150 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F699F62
P 2850 8700
AR Path="/5F699F62" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F62" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F62" Ref="C18"  Part="1" 
F 0 "C18" H 2895 8719 59  0000 L BNN
F 1 "100uF" H 2895 8519 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 2850 8700 50  0001 C CNN
F 3 "" H 2850 8700 50  0001 C CNN
	1    2850 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7401N IC?
U 5 1 5F6CD650
P 7900 8800
AR Path="/5F6CD650" Ref="IC?"  Part="5" 
AR Path="/5E53B952/5F6CD650" Ref="IC?"  Part="5" 
AR Path="/5E53BC83/5F6CD650" Ref="IC9"  Part="5" 
F 0 "IC9" H 7875 8775 59  0000 L BNN
F 1 "74LS01N" H 8000 8600 59  0001 L BNN
F 2 "Package_DIP:DIP-14_W7.62mm_Socket_LongPads" H 7900 8800 50  0001 C CNN
F 3 "" H 7900 8800 50  0001 C CNN
	5    7900 8800
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6CD656
P 6700 8700
AR Path="/5F6CD656" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD656" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD656" Ref="C26"  Part="1" 
F 0 "C26" H 6760 8715 59  0000 L BNN
F 1 "100nF" H 6760 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 6700 8700 50  0001 C CNN
F 3 "" H 6700 8700 50  0001 C CNN
	1    6700 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:74174N IC?
U 2 1 5F6CD664
P 6350 8800
AR Path="/5F6CD664" Ref="IC?"  Part="2" 
AR Path="/5E53B810/5F6CD664" Ref="IC?"  Part="2" 
AR Path="/5E53B952/5F6CD664" Ref="IC?"  Part="2" 
AR Path="/5E53BC83/5F6CD664" Ref="IC6"  Part="2" 
F 0 "IC6" H 6325 8775 59  0000 L BNN
F 1 "74174N" H 6050 8200 59  0001 L BNN
F 2 "Package_DIP:DIP-16_W7.62mm_Socket_LongPads" H 6350 8800 50  0001 C CNN
F 3 "" H 6350 8800 50  0001 C CNN
	2    6350 8800
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6CD66A
P 5900 8700
AR Path="/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD66A" Ref="C25"  Part="1" 
F 0 "C25" H 5960 8715 59  0000 L BNN
F 1 "100nF" H 5960 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 5900 8700 50  0001 C CNN
F 3 "" H 5900 8700 50  0001 C CNN
	1    5900 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD670
P 1550 8700
AR Path="/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD670" Ref="C15"  Part="1" 
F 0 "C15" H 1595 8719 59  0000 L BNN
F 1 "100uF" H 1595 8519 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 1550 8700 50  0001 C CNN
F 3 "" H 1550 8700 50  0001 C CNN
	1    1550 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD676
P 2450 8700
AR Path="/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD676" Ref="C17"  Part="1" 
F 0 "C17" H 2495 8719 59  0000 L BNN
F 1 "100uF" H 2495 8519 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 2450 8700 50  0001 C CNN
F 3 "" H 2450 8700 50  0001 C CNN
	1    2450 8700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD67C
P 2000 8700
AR Path="/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD67C" Ref="C16"  Part="1" 
F 0 "C16" H 2045 8719 59  0000 L BNN
F 1 "100uF" H 2045 8519 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 2000 8700 50  0001 C CNN
F 3 "" H 2000 8700 50  0001 C CNN
	1    2000 8700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3750 8200 3300 8200
Wire Wire Line
	1150 8200 1150 8600
Connection ~ 3750 8200
Connection ~ 3300 8200
Wire Wire Line
	3300 8200 2850 8200
Wire Wire Line
	1150 8900 1150 9300
Connection ~ 3750 9300
Connection ~ 3300 9300
Wire Wire Line
	3300 9300 3750 9300
Wire Wire Line
	3850 9300 4150 9300
Wire Wire Line
	7900 9300 7900 9100
Connection ~ 3850 9300
Wire Wire Line
	7900 8500 7900 8200
Connection ~ 3850 8200
Wire Wire Line
	4150 8600 4150 8200
Connection ~ 4150 8200
Wire Wire Line
	4150 8200 3850 8200
Wire Wire Line
	4600 8600 4600 8200
Connection ~ 4600 8200
Wire Wire Line
	4600 8200 4150 8200
Wire Wire Line
	5100 8500 5100 8200
Connection ~ 5100 8200
Wire Wire Line
	5100 8200 4600 8200
Wire Wire Line
	5450 8600 5450 8200
Connection ~ 5450 8200
Wire Wire Line
	5450 8200 5100 8200
Wire Wire Line
	5900 8600 5900 8200
Connection ~ 5900 8200
Wire Wire Line
	5900 8200 5450 8200
Wire Wire Line
	6350 8500 6350 8200
Connection ~ 6350 8200
Wire Wire Line
	6350 8200 5900 8200
Wire Wire Line
	6700 8600 6700 8200
Wire Wire Line
	6700 8200 6350 8200
Wire Wire Line
	6700 8900 6700 9300
Wire Wire Line
	6350 9100 6350 9300
Connection ~ 6350 9300
Wire Wire Line
	6350 9300 6700 9300
Wire Wire Line
	5900 8900 5900 9300
Connection ~ 5900 9300
Wire Wire Line
	5900 9300 6350 9300
Wire Wire Line
	5450 8900 5450 9300
Connection ~ 5450 9300
Wire Wire Line
	5450 9300 5900 9300
Wire Wire Line
	5100 9100 5100 9300
Connection ~ 5100 9300
Wire Wire Line
	5100 9300 5450 9300
Wire Wire Line
	4600 8900 4600 9300
Connection ~ 4600 9300
Wire Wire Line
	4600 9300 5100 9300
Wire Wire Line
	4150 8900 4150 9300
Connection ~ 4150 9300
Wire Wire Line
	4150 9300 4600 9300
Wire Wire Line
	2850 8600 2850 8200
Connection ~ 2850 8200
Wire Wire Line
	2850 8200 2450 8200
Wire Wire Line
	2850 8900 2850 9300
Wire Wire Line
	1150 9300 1550 9300
Connection ~ 2850 9300
Wire Wire Line
	2850 9300 3300 9300
Wire Wire Line
	2450 8600 2450 8200
Connection ~ 2450 8200
Wire Wire Line
	2450 8200 2000 8200
Wire Wire Line
	2450 8900 2450 9300
Connection ~ 2450 9300
Wire Wire Line
	2450 9300 2850 9300
Wire Wire Line
	2000 8600 2000 8200
Connection ~ 2000 8200
Wire Wire Line
	2000 8200 1550 8200
Wire Wire Line
	2000 8900 2000 9300
Connection ~ 2000 9300
Wire Wire Line
	2000 9300 2450 9300
Wire Wire Line
	1550 8600 1550 8200
Connection ~ 1550 8200
Wire Wire Line
	1550 8200 1150 8200
Wire Wire Line
	1550 8900 1550 9300
Connection ~ 1550 9300
Wire Wire Line
	1550 9300 2000 9300
$Comp
L power:VCC #PWR0108
U 1 1 5F7D33E2
P 1150 7850
F 0 "#PWR0108" H 1150 7700 50  0001 C CNN
F 1 "VCC" H 1167 8023 50  0000 C CNN
F 2 "" H 1150 7850 50  0001 C CNN
F 3 "" H 1150 7850 50  0001 C CNN
	1    1150 7850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0109
U 1 1 5F7D403D
P 7900 9600
F 0 "#PWR0109" H 7900 9350 50  0001 C CNN
F 1 "GND" H 7905 9427 50  0000 C CNN
F 2 "" H 7900 9600 50  0001 C CNN
F 3 "" H 7900 9600 50  0001 C CNN
	1    7900 9600
	1    0    0    -1  
$EndComp
Wire Wire Line
	7900 9600 7900 9300
Connection ~ 7900 9300
Wire Wire Line
	1150 7850 1150 8200
Connection ~ 1150 8200
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F3EE222
P 7250 8700
AR Path="/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F3EE222" Ref="C27"  Part="1" 
F 0 "C27" H 7310 8715 59  0000 L BNN
F 1 "100nF" H 7310 8515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 7250 8700 50  0001 C CNN
F 3 "" H 7250 8700 50  0001 C CNN
	1    7250 8700
	1    0    0    -1  
$EndComp
Wire Wire Line
	7250 8600 7250 8200
Wire Wire Line
	6700 8200 7250 8200
Connection ~ 6700 8200
Wire Wire Line
	7250 8200 7900 8200
Connection ~ 7250 8200
Wire Wire Line
	7250 8900 7250 9300
Wire Wire Line
	7250 9300 7900 9300
Wire Wire Line
	7250 9300 6700 9300
Connection ~ 7250 9300
Connection ~ 6700 9300
Wire Bus Line
	11150 4100 11150 5700
Wire Bus Line
	9450 2150 9450 4500
$EndSCHEMATC
