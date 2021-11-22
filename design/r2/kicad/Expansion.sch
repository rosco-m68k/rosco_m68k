EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 7
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-10-22"
Rev "2.1"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
Text GLabel 8450 4000 0    47   Output ~ 0
AS
Text GLabel 8450 4100 0    47   Input ~ 0
BERR
Text GLabel 8450 4200 0    47   Output ~ 0
BG
Text GLabel 8450 4300 0    47   Input ~ 0
BGACK
Text GLabel 8450 4400 0    47   Input ~ 0
BR
Text GLabel 8450 4500 0    47   Input ~ 0
DTACK
Text GLabel 8450 4600 0    47   Output ~ 0
RW
Wire Wire Line
	8950 1700 9450 1700
Text GLabel 8950 1800 2    47   Output ~ 0
CLK
Text GLabel 8950 2400 2    47   Output ~ 0
IOSEL
Text GLabel 8950 2500 2    47   Output ~ 0
EXPSEL
Text GLabel 8950 2600 2    47   Output ~ 0
FC0
Text GLabel 8950 2700 2    47   Output ~ 0
FC1
Text GLabel 8950 2800 2    47   Output ~ 0
FC2
Text GLabel 8950 2900 2    47   Input ~ 0
IRQ5
Text GLabel 8950 3000 2    47   Input ~ 0
IRQ2
Text GLabel 8950 3100 2    47   Input ~ 0
IRQ6
Text GLabel 8950 3200 2    47   Output ~ 0
LDS
Text GLabel 8950 3300 2    47   Output ~ 0
UDS
Text GLabel 8950 3400 2    47   BiDi ~ 0
RESET
$Comp
L power:VCC #PWR0151
U 1 1 5FD5B222
P 9500 1100
F 0 "#PWR0151" H 9500 950 50  0001 C CNN
F 1 "VCC" H 9517 1273 50  0000 C CNN
F 2 "" H 9500 1100 50  0001 C CNN
F 3 "" H 9500 1100 50  0001 C CNN
	1    9500 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	9450 1100 9450 1700
$Comp
L power:GND #PWR0152
U 1 1 5FD5E976
P 10150 4750
F 0 "#PWR0152" H 10150 4500 50  0001 C CNN
F 1 "GND" H 10155 4577 50  0000 C CNN
F 2 "" H 10150 4750 50  0001 C CNN
F 3 "" H 10150 4750 50  0001 C CNN
	1    10150 4750
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB083A
P 1250 3100
AR Path="/5E53BCCF/5FDB083A" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB083A" Ref="H1"  Part="1" 
F 0 "H1" H 1250 3300 50  0000 C CNN
F 1 "MountingHole" H 1250 3225 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 1250 3100 50  0001 C CNN
F 3 "~" H 1250 3100 50  0001 C CNN
	1    1250 3100
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB0840
P 1250 3450
AR Path="/5E53BCCF/5FDB0840" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB0840" Ref="H2"  Part="1" 
F 0 "H2" H 1250 3650 50  0000 C CNN
F 1 "MountingHole" H 1250 3575 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 1250 3450 50  0001 C CNN
F 3 "~" H 1250 3450 50  0001 C CNN
	1    1250 3450
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB0846
P 1250 3800
AR Path="/5E53BCCF/5FDB0846" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB0846" Ref="H3"  Part="1" 
F 0 "H3" H 1250 4000 50  0000 C CNN
F 1 "MountingHole" H 1250 3925 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 1250 3800 50  0001 C CNN
F 3 "~" H 1250 3800 50  0001 C CNN
	1    1250 3800
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H?
U 1 1 5FDB084C
P 1250 4150
AR Path="/5E53BCCF/5FDB084C" Ref="H?"  Part="1" 
AR Path="/5E53BC83/5FDB084C" Ref="H4"  Part="1" 
F 0 "H4" H 1250 4350 50  0000 C CNN
F 1 "MountingHole" H 1250 4275 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 1250 4150 50  0001 C CNN
F 3 "~" H 1250 4150 50  0001 C CNN
	1    1250 4150
	1    0    0    -1  
$EndComp
Text GLabel 9750 2000 2    50   Input ~ 0
VPA
Text GLabel 8950 2200 2    50   Output ~ 0
VMA
Text GLabel 8950 2100 2    50   Output ~ 0
E
$Comp
L Device:R R19
U 1 1 600B8632
P 9550 1500
F 0 "R19" H 9620 1546 50  0000 L CNN
F 1 "10K" H 9620 1455 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 9480 1500 50  0001 C CNN
F 3 "~" H 9550 1500 50  0001 C CNN
	1    9550 1500
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x32_Odd_Even J3
U 1 1 5EE9DB9A
P 8650 3200
F 0 "J3" H 8700 4917 50  0000 C CNN
F 1 "Conn_02x32_Odd_Even" H 8700 4826 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x32_P2.54mm_Vertical" H 8650 3200 50  0001 C CNN
F 3 "~" H 8650 3200 50  0001 C CNN
	1    8650 3200
	1    0    0    -1  
$EndComp
Wire Wire Line
	3050 1600 2150 1600
Wire Wire Line
	2150 1600 2150 1700
Wire Wire Line
	2150 1700 1650 1700
Wire Wire Line
	1650 1700 1150 1700
Connection ~ 1650 1700
Connection ~ 1150 1700
Wire Wire Line
	3050 1500 2150 1500
Wire Wire Line
	2150 1500 2150 1400
Wire Wire Line
	2150 1400 1650 1400
Wire Wire Line
	1650 1400 1150 1400
Connection ~ 1650 1400
Connection ~ 1150 1400
$Comp
L rosco_m68k-eagle-import:PINHD-1X2 JP?
U 1 1 5F55DF2F
P 3150 1600
AR Path="/5F55DF2F" Ref="JP?"  Part="1" 
AR Path="/5E53B952/5F55DF2F" Ref="JP?"  Part="1" 
AR Path="/5E53BC83/5F55DF2F" Ref="J5"  Part="1" 
F 0 "J5" H 2900 1825 59  0000 L BNN
F 1 "PWR" H 2900 1400 59  0000 L BNN
F 2 "rosco_m68k:1X02" H 3150 1600 50  0001 C CNN
F 3 "" H 3150 1600 50  0001 C CNN
F 4 "+5V" H 3250 1700 59  0001 L BNN "1"
F 5 "GND" H 3250 1600 59  0001 L BNN "2"
	1    3150 1600
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE3.5-10 C?
U 1 1 5F55DF35
P 1650 1500
AR Path="/5F55DF35" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F55DF35" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F55DF35" Ref="C21"  Part="1" 
F 0 "C21" H 1695 1519 59  0000 L BNN
F 1 "470uF" H 1695 1319 59  0000 L BNN
F 2 "rosco_m68k:E3,5-10" H 1650 1500 50  0001 C CNN
F 3 "" H 1650 1500 50  0001 C CNN
	1    1650 1500
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F55DF3B
P 1150 1500
AR Path="/5F55DF3B" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F55DF3B" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F55DF3B" Ref="C19"  Part="1" 
F 0 "C19" H 1195 1519 59  0000 L BNN
F 1 "100uF" H 1195 1319 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 1150 1500 50  0001 C CNN
F 3 "" H 1150 1500 50  0001 C CNN
	1    1150 1500
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG?
U 1 1 5F55DF41
P 1650 1400
AR Path="/5E53B952/5F55DF41" Ref="#FLG?"  Part="1" 
AR Path="/5E53BC83/5F55DF41" Ref="#FLG0101"  Part="1" 
F 0 "#FLG0101" H 1650 1475 50  0001 C CNN
F 1 "PWR_FLAG" H 1650 1550 50  0000 C CNN
F 2 "" H 1650 1400 50  0001 C CNN
F 3 "~" H 1650 1400 50  0001 C CNN
	1    1650 1400
	1    0    0    -1  
$EndComp
$Comp
L power:PWR_FLAG #FLG?
U 1 1 5F55DF47
P 1650 1700
AR Path="/5E53B952/5F55DF47" Ref="#FLG?"  Part="1" 
AR Path="/5E53BC83/5F55DF47" Ref="#FLG0102"  Part="1" 
F 0 "#FLG0102" H 1650 1775 50  0001 C CNN
F 1 "PWR_FLAG" H 1650 1850 50  0000 C CNN
F 2 "" H 1650 1700 50  0001 C CNN
F 3 "~" H 1650 1700 50  0001 C CNN
	1    1650 1700
	-1   0    0    1   
$EndComp
$Comp
L power:VCC #PWR?
U 1 1 5F55DF4D
P 1150 1400
AR Path="/5E53B952/5F55DF4D" Ref="#PWR?"  Part="1" 
AR Path="/5E53BC83/5F55DF4D" Ref="#PWR0127"  Part="1" 
F 0 "#PWR0127" H 1150 1250 50  0001 C CNN
F 1 "VCC" H 1150 1550 50  0000 C CNN
F 2 "" H 1150 1400 50  0001 C CNN
F 3 "" H 1150 1400 50  0001 C CNN
	1    1150 1400
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 5F55DF53
P 1150 1700
AR Path="/5E53B952/5F55DF53" Ref="#PWR?"  Part="1" 
AR Path="/5E53BC83/5F55DF53" Ref="#PWR0128"  Part="1" 
F 0 "#PWR0128" H 1150 1450 50  0001 C CNN
F 1 "GND" H 1150 1550 50  0000 C CNN
F 2 "" H 1150 1700 50  0001 C CNN
F 3 "" H 1150 1700 50  0001 C CNN
	1    1150 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	8950 2000 9550 2000
Wire Wire Line
	9550 1350 9550 1100
Wire Wire Line
	9550 1100 9500 1100
Connection ~ 9500 1100
Wire Wire Line
	9500 1100 9450 1100
Wire Wire Line
	9550 1650 9550 2000
Connection ~ 9550 2000
Wire Wire Line
	9550 2000 9750 2000
Wire Wire Line
	8950 1900 10150 1900
Wire Wire Line
	10150 1900 10150 4750
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6756E5
P 4200 5150
AR Path="/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53B630/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F6756E5" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6756E5" Ref="C23"  Part="1" 
F 0 "C23" H 4260 5165 59  0000 L BNN
F 1 "100nF" H 4260 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 4200 5150 50  0001 C CNN
F 3 "" H 4200 5150 50  0001 C CNN
	1    4200 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6756EB
P 5050 5150
AR Path="/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53B630/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F6756EB" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6756EB" Ref="C24"  Part="1" 
F 0 "C24" H 5110 5165 59  0000 L BNN
F 1 "100nF" H 5110 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 5050 5150 50  0001 C CNN
F 3 "" H 5050 5150 50  0001 C CNN
	1    5050 5150
	1    0    0    -1  
$EndComp
Wire Wire Line
	2900 4650 2900 5050
Wire Wire Line
	3450 4650 3350 4650
Wire Wire Line
	3350 4850 3350 4650
Wire Wire Line
	3450 4850 3450 4650
Wire Wire Line
	2900 5350 2900 5750
Wire Wire Line
	3350 5750 3450 5750
Wire Wire Line
	3350 5450 3350 5750
Wire Wire Line
	3450 5450 3450 5750
$Comp
L rosco_m68k-eagle-import:MC68000P IC?
U 2 1 5F699F4A
P 3350 5150
AR Path="/5F699F4A" Ref="IC?"  Part="2" 
AR Path="/5E53B4B8/5F699F4A" Ref="IC?"  Part="2" 
AR Path="/5E53BC83/5F699F4A" Ref="IC1"  Part="2" 
F 0 "IC1" H 3325 5125 59  0000 L BNN
F 1 "MC68010P10" H 2850 3050 59  0001 L BNN
F 2 "rosco_m68k:DIL64" H 3350 5150 50  0001 C CNN
F 3 "" H 3350 5150 50  0001 C CNN
	2    3350 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F699F50
P 2900 5150
AR Path="/5F699F50" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F50" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F50" Ref="C20"  Part="1" 
F 0 "C20" H 2960 5165 59  0000 L BNN
F 1 "100nF" H 2960 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 2900 5150 50  0001 C CNN
F 3 "" H 2900 5150 50  0001 C CNN
	1    2900 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F699F56
P 3750 5150
AR Path="/5F699F56" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F56" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F56" Ref="C22"  Part="1" 
F 0 "C22" H 3810 5165 59  0000 L BNN
F 1 "100nF" H 3810 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 3750 5150 50  0001 C CNN
F 3 "" H 3750 5150 50  0001 C CNN
	1    3750 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F699F5C
P 750 5150
AR Path="/5F699F5C" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F5C" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F5C" Ref="C14"  Part="1" 
F 0 "C14" H 795 5169 59  0000 L BNN
F 1 "100uF" H 795 4969 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 750 5150 50  0001 C CNN
F 3 "" H 750 5150 50  0001 C CNN
	1    750  5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F699F62
P 2450 5150
AR Path="/5F699F62" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/5F699F62" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F699F62" Ref="C18"  Part="1" 
F 0 "C18" H 2495 5169 59  0000 L BNN
F 1 "100uF" H 2495 4969 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 2450 5150 50  0001 C CNN
F 3 "" H 2450 5150 50  0001 C CNN
	1    2450 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6CD656
P 6300 5150
AR Path="/5F6CD656" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD656" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD656" Ref="C26"  Part="1" 
F 0 "C26" H 6360 5165 59  0000 L BNN
F 1 "100nF" H 6360 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 6300 5150 50  0001 C CNN
F 3 "" H 6300 5150 50  0001 C CNN
	1    6300 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F6CD66A
P 5500 5150
AR Path="/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD66A" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD66A" Ref="C25"  Part="1" 
F 0 "C25" H 5560 5165 59  0000 L BNN
F 1 "100nF" H 5560 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 5500 5150 50  0001 C CNN
F 3 "" H 5500 5150 50  0001 C CNN
	1    5500 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD670
P 1150 5150
AR Path="/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD670" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD670" Ref="C15"  Part="1" 
F 0 "C15" H 1195 5169 59  0000 L BNN
F 1 "100uF" H 1195 4969 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 1150 5150 50  0001 C CNN
F 3 "" H 1150 5150 50  0001 C CNN
	1    1150 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD676
P 2050 5150
AR Path="/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD676" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD676" Ref="C17"  Part="1" 
F 0 "C17" H 2095 5169 59  0000 L BNN
F 1 "100uF" H 2095 4969 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 2050 5150 50  0001 C CNN
F 3 "" H 2050 5150 50  0001 C CNN
	1    2050 5150
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:CPOL-EUE2.5-5 C?
U 1 1 5F6CD67C
P 1600 5150
AR Path="/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F6CD67C" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F6CD67C" Ref="C16"  Part="1" 
F 0 "C16" H 1645 5169 59  0000 L BNN
F 1 "100uF" H 1645 4969 59  0000 L BNN
F 2 "rosco_m68k:E2,5-5" H 1600 5150 50  0001 C CNN
F 3 "" H 1600 5150 50  0001 C CNN
	1    1600 5150
	1    0    0    -1  
$EndComp
Wire Wire Line
	3350 4650 2900 4650
Wire Wire Line
	750  4650 750  5050
Connection ~ 3350 4650
Connection ~ 2900 4650
Wire Wire Line
	2900 4650 2450 4650
Wire Wire Line
	750  5350 750  5750
Connection ~ 3350 5750
Connection ~ 2900 5750
Wire Wire Line
	2900 5750 3350 5750
Wire Wire Line
	3450 5750 3750 5750
Connection ~ 3450 5750
Connection ~ 3450 4650
Wire Wire Line
	3750 5050 3750 4650
Connection ~ 3750 4650
Wire Wire Line
	3750 4650 3450 4650
Wire Wire Line
	4200 5050 4200 4650
Connection ~ 4200 4650
Wire Wire Line
	4200 4650 3750 4650
Wire Wire Line
	5050 5050 5050 4650
Connection ~ 5050 4650
Wire Wire Line
	5500 5050 5500 4650
Connection ~ 5500 4650
Wire Wire Line
	5500 4650 5050 4650
Wire Wire Line
	6300 5050 6300 4650
Wire Wire Line
	6300 5350 6300 5750
Wire Wire Line
	5500 5350 5500 5750
Connection ~ 5500 5750
Wire Wire Line
	5050 5350 5050 5750
Connection ~ 5050 5750
Wire Wire Line
	5050 5750 5500 5750
Wire Wire Line
	4200 5350 4200 5750
Connection ~ 4200 5750
Wire Wire Line
	3750 5350 3750 5750
Connection ~ 3750 5750
Wire Wire Line
	3750 5750 4200 5750
Wire Wire Line
	2450 5050 2450 4650
Connection ~ 2450 4650
Wire Wire Line
	2450 4650 2050 4650
Wire Wire Line
	2450 5350 2450 5750
Wire Wire Line
	750  5750 1150 5750
Connection ~ 2450 5750
Wire Wire Line
	2450 5750 2900 5750
Wire Wire Line
	2050 5050 2050 4650
Connection ~ 2050 4650
Wire Wire Line
	2050 4650 1600 4650
Wire Wire Line
	2050 5350 2050 5750
Connection ~ 2050 5750
Wire Wire Line
	2050 5750 2450 5750
Wire Wire Line
	1600 5050 1600 4650
Connection ~ 1600 4650
Wire Wire Line
	1600 4650 1150 4650
Wire Wire Line
	1600 5350 1600 5750
Connection ~ 1600 5750
Wire Wire Line
	1600 5750 2050 5750
Wire Wire Line
	1150 5050 1150 4650
Connection ~ 1150 4650
Wire Wire Line
	1150 4650 750  4650
Wire Wire Line
	1150 5350 1150 5750
Connection ~ 1150 5750
Wire Wire Line
	1150 5750 1600 5750
$Comp
L power:VCC #PWR0108
U 1 1 5F7D33E2
P 750 4300
F 0 "#PWR0108" H 750 4150 50  0001 C CNN
F 1 "VCC" H 767 4473 50  0000 C CNN
F 2 "" H 750 4300 50  0001 C CNN
F 3 "" H 750 4300 50  0001 C CNN
	1    750  4300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0109
U 1 1 5F7D403D
P 6850 6050
F 0 "#PWR0109" H 6850 5800 50  0001 C CNN
F 1 "GND" H 6855 5877 50  0000 C CNN
F 2 "" H 6850 6050 50  0001 C CNN
F 3 "" H 6850 6050 50  0001 C CNN
	1    6850 6050
	1    0    0    -1  
$EndComp
Wire Wire Line
	6850 6050 6850 5750
Wire Wire Line
	750  4300 750  4650
Connection ~ 750  4650
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 5F3EE222
P 6850 5150
AR Path="/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53B810/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53B952/5F3EE222" Ref="C?"  Part="1" 
AR Path="/5E53BC83/5F3EE222" Ref="C27"  Part="1" 
F 0 "C27" H 6910 5165 59  0000 L BNN
F 1 "100nF" H 6910 4965 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 6850 5150 50  0001 C CNN
F 3 "" H 6850 5150 50  0001 C CNN
	1    6850 5150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6850 5050 6850 4650
Wire Wire Line
	6300 4650 6850 4650
Connection ~ 6300 4650
Wire Wire Line
	6850 5350 6850 5750
Wire Wire Line
	6850 5750 6300 5750
Connection ~ 6850 5750
Connection ~ 6300 5750
Text GLabel 8450 1700 0    50   Input ~ 0
A1
Text GLabel 8450 1800 0    50   Input ~ 0
A2
Text GLabel 8450 1900 0    50   Input ~ 0
A3
Text GLabel 8450 2000 0    50   Input ~ 0
A4
Text GLabel 8450 2100 0    50   Input ~ 0
A5
Text GLabel 8450 2200 0    50   Input ~ 0
A6
Text GLabel 8450 2300 0    50   Input ~ 0
A7
Text GLabel 8450 2400 0    50   Input ~ 0
A8
Text GLabel 8450 2500 0    50   Input ~ 0
A9
Text GLabel 8450 2600 0    50   Input ~ 0
A10
Text GLabel 8450 2700 0    50   Input ~ 0
A11
Text GLabel 8450 2800 0    50   Input ~ 0
A12
Text GLabel 8450 2900 0    50   Input ~ 0
A13
Text GLabel 8450 3000 0    50   Input ~ 0
A14
Text GLabel 8450 3100 0    50   Input ~ 0
A15
Text GLabel 8450 3200 0    50   Input ~ 0
A16
Text GLabel 8450 3300 0    50   Input ~ 0
A17
Text GLabel 8450 3400 0    50   Input ~ 0
A18
Text GLabel 8450 3500 0    50   Input ~ 0
A19
Text GLabel 8450 3600 0    50   Input ~ 0
A20
Text GLabel 8450 3700 0    50   Input ~ 0
A21
Text GLabel 8450 3800 0    50   Input ~ 0
A22
Text GLabel 8450 3900 0    50   Input ~ 0
A23
Text GLabel 8450 4700 0    50   BiDi ~ 0
D0
Text GLabel 8450 4800 0    50   BiDi ~ 0
D1
Text GLabel 8950 4800 2    50   BiDi ~ 0
D2
Text GLabel 8950 4700 2    50   BiDi ~ 0
D3
Text GLabel 8950 4600 2    50   BiDi ~ 0
D4
Text GLabel 8950 4500 2    50   BiDi ~ 0
D5
Text GLabel 8950 4400 2    50   BiDi ~ 0
D6
Text GLabel 8950 4300 2    50   BiDi ~ 0
D7
Text GLabel 8950 4200 2    50   BiDi ~ 0
D8
Text GLabel 8950 4100 2    50   BiDi ~ 0
D9
Text GLabel 8950 4000 2    50   BiDi ~ 0
D10
Text GLabel 8950 3900 2    50   BiDi ~ 0
D11
Text GLabel 8950 3800 2    50   BiDi ~ 0
D12
Text GLabel 8950 3700 2    50   BiDi ~ 0
D13
Text GLabel 8950 3600 2    50   BiDi ~ 0
D14
Text GLabel 8950 3500 2    50   BiDi ~ 0
D15
Wire Wire Line
	4200 4650 5050 4650
Wire Wire Line
	4200 5750 5050 5750
Wire Wire Line
	5500 4650 6300 4650
Wire Wire Line
	5500 5750 6300 5750
$Comp
L Connector:Conn_01x04_Male J6
U 1 1 61646A1A
P 1700 2450
F 0 "J6" H 1808 2731 50  0000 C CNN
F 1 "Conn_01x04_Male" H 1808 2640 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 1700 2450 50  0001 C CNN
F 3 "~" H 1700 2450 50  0001 C CNN
	1    1700 2450
	1    0    0    -1  
$EndComp
Text GLabel 1900 2350 2    50   Input ~ 0
A20
Text GLabel 1900 2450 2    50   Input ~ 0
A21
Text GLabel 1900 2550 2    50   Input ~ 0
A22
Text GLabel 1900 2650 2    50   Input ~ 0
A23
$Comp
L 74xx:74LS148 IC7
U 1 1 6173FF25
P 6350 2700
F 0 "IC7" H 6350 3581 50  0000 C CNN
F 1 "74LS148" H 6350 3490 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_LongPads" H 6350 2700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS148" H 6350 2700 50  0001 C CNN
	1    6350 2700
	1    0    0    -1  
$EndComp
Text GLabel 8950 2300 2    50   Input ~ 0
IRQ3
Text GLabel 5850 2300 0    50   Input ~ 0
GND
Text GLabel 5850 3100 0    50   Input ~ 0
GND
Text GLabel 6850 2300 2    50   Output ~ 0
IPL0
Text GLabel 6850 2400 2    50   Output ~ 0
IPL1
Text GLabel 6850 2500 2    50   Output ~ 0
IPL2
Wire Wire Line
	4100 1800 4100 2000
$Comp
L power:VCC #PWR07
U 1 1 617498B7
P 4100 1800
F 0 "#PWR07" H 4100 1650 50  0001 C CNN
F 1 "VCC" H 4117 1973 50  0000 C CNN
F 2 "" H 4100 1800 50  0001 C CNN
F 3 "" H 4100 1800 50  0001 C CNN
	1    4100 1800
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR08
U 1 1 6174A780
P 6350 3500
F 0 "#PWR08" H 6350 3250 50  0001 C CNN
F 1 "GND" H 6355 3327 50  0000 C CNN
F 2 "" H 6350 3500 50  0001 C CNN
F 3 "" H 6350 3500 50  0001 C CNN
	1    6350 3500
	1    0    0    -1  
$EndComp
Wire Wire Line
	6350 3400 6350 3500
NoConn ~ 6850 2800
NoConn ~ 6850 2900
Text GLabel 3950 2500 0    50   Input ~ 0
IRQ2
$Comp
L Device:R R17
U 1 1 6175BA3C
P 5000 2250
F 0 "R17" H 5070 2296 50  0000 L CNN
F 1 "4K7" H 5070 2205 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 4930 2250 50  0001 C CNN
F 3 "~" H 5000 2250 50  0001 C CNN
	1    5000 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R12
U 1 1 6175C33F
P 5300 2250
F 0 "R12" H 5370 2296 50  0000 L CNN
F 1 "4K7" H 5370 2205 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 5230 2250 50  0001 C CNN
F 3 "~" H 5300 2250 50  0001 C CNN
	1    5300 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R16
U 1 1 6175E1D4
P 4700 2250
F 0 "R16" H 4770 2296 50  0000 L CNN
F 1 "4K7" H 4770 2205 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 4630 2250 50  0001 C CNN
F 3 "~" H 4700 2250 50  0001 C CNN
	1    4700 2250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R18
U 1 1 6175FFEB
P 4400 2250
F 0 "R18" H 4470 2296 50  0000 L CNN
F 1 "4K7" H 4470 2205 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 4330 2250 50  0001 C CNN
F 3 "~" H 4400 2250 50  0001 C CNN
	1    4400 2250
	1    0    0    -1  
$EndComp
Text GLabel 3950 2600 0    50   Input ~ 0
IRQ3
Text GLabel 3950 2800 0    50   Input ~ 0
IRQ5
Text GLabel 3950 2900 0    50   Input ~ 0
IRQ6
Text GLabel 3950 2700 0    50   Input ~ 0
DUAIRQ
Wire Wire Line
	4400 2000 4400 2100
Wire Wire Line
	4700 2100 4700 2000
Connection ~ 4700 2000
Wire Wire Line
	4700 2000 4400 2000
Wire Wire Line
	5000 2100 5000 2000
Connection ~ 5000 2000
Wire Wire Line
	5000 2000 4700 2000
Wire Wire Line
	5300 2100 5300 2000
Wire Wire Line
	5300 2000 5000 2000
$Comp
L Device:R R15
U 1 1 61797C20
P 4100 2250
F 0 "R15" H 4170 2296 50  0000 L CNN
F 1 "4K7" H 4170 2205 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 4030 2250 50  0001 C CNN
F 3 "~" H 4100 2250 50  0001 C CNN
	1    4100 2250
	1    0    0    -1  
$EndComp
Wire Wire Line
	4100 2000 4100 2100
Wire Wire Line
	4100 2000 4400 2000
Connection ~ 4400 2000
Wire Wire Line
	3950 2500 4100 2500
Wire Wire Line
	3950 2600 4400 2600
Wire Wire Line
	3950 2700 4700 2700
Wire Wire Line
	3950 2800 5000 2800
Wire Wire Line
	3950 2900 5300 2900
Wire Wire Line
	4100 2400 4100 2500
Wire Wire Line
	4400 2400 4400 2600
Wire Wire Line
	4700 2400 4700 2700
Wire Wire Line
	5000 2400 5000 2800
Wire Wire Line
	5300 2400 5300 2900
Text GLabel 5850 2400 0    50   Input ~ 0
VCC
Text GLabel 5850 3000 0    50   Input ~ 0
VCC
Connection ~ 4100 2000
Wire Wire Line
	5850 2500 4100 2500
Connection ~ 4100 2500
Wire Wire Line
	4400 2600 5850 2600
Connection ~ 4400 2600
Wire Wire Line
	5850 2700 4700 2700
Connection ~ 4700 2700
Wire Wire Line
	5000 2800 5850 2800
Connection ~ 5000 2800
Wire Wire Line
	5850 2900 5300 2900
Connection ~ 5300 2900
Wire Wire Line
	5300 2000 6350 2000
Connection ~ 5300 2000
$EndSCHEMATC
