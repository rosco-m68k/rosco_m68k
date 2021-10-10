EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 5 7
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-10-08"
Rev "2.0"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
Text GLabel 3750 3550 0    47   Input ~ 0
IPL2
Text GLabel 3750 3450 0    47   Input ~ 0
IPL1
Text GLabel 3750 3350 0    47   Input ~ 0
IPL0
Text GLabel 3750 3150 0    47   Input ~ 0
DTACK
Text GLabel 3750 2950 0    47   Output ~ 0
BGACK
Text GLabel 3750 2850 0    47   Input ~ 0
BR
Text GLabel 3750 2350 0    47   BiDi ~ 0
RESET
Text GLabel 3750 2250 0    47   Output ~ 0
BERR
Text GLabel 3750 2050 0    47   Input ~ 0
CLK
Text GLabel 5050 3350 2    47   Output ~ 0
LDS
Text GLabel 5050 3250 2    47   Output ~ 0
UDS
Text GLabel 5050 3150 2    47   Output ~ 0
RW
Text GLabel 5050 3050 2    47   Output ~ 0
AS
Text GLabel 5050 2850 2    47   Output ~ 0
BG
Text GLabel 5050 2250 2    47   Output ~ 0
FC2
Text GLabel 5050 2150 2    47   Output ~ 0
FC1
Text GLabel 5050 2050 2    47   Output ~ 0
FC0
Text GLabel 3750 2450 0    47   BiDi ~ 0
HALT
$Comp
L rosco_m68k-eagle-import:MC68000P IC1
U 1 1 8B1E8DB7
P 4450 3850
AR Path="/8B1E8DB7" Ref="IC1"  Part="1" 
AR Path="/5E53B4B8/8B1E8DB7" Ref="IC1"  Part="1" 
F 0 "IC1" H 3950 5775 59  0000 L BNN
F 1 "MC68010P10" H 3950 1750 59  0001 L BNN
F 2 "rosco_m68k:DIL64" H 4450 3850 50  0001 C CNN
F 3 "https://github.com/rosco-m68k/hardware-projects/blob/master/datasheets/MC68000UM.pdf" H 4450 3850 50  0001 C CNN
	1    4450 3850
	1    0    0    -1  
$EndComp
Text GLabel 3750 2650 0    47   Input ~ 0
VPA
Text GLabel 5050 2650 2    47   Output ~ 0
VMA
Text GLabel 5050 2550 2    47   Output ~ 0
E
Text Notes 3950 6050 0    98   ~ 0
MC68010P10
Text GLabel 5050 3550 2    50   Output ~ 0
A1
Text GLabel 5050 3650 2    50   Output ~ 0
A2
Text GLabel 5050 3750 2    50   Output ~ 0
A3
Text GLabel 5050 3850 2    50   Output ~ 0
A4
Text GLabel 5050 3950 2    50   Output ~ 0
A5
Text GLabel 5050 4050 2    50   Output ~ 0
A6
Text GLabel 5050 4150 2    50   Output ~ 0
A7
Text GLabel 5050 4250 2    50   Output ~ 0
A8
Text GLabel 5050 4350 2    50   Output ~ 0
A9
Text GLabel 5050 4450 2    50   Output ~ 0
A10
Text GLabel 5050 4550 2    50   Output ~ 0
A11
Text GLabel 5050 4650 2    50   Output ~ 0
A12
Text GLabel 5050 4750 2    50   Output ~ 0
A13
Text GLabel 5050 4850 2    50   Output ~ 0
A14
Text GLabel 5050 4950 2    50   Output ~ 0
A15
Text GLabel 5050 5050 2    50   Output ~ 0
A16
Text GLabel 5050 5150 2    50   Output ~ 0
A17
Text GLabel 5050 5250 2    50   Output ~ 0
A18
Text GLabel 5050 5350 2    50   Output ~ 0
A19
Text GLabel 5050 5450 2    50   Output ~ 0
A20
Text GLabel 5050 5550 2    50   Output ~ 0
A21
Text GLabel 5050 5650 2    50   Output ~ 0
A22
Text GLabel 5050 5750 2    50   Output ~ 0
A23
Text GLabel 3750 4250 0    50   BiDi ~ 0
D0
Text GLabel 3750 4350 0    50   BiDi ~ 0
D1
Text GLabel 3750 4450 0    50   BiDi ~ 0
D2
Text GLabel 3750 4550 0    50   BiDi ~ 0
D3
Text GLabel 3750 4650 0    50   BiDi ~ 0
D4
Text GLabel 3750 4750 0    50   BiDi ~ 0
D5
Text GLabel 3750 4850 0    50   BiDi ~ 0
D6
Text GLabel 3750 4950 0    50   BiDi ~ 0
D7
Text GLabel 3750 5050 0    50   BiDi ~ 0
D8
Text GLabel 3750 5150 0    50   BiDi ~ 0
D9
Text GLabel 3750 5250 0    50   BiDi ~ 0
D10
Text GLabel 3750 5350 0    50   BiDi ~ 0
D11
Text GLabel 3750 5450 0    50   BiDi ~ 0
D12
Text GLabel 3750 5550 0    50   BiDi ~ 0
D13
Text GLabel 3750 5650 0    50   BiDi ~ 0
D14
Text GLabel 3750 5750 0    50   BiDi ~ 0
D15
Wire Wire Line
	7400 4300 7200 4300
Wire Wire Line
	7200 4300 6800 4300
Wire Wire Line
	6800 4300 6400 4300
Wire Wire Line
	6400 4300 6400 4600
Wire Wire Line
	7400 4300 7600 4300
Wire Wire Line
	7600 4300 8000 4300
Wire Wire Line
	8000 4300 8400 4300
Wire Wire Line
	8400 4300 8400 4600
Wire Wire Line
	8000 4600 8000 4300
Wire Wire Line
	7600 4600 7600 4300
Wire Wire Line
	7200 4600 7200 4300
Wire Wire Line
	6800 4600 6800 4300
Connection ~ 7400 4300
Connection ~ 8000 4300
Connection ~ 7600 4300
Connection ~ 7200 4300
Connection ~ 6800 4300
Wire Wire Line
	6400 5800 6400 5000
Wire Wire Line
	6800 5800 6800 5000
Text GLabel 6800 5800 3    70   UnSpc ~ 0
IPL1
Wire Wire Line
	7200 5800 7200 5000
Text GLabel 7200 5800 3    70   UnSpc ~ 0
IPL0
Wire Wire Line
	8000 5800 8000 5000
Text GLabel 8000 5800 3    70   UnSpc ~ 0
BGACK
Wire Wire Line
	7600 5800 7600 5000
Text GLabel 7600 5800 3    70   UnSpc ~ 0
BR
Wire Wire Line
	8400 5800 8400 5000
Text GLabel 8400 5800 3    70   UnSpc ~ 0
BERR
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A5C
P 6400 4800
AR Path="/616E1A5C" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A5C" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A5C" Ref="R4"  Part="1" 
F 0 "R4" V 6250 4859 59  0000 L BNN
F 1 "4K7" V 6430 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 6400 4800 50  0001 C CNN
F 3 "" H 6400 4800 50  0001 C CNN
	1    6400 4800
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A68
P 7200 4800
AR Path="/616E1A68" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A68" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A68" Ref="R6"  Part="1" 
F 0 "R6" V 7050 4859 59  0000 L BNN
F 1 "4K7" V 7230 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 7200 4800 50  0001 C CNN
F 3 "" H 7200 4800 50  0001 C CNN
	1    7200 4800
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A6E
P 7600 4800
AR Path="/616E1A6E" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A6E" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A6E" Ref="R7"  Part="1" 
F 0 "R7" V 7450 4859 59  0000 L BNN
F 1 "4K7" V 7630 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 7600 4800 50  0001 C CNN
F 3 "" H 7600 4800 50  0001 C CNN
	1    7600 4800
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A74
P 8000 4800
AR Path="/616E1A74" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A74" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A74" Ref="R9"  Part="1" 
F 0 "R9" V 7850 4859 59  0000 L BNN
F 1 "4K7" V 8030 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 8000 4800 50  0001 C CNN
F 3 "" H 8000 4800 50  0001 C CNN
	1    8000 4800
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A7A
P 8400 4800
AR Path="/616E1A7A" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A7A" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A7A" Ref="R10"  Part="1" 
F 0 "R10" V 8250 4859 59  0000 L BNN
F 1 "4K7" V 8430 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 8400 4800 50  0001 C CNN
F 3 "" H 8400 4800 50  0001 C CNN
	1    8400 4800
	0    -1   -1   0   
$EndComp
$Comp
L power:VCC #PWR?
U 1 1 616E1A80
P 7400 3900
AR Path="/5E53B952/616E1A80" Ref="#PWR?"  Part="1" 
AR Path="/5E53B4B8/616E1A80" Ref="#PWR01"  Part="1" 
F 0 "#PWR01" H 7400 3750 50  0001 C CNN
F 1 "VCC" H 7417 4073 50  0000 C CNN
F 2 "" H 7400 3900 50  0001 C CNN
F 3 "" H 7400 3900 50  0001 C CNN
	1    7400 3900
	1    0    0    -1  
$EndComp
Wire Wire Line
	7400 3900 7400 4300
Text GLabel 6400 5800 3    70   UnSpc ~ 0
IPL2
Text GLabel 7750 2350 2    50   Output ~ 0
CLK
Wire Wire Line
	7250 1650 8150 1650
Wire Wire Line
	7250 1650 7250 2050
Wire Wire Line
	7250 2650 7250 3000
Wire Wire Line
	7250 3000 8150 3000
$Comp
L power:VCC #PWR?
U 1 1 616E1A8D
P 8150 1150
AR Path="/5E53B952/616E1A8D" Ref="#PWR?"  Part="1" 
AR Path="/5E53B4B8/616E1A8D" Ref="#PWR02"  Part="1" 
F 0 "#PWR02" H 8150 1000 50  0001 C CNN
F 1 "VCC" H 8167 1323 50  0000 C CNN
F 2 "" H 8150 1150 50  0001 C CNN
F 3 "" H 8150 1150 50  0001 C CNN
	1    8150 1150
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 616E1A93
P 8150 3300
AR Path="/5E53B952/616E1A93" Ref="#PWR?"  Part="1" 
AR Path="/5E53B4B8/616E1A93" Ref="#PWR03"  Part="1" 
F 0 "#PWR03" H 8150 3050 50  0001 C CNN
F 1 "GND" H 8155 3127 50  0000 C CNN
F 2 "" H 8150 3300 50  0001 C CNN
F 3 "" H 8150 3300 50  0001 C CNN
	1    8150 3300
	1    0    0    -1  
$EndComp
Wire Wire Line
	8150 1150 8150 1650
Wire Wire Line
	8150 3300 8150 3000
Wire Wire Line
	7550 2350 7750 2350
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 616E1A9C
P 6500 2300
AR Path="/616E1A9C" Ref="C?"  Part="1" 
AR Path="/5E53B952/616E1A9C" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/616E1A9C" Ref="C7"  Part="1" 
F 0 "C7" H 6560 2315 59  0000 L BNN
F 1 "100nF" H 6560 2115 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 6500 2300 50  0001 C CNN
F 3 "" H 6500 2300 50  0001 C CNN
	1    6500 2300
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 616E1AA2
P 8150 2300
AR Path="/616E1AA2" Ref="C?"  Part="1" 
AR Path="/5E53B952/616E1AA2" Ref="C?"  Part="1" 
AR Path="/5E53B4B8/616E1AA2" Ref="C8"  Part="1" 
F 0 "C8" H 8210 2315 59  0000 L BNN
F 1 "100nF" H 8210 2115 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 8150 2300 50  0001 C CNN
F 3 "" H 8150 2300 50  0001 C CNN
	1    8150 2300
	1    0    0    -1  
$EndComp
Wire Wire Line
	6500 2200 6500 1650
Wire Wire Line
	6500 1650 6850 1650
Connection ~ 7250 1650
Wire Wire Line
	6500 2500 6500 3000
Wire Wire Line
	6500 3000 7250 3000
Connection ~ 7250 3000
Wire Wire Line
	8150 2200 8150 1650
Wire Wire Line
	8150 2500 8150 3000
$Comp
L Oscillator:CXO_DIP8 Q?
U 1 1 616E1AB0
P 7250 2350
AR Path="/5E53B952/616E1AB0" Ref="Q?"  Part="1" 
AR Path="/5E53B4B8/616E1AB0" Ref="Q2"  Part="1" 
F 0 "Q2" H 7400 2600 50  0000 L CNN
F 1 "5H8ET-10.000" H 7400 2100 50  0000 L CNN
F 2 "Oscillator:Oscillator_DIP-8" H 7700 2000 50  0001 C CNN
F 3 "https://docs.rs-online.com/4a59/0900766b81111d78.pdf" H 7150 2350 50  0001 C CNN
	1    7250 2350
	1    0    0    -1  
$EndComp
$Comp
L Device:R R?
U 1 1 616E1AB6
P 6850 1900
AR Path="/5E53B952/616E1AB6" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1AB6" Ref="R3"  Part="1" 
F 0 "R3" H 6920 1946 50  0000 L CNN
F 1 "4K7" H 6920 1855 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 6780 1900 50  0001 C CNN
F 3 "~" H 6850 1900 50  0001 C CNN
	1    6850 1900
	1    0    0    -1  
$EndComp
Wire Wire Line
	6850 1750 6850 1650
Connection ~ 6850 1650
Wire Wire Line
	6850 1650 7250 1650
Wire Wire Line
	6850 2050 6850 2350
Wire Wire Line
	6850 2350 6950 2350
Connection ~ 8150 1650
Connection ~ 8150 3000
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 616E1A62
P 6800 4800
AR Path="/616E1A62" Ref="R?"  Part="1" 
AR Path="/5E53B952/616E1A62" Ref="R?"  Part="1" 
AR Path="/5E53B4B8/616E1A62" Ref="R5"  Part="1" 
F 0 "R5" V 6650 4859 59  0000 L BNN
F 1 "4K7" V 6830 4850 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 6800 4800 50  0001 C CNN
F 3 "" H 6800 4800 50  0001 C CNN
	1    6800 4800
	0    -1   -1   0   
$EndComp
$EndSCHEMATC
