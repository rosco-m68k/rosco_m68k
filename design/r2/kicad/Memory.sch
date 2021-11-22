EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 6 7
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-10-22"
Rev "2.1"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
Text GLabel 5300 1600 0    47   Input ~ 0
RW
Text GLabel 8700 1600 0    47   Input ~ 0
RW
Text GLabel 1800 3450 0    47   Input ~ 0
ODDROMSEL
Text GLabel 5300 1400 0    47   Input ~ 0
ODDRAMSEL
Text GLabel 8700 1400 0    47   Input ~ 0
EVENRAMSEL
Text Notes 2550 3500 0    59   ~ 0
ODD
Text Notes 6200 3900 0    59   ~ 0
ODD
Text Notes 2550 7250 0    59   ~ 0
EVEN
Text Notes 9600 3900 0    59   ~ 0
EVEN
$Comp
L power:VCC #PWR0103
U 1 1 5E971BE5
P 1000 850
F 0 "#PWR0103" H 1000 700 50  0001 C CNN
F 1 "VCC" H 1017 1023 50  0000 C CNN
F 2 "" H 1000 850 50  0001 C CNN
F 3 "" H 1000 850 50  0001 C CNN
	1    1000 850 
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C5
U 1 1 E602F468
P 1000 2200
AR Path="/E602F468" Ref="C5"  Part="1" 
AR Path="/5E53B4B8/E602F468" Ref="C3"  Part="1" 
AR Path="/616B7C9B/E602F468" Ref="C3"  Part="1" 
F 0 "C3" V 1160 2115 59  0000 L BNN
F 1 "100nF" V 900 2000 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 1000 2200 50  0001 C CNN
F 3 "" H 1000 2200 50  0001 C CNN
	1    1000 2200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0104
U 1 1 5ED1852C
P 1000 3750
F 0 "#PWR0104" H 1000 3500 50  0001 C CNN
F 1 "GND" H 1005 3577 50  0000 C CNN
F 2 "" H 1000 3750 50  0001 C CNN
F 3 "" H 1000 3750 50  0001 C CNN
	1    1000 3750
	1    0    0    -1  
$EndComp
Text GLabel 1800 7150 0    47   Input ~ 0
EVENROMSEL
$Comp
L rosco_m68k-eagle-import:AS6C4008-55PCN U3
U 1 1 5FE46869
P 6000 2400
F 0 "U3" H 6000 4008 69  0000 C CNN
F 1 "AS6C4008-55PCN" H 6000 3888 69  0000 C CNN
F 2 "Package_DIP:DIP-32_W15.24mm_LongPads" H 6000 2400 50  0001 C CNN
F 3 "" H 6000 2400 50  0001 C CNN
	1    6000 2400
	1    0    0    -1  
$EndComp
$Comp
L Memory_Flash:SST39SF040 U2
U 1 1 5ECF0092
P 2400 6150
F 0 "U2" H 2400 7558 69  0000 C CNN
F 1 "SST39SF040" H 2400 7438 69  0000 C CNN
F 2 "Package_DIP:DIP-32_W15.24mm_LongPads" H 2400 6150 50  0001 C CNN
F 3 "" H 2400 6150 50  0001 C CNN
	1    2400 6150
	1    0    0    -1  
$EndComp
$Comp
L Memory_Flash:SST39SF040 U1
U 1 1 5ECEE814
P 2400 2450
F 0 "U1" H 2400 3858 69  0000 C CNN
F 1 "SST39SF040" H 2400 3738 69  0000 C CNN
F 2 "Package_DIP:DIP-32_W15.24mm_LongPads" H 2400 2450 50  0001 C CNN
F 3 "" H 2400 2450 50  0001 C CNN
	1    2400 2450
	1    0    0    -1  
$EndComp
Text GLabel 3000 1250 2    50   BiDi ~ 0
D0
Text GLabel 3000 1350 2    50   BiDi ~ 0
D1
Text GLabel 3000 1450 2    50   BiDi ~ 0
D2
Text GLabel 3000 1550 2    50   BiDi ~ 0
D3
Text GLabel 3000 1650 2    50   BiDi ~ 0
D4
Text GLabel 3000 1750 2    50   BiDi ~ 0
D5
Text GLabel 3000 1850 2    50   BiDi ~ 0
D6
Text GLabel 3000 1950 2    50   BiDi ~ 0
D7
Text GLabel 1800 3250 0    50   Input ~ 0
ROM_RW
Text GLabel 1800 3550 0    50   Input ~ 0
WR
Text GLabel 1800 1250 0    50   Input ~ 0
A1
Text GLabel 1800 1350 0    50   Input ~ 0
A2
Text GLabel 1800 1450 0    50   Input ~ 0
A3
Text GLabel 1800 1550 0    50   Input ~ 0
A4
Text GLabel 1800 1650 0    50   Input ~ 0
A5
Text GLabel 1800 1750 0    50   Input ~ 0
A6
Text GLabel 1800 1850 0    50   Input ~ 0
A7
Text GLabel 1800 1950 0    50   Input ~ 0
A8
Text GLabel 1800 2050 0    50   Input ~ 0
A9
Text GLabel 1800 2150 0    50   Input ~ 0
A10
Text GLabel 1800 2250 0    50   Input ~ 0
A11
Text GLabel 1800 2350 0    50   Input ~ 0
A12
Text GLabel 1800 2450 0    50   Input ~ 0
A13
Text GLabel 1800 2550 0    50   Input ~ 0
A14
Text GLabel 1800 2650 0    50   Input ~ 0
A15
Text GLabel 1800 2750 0    50   Input ~ 0
A16
Text GLabel 1800 2850 0    50   Input ~ 0
A17
Text GLabel 1800 2950 0    50   Input ~ 0
A18
Text GLabel 1800 3050 0    50   Input ~ 0
A19
Wire Wire Line
	2400 1150 1000 1150
Wire Wire Line
	1000 1150 1000 850 
Wire Wire Line
	1000 1150 1000 2100
Connection ~ 1000 1150
Wire Wire Line
	2400 3650 1000 3650
Wire Wire Line
	1000 3650 1000 3750
Wire Wire Line
	1000 2400 1000 3650
Connection ~ 1000 3650
Text GLabel 1800 4950 0    50   Input ~ 0
A1
Text GLabel 1800 5050 0    50   Input ~ 0
A2
Text GLabel 1800 5150 0    50   Input ~ 0
A3
Text GLabel 1800 5250 0    50   Input ~ 0
A4
Text GLabel 1800 5350 0    50   Input ~ 0
A5
Text GLabel 1800 5450 0    50   Input ~ 0
A6
Text GLabel 1800 5550 0    50   Input ~ 0
A7
Text GLabel 1800 5650 0    50   Input ~ 0
A8
Text GLabel 1800 5750 0    50   Input ~ 0
A9
Text GLabel 1800 5850 0    50   Input ~ 0
A10
Text GLabel 1800 5950 0    50   Input ~ 0
A11
Text GLabel 1800 6050 0    50   Input ~ 0
A12
Text GLabel 1800 6150 0    50   Input ~ 0
A13
Text GLabel 1800 6250 0    50   Input ~ 0
A14
Text GLabel 1800 6350 0    50   Input ~ 0
A15
Text GLabel 1800 6450 0    50   Input ~ 0
A16
Text GLabel 1800 6550 0    50   Input ~ 0
A17
Text GLabel 1800 6650 0    50   Input ~ 0
A18
Text GLabel 1800 6750 0    50   Input ~ 0
A19
Text GLabel 1800 6950 0    50   Input ~ 0
ROM_RW
Text GLabel 1800 7250 0    50   Input ~ 0
WR
$Comp
L power:VCC #PWR0105
U 1 1 61798ECA
P 1000 4550
F 0 "#PWR0105" H 1000 4400 50  0001 C CNN
F 1 "VCC" H 1017 4723 50  0000 C CNN
F 2 "" H 1000 4550 50  0001 C CNN
F 3 "" H 1000 4550 50  0001 C CNN
	1    1000 4550
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 61798ED0
P 1000 5900
AR Path="/61798ED0" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/61798ED0" Ref="C?"  Part="1" 
AR Path="/616B7C9B/61798ED0" Ref="C4"  Part="1" 
F 0 "C4" V 1160 5815 59  0000 L BNN
F 1 "100nF" V 900 5700 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 1000 5900 50  0001 C CNN
F 3 "" H 1000 5900 50  0001 C CNN
	1    1000 5900
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0106
U 1 1 61798ED6
P 1000 7450
F 0 "#PWR0106" H 1000 7200 50  0001 C CNN
F 1 "GND" H 1005 7277 50  0000 C CNN
F 2 "" H 1000 7450 50  0001 C CNN
F 3 "" H 1000 7450 50  0001 C CNN
	1    1000 7450
	1    0    0    -1  
$EndComp
Wire Wire Line
	2400 4850 1000 4850
Wire Wire Line
	1000 4850 1000 4550
Wire Wire Line
	1000 4850 1000 5800
Connection ~ 1000 4850
Wire Wire Line
	2400 7350 1000 7350
Wire Wire Line
	1000 7350 1000 7450
Wire Wire Line
	1000 6100 1000 7350
Connection ~ 1000 7350
Text GLabel 3000 4950 2    50   BiDi ~ 0
D8
Text GLabel 3000 5050 2    50   BiDi ~ 0
D9
Text GLabel 3000 5150 2    50   BiDi ~ 0
D10
Text GLabel 3000 5250 2    50   BiDi ~ 0
D11
Text GLabel 3000 5350 2    50   BiDi ~ 0
D12
Text GLabel 3000 5450 2    50   BiDi ~ 0
D13
Text GLabel 3000 5550 2    50   BiDi ~ 0
D14
Text GLabel 3000 5650 2    50   BiDi ~ 0
D15
Text GLabel 5300 1800 0    50   Input ~ 0
A1
Text GLabel 5300 1900 0    50   Input ~ 0
A2
Text GLabel 5300 2000 0    50   Input ~ 0
A3
Text GLabel 5300 2100 0    50   Input ~ 0
A4
Text GLabel 5300 2200 0    50   Input ~ 0
A5
Text GLabel 5300 2300 0    50   Input ~ 0
A6
Text GLabel 5300 2400 0    50   Input ~ 0
A7
Text GLabel 5300 2500 0    50   Input ~ 0
A8
Text GLabel 5300 2600 0    50   Input ~ 0
A9
Text GLabel 5300 2700 0    50   Input ~ 0
A10
Text GLabel 5300 2800 0    50   Input ~ 0
A11
Text GLabel 5300 2900 0    50   Input ~ 0
A12
Text GLabel 5300 3000 0    50   Input ~ 0
A13
Text GLabel 5300 3100 0    50   Input ~ 0
A14
Text GLabel 5300 3200 0    50   Input ~ 0
A15
Text GLabel 5300 3300 0    50   Input ~ 0
A16
Text GLabel 5300 3400 0    50   Input ~ 0
A17
Text GLabel 5300 3500 0    50   Input ~ 0
A18
Text GLabel 5300 3600 0    50   Input ~ 0
A19
Text GLabel 6700 1200 2    50   BiDi ~ 0
D0
Text GLabel 6700 1300 2    50   BiDi ~ 0
D1
Text GLabel 6700 1400 2    50   BiDi ~ 0
D2
Text GLabel 6700 1500 2    50   BiDi ~ 0
D3
Text GLabel 6700 1600 2    50   BiDi ~ 0
D4
Text GLabel 6700 1700 2    50   BiDi ~ 0
D5
Text GLabel 6700 1800 2    50   BiDi ~ 0
D6
Text GLabel 6700 1900 2    50   BiDi ~ 0
D7
$Comp
L power:VCC #PWR0107
U 1 1 617B09B9
P 4550 900
F 0 "#PWR0107" H 4550 750 50  0001 C CNN
F 1 "VCC" H 4567 1073 50  0000 C CNN
F 2 "" H 4550 900 50  0001 C CNN
F 3 "" H 4550 900 50  0001 C CNN
	1    4550 900 
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 617B09BF
P 4550 2250
AR Path="/617B09BF" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/617B09BF" Ref="C?"  Part="1" 
AR Path="/616B7C9B/617B09BF" Ref="C5"  Part="1" 
F 0 "C5" V 4710 2165 59  0000 L BNN
F 1 "100nF" V 4450 2050 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 4550 2250 50  0001 C CNN
F 3 "" H 4550 2250 50  0001 C CNN
	1    4550 2250
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0110
U 1 1 617B09C5
P 4550 4050
F 0 "#PWR0110" H 4550 3800 50  0001 C CNN
F 1 "GND" H 4555 3877 50  0000 C CNN
F 2 "" H 4550 4050 50  0001 C CNN
F 3 "" H 4550 4050 50  0001 C CNN
	1    4550 4050
	1    0    0    -1  
$EndComp
Wire Wire Line
	4550 900  4550 1200
Wire Wire Line
	4550 2450 4550 3800
Wire Wire Line
	5300 3800 4550 3800
Connection ~ 4550 3800
Wire Wire Line
	4550 3800 4550 4050
Wire Wire Line
	5300 1200 4550 1200
Connection ~ 4550 1200
Wire Wire Line
	4550 1200 4550 2150
$Comp
L rosco_m68k-eagle-import:AS6C4008-55PCN U4
U 1 1 5FE4AB28
P 9400 2400
F 0 "U4" H 9400 4008 69  0000 C CNN
F 1 "AS6C4008-55PCN" H 9400 3888 69  0000 C CNN
F 2 "Package_DIP:DIP-32_W15.24mm_LongPads" H 9400 2400 50  0001 C CNN
F 3 "" H 9400 2400 50  0001 C CNN
	1    9400 2400
	1    0    0    -1  
$EndComp
Text GLabel 10100 1200 2    50   BiDi ~ 0
D8
Text GLabel 10100 1300 2    50   BiDi ~ 0
D9
Text GLabel 10100 1400 2    50   BiDi ~ 0
D10
Text GLabel 10100 1500 2    50   BiDi ~ 0
D11
Text GLabel 10100 1600 2    50   BiDi ~ 0
D12
Text GLabel 10100 1700 2    50   BiDi ~ 0
D13
Text GLabel 10100 1800 2    50   BiDi ~ 0
D14
Text GLabel 10100 1900 2    50   BiDi ~ 0
D15
Text GLabel 8700 1800 0    50   Input ~ 0
A1
Text GLabel 8700 1900 0    50   Input ~ 0
A2
Text GLabel 8700 2000 0    50   Input ~ 0
A3
Text GLabel 8700 2100 0    50   Input ~ 0
A4
Text GLabel 8700 2200 0    50   Input ~ 0
A5
Text GLabel 8700 2300 0    50   Input ~ 0
A6
Text GLabel 8700 2400 0    50   Input ~ 0
A7
Text GLabel 8700 2500 0    50   Input ~ 0
A8
Text GLabel 8700 2600 0    50   Input ~ 0
A9
Text GLabel 8700 2700 0    50   Input ~ 0
A10
Text GLabel 8700 2800 0    50   Input ~ 0
A11
Text GLabel 8700 2900 0    50   Input ~ 0
A12
Text GLabel 8700 3000 0    50   Input ~ 0
A13
Text GLabel 8700 3100 0    50   Input ~ 0
A14
Text GLabel 8700 3200 0    50   Input ~ 0
A15
Text GLabel 8700 3300 0    50   Input ~ 0
A16
Text GLabel 8700 3400 0    50   Input ~ 0
A17
Text GLabel 8700 3500 0    50   Input ~ 0
A18
Text GLabel 8700 3600 0    50   Input ~ 0
A19
$Comp
L power:VCC #PWR0111
U 1 1 617CC87F
P 7950 900
F 0 "#PWR0111" H 7950 750 50  0001 C CNN
F 1 "VCC" H 7967 1073 50  0000 C CNN
F 2 "" H 7950 900 50  0001 C CNN
F 3 "" H 7950 900 50  0001 C CNN
	1    7950 900 
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 617CC885
P 7950 2250
AR Path="/617CC885" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/617CC885" Ref="C?"  Part="1" 
AR Path="/616B7C9B/617CC885" Ref="C6"  Part="1" 
F 0 "C6" V 8110 2165 59  0000 L BNN
F 1 "100nF" V 7850 2050 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 7950 2250 50  0001 C CNN
F 3 "" H 7950 2250 50  0001 C CNN
	1    7950 2250
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0112
U 1 1 617CC88B
P 7950 4050
F 0 "#PWR0112" H 7950 3800 50  0001 C CNN
F 1 "GND" H 7955 3877 50  0000 C CNN
F 2 "" H 7950 4050 50  0001 C CNN
F 3 "" H 7950 4050 50  0001 C CNN
	1    7950 4050
	1    0    0    -1  
$EndComp
Wire Wire Line
	7950 900  7950 1200
Wire Wire Line
	7950 2450 7950 3800
Wire Wire Line
	8700 3800 7950 3800
Connection ~ 7950 3800
Wire Wire Line
	7950 3800 7950 4050
Wire Wire Line
	8700 1200 7950 1200
Connection ~ 7950 1200
Wire Wire Line
	7950 1200 7950 2150
Text GLabel 8700 1500 0    50   Input ~ 0
WR
Text GLabel 5300 1500 0    50   Input ~ 0
WR
$Comp
L Device:Jumper JP3
U 1 1 6162CC16
P 4800 5700
F 0 "JP3" H 4800 5964 50  0000 C CNN
F 1 "Jumper" H 4800 5873 50  0000 C CNN
F 2 "rosco_m68k:1X02" H 4800 5700 50  0001 C CNN
F 3 "~" H 4800 5700 50  0001 C CNN
	1    4800 5700
	1    0    0    -1  
$EndComp
Text GLabel 4200 5700 0    50   Input ~ 0
RW
Text GLabel 5750 5700 2    50   Output ~ 0
ROM_RW
Wire Wire Line
	4200 5700 4500 5700
Wire Wire Line
	5100 5700 5350 5700
$Comp
L Device:R R11
U 1 1 6162E070
P 5350 5100
F 0 "R11" H 5420 5146 50  0000 L CNN
F 1 "10K" H 5420 5055 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 5280 5100 50  0001 C CNN
F 3 "~" H 5350 5100 50  0001 C CNN
	1    5350 5100
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0114
U 1 1 6162EC39
P 5350 4750
F 0 "#PWR0114" H 5350 4600 50  0001 C CNN
F 1 "VCC" H 5367 4923 50  0000 C CNN
F 2 "" H 5350 4750 50  0001 C CNN
F 3 "" H 5350 4750 50  0001 C CNN
	1    5350 4750
	1    0    0    -1  
$EndComp
Wire Wire Line
	5350 4750 5350 4950
Wire Wire Line
	5350 5250 5350 5700
Connection ~ 5350 5700
Wire Wire Line
	5350 5700 5750 5700
$EndSCHEMATC
