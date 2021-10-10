EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 7 7
Title "rosco_m68k Pro (030) Prototype"
Date "2021-10-01"
Rev "0"
Comp "The Really Old-School Company Limited"
Comment1 "Copyright ©2021 The Really Old-School Company Limited"
Comment2 "Open Source Hardware (CERN OHL)"
Comment3 "Prototype Hardware! Not suitable for general use!"
Comment4 ""
$EndDescr
$Comp
L rosco_m68k-rescue:GAL22V10 IC?
U 1 1 616244B8
P 9200 3900
AR Path="/61161E57/616244B8" Ref="IC?"  Part="1" 
AR Path="/6103896C/616244B8" Ref="IC10"  Part="1" 
AR Path="/617D19F3/616244B8" Ref="IC6"  Part="1" 
F 0 "IC6" H 9200 4781 50  0000 C CNN
F 1 "ATF22V10C" H 9200 4690 50  0000 C CNN
F 2 "Package_DIP:DIP-24_W7.62mm_Socket_LongPads" H 9200 3900 50  0001 C CNN
F 3 "https://www.mouser.com/datasheet/2/268/doc0735-1369018.pdf" H 9200 3900 50  0001 C CNN
	1    9200 3900
	1    0    0    -1  
$EndComp
Wire Wire Line
	9200 4600 9200 4850
Text GLabel 8700 3400 0    50   Input ~ 0
CLK
Text GLabel 8700 3500 0    50   Input ~ 0
AS
Text GLabel 8700 3600 0    50   Input ~ 0
ANYIACK
NoConn ~ 9700 3600
NoConn ~ 9700 3500
Text Notes 6700 5000 0    50   ~ 0
WATCHDOG.PLD
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 616269B3
P 5850 3700
AR Path="/616269B3" Ref="C?"  Part="1" 
AR Path="/5E53B810/616269B3" Ref="C?"  Part="1" 
AR Path="/5E53B952/616269B3" Ref="C?"  Part="1" 
AR Path="/6103896C/616269B3" Ref="C12"  Part="1" 
AR Path="/617D19F3/616269B3" Ref="C12"  Part="1" 
F 0 "C12" H 5910 3715 59  0000 L BNN
F 1 "100nF" H 5910 3515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 5850 3700 50  0001 C CNN
F 3 "" H 5850 3700 50  0001 C CNN
	1    5850 3700
	1    0    0    -1  
$EndComp
Wire Wire Line
	5850 3900 5850 4850
Wire Wire Line
	5850 3200 5850 3600
NoConn ~ 8700 3700
NoConn ~ 8700 3800
NoConn ~ 8700 3900
NoConn ~ 8700 4000
NoConn ~ 8700 4100
NoConn ~ 8700 4200
NoConn ~ 8700 4300
NoConn ~ 8700 4400
Text GLabel 9700 4400 2    50   UnSpc ~ 0
GND
Text GLabel 9700 3400 2    50   3State ~ 0
BERR
NoConn ~ 9700 4300
NoConn ~ 9700 4200
NoConn ~ 9700 4000
NoConn ~ 9700 3900
NoConn ~ 9700 3800
NoConn ~ 9700 3700
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 616BA5ED
P 8000 3700
AR Path="/616BA5ED" Ref="C?"  Part="1" 
AR Path="/5E53B810/616BA5ED" Ref="C?"  Part="1" 
AR Path="/5E53B952/616BA5ED" Ref="C?"  Part="1" 
AR Path="/6103896C/616BA5ED" Ref="C30"  Part="1" 
AR Path="/617D19F3/616BA5ED" Ref="C31"  Part="1" 
F 0 "C31" H 8060 3715 59  0000 L BNN
F 1 "100nF" H 8060 3515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 8000 3700 50  0001 C CNN
F 3 "" H 8000 3700 50  0001 C CNN
	1    8000 3700
	1    0    0    -1  
$EndComp
Wire Wire Line
	8000 3900 8000 4850
Wire Wire Line
	8000 3200 8000 3600
Text GLabel 6450 3900 0    47   Input ~ 0
FC0
Text GLabel 6450 3800 0    47   Input ~ 0
FC1
Text GLabel 6450 3700 0    47   Input ~ 0
FC2
Text GLabel 7450 3400 2    47   Output ~ 0
DUAIACK
$Comp
L rosco_m68k-rescue:GAL22V10 IC?
U 1 1 6161CAA3
P 6950 3900
AR Path="/5E53B810/6161CAA3" Ref="IC?"  Part="1" 
AR Path="/5E53B952/6161CAA3" Ref="IC?"  Part="1" 
AR Path="/617D19F3/6161CAA3" Ref="IC5"  Part="1" 
F 0 "IC5" H 6950 4786 59  0000 C CNN
F 1 "ATF16V8BQL-15PU" H 6950 4681 59  0000 C CNN
F 2 "Package_DIP:DIP-24_W7.62mm_Socket_LongPads" H 6950 3900 50  0001 C CNN
F 3 "https://www.mouser.com/datasheet/2/268/doc0735-1369018.pdf" H 6950 3900 50  0001 C CNN
	1    6950 3900
	1    0    0    -1  
$EndComp
Text Notes 8900 5000 0    50   ~ 0
GLUE_LOGIC.PLD
Text GLabel 3000 3700 2    47   Input ~ 0
ANYIACK
Text GLabel 3000 3900 2    47   Output ~ 0
IOSEL
Text GLabel 2000 4000 0    47   Input ~ 0
UDS
Text GLabel 2000 4100 0    47   Input ~ 0
LDS
Text GLabel 2000 4200 0    47   Input ~ 0
BOOT
Text GLabel 3000 4400 2    47   Input ~ 0
AS
Text GLabel 3000 4300 2    47   Output ~ 0
EVENRAMSEL
Text GLabel 3000 4200 2    47   Output ~ 0
ODDRAMSEL
Text GLabel 3000 4100 2    47   Output ~ 0
EVENROMSEL
Text GLabel 3000 4000 2    47   Output ~ 0
ODDROMSEL
Text GLabel 3000 3800 2    47   Output ~ 0
EXPSEL
NoConn ~ 3000 3600
$Comp
L power:VCC #PWR?
U 1 1 6161CACE
P 1400 3000
AR Path="/5E53B630/6161CACE" Ref="#PWR?"  Part="1" 
AR Path="/5E53B952/6161CACE" Ref="#PWR?"  Part="1" 
AR Path="/617D19F3/6161CACE" Ref="#PWR0113"  Part="1" 
F 0 "#PWR0113" H 1400 2850 50  0001 C CNN
F 1 "VCC" H 1417 3173 50  0000 C CNN
F 2 "" H 1400 3000 50  0001 C CNN
F 3 "" H 1400 3000 50  0001 C CNN
	1    1400 3000
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 6161CAD4
P 1400 5050
AR Path="/5E53B630/6161CAD4" Ref="#PWR?"  Part="1" 
AR Path="/5E53B952/6161CAD4" Ref="#PWR?"  Part="1" 
AR Path="/617D19F3/6161CAD4" Ref="#PWR0115"  Part="1" 
F 0 "#PWR0115" H 1400 4800 50  0001 C CNN
F 1 "GND" H 1405 4877 50  0000 C CNN
F 2 "" H 1400 5050 50  0001 C CNN
F 3 "" H 1400 5050 50  0001 C CNN
	1    1400 5050
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-rescue:GAL22V10 IC?
U 1 1 6161CADA
P 2500 3900
AR Path="/5E53B630/6161CADA" Ref="IC?"  Part="1" 
AR Path="/5E53B952/6161CADA" Ref="IC?"  Part="1" 
AR Path="/617D19F3/6161CADA" Ref="IC2"  Part="1" 
F 0 "IC2" H 2500 4786 59  0000 C CNN
F 1 "ATF16V8BQL-15PU" H 2500 4681 59  0000 C CNN
F 2 "Package_DIP:DIP-24_W7.62mm_Socket_LongPads" H 2500 3900 50  0001 C CNN
F 3 "https://www.mouser.com/datasheet/2/268/doc0735-1369018.pdf" H 2500 3900 50  0001 C CNN
	1    2500 3900
	1    0    0    -1  
$EndComp
Text Notes 2050 5000 0    50   ~ 0
ADDRESS_DECODER.PLD
Wire Wire Line
	1400 3000 1400 3200
Wire Wire Line
	1400 4850 1400 5050
Connection ~ 1400 4850
NoConn ~ 6450 3500
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 6161CAC0
P 1400 3750
AR Path="/6161CAC0" Ref="C?"  Part="1" 
AR Path="/5E53B630/6161CAC0" Ref="C?"  Part="1" 
AR Path="/5E53B952/6161CAC0" Ref="C?"  Part="1" 
AR Path="/617D19F3/6161CAC0" Ref="C9"  Part="1" 
F 0 "C9" H 1460 3765 59  0000 L BNN
F 1 "100nF" H 1460 3565 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 1400 3750 50  0001 C CNN
F 3 "" H 1400 3750 50  0001 C CNN
	1    1400 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	1400 3650 1400 3200
Connection ~ 1400 3200
Text GLabel 2000 3400 0    50   Input ~ 0
A18
Text GLabel 2000 3500 0    50   Input ~ 0
A19
Text GLabel 2000 3600 0    50   Input ~ 0
A20
Text GLabel 2000 3700 0    50   Input ~ 0
A21
Text GLabel 2000 3800 0    50   Input ~ 0
A22
Text GLabel 2000 3900 0    50   Input ~ 0
A23
Wire Wire Line
	1400 3200 2500 3200
Text GLabel 2000 4300 0    50   Input ~ 0
LGEXP
Text GLabel 2000 4400 0    50   Input ~ 0
RW
Text GLabel 3000 3500 2    50   3State ~ 0
DTACK
Text GLabel 3000 3400 2    50   Output ~ 0
WR
Wire Wire Line
	1400 4850 2500 4850
Wire Wire Line
	3650 3200 2500 3200
Connection ~ 2500 3200
Wire Wire Line
	1400 3950 1400 4850
Text GLabel 1800 6850 0    50   BiDi ~ 0
DTACK
Text GLabel 1800 7000 0    50   Input ~ 0
LGEXP
Wire Wire Line
	1800 6850 2550 6850
Wire Wire Line
	1800 7000 2200 7000
$Comp
L Device:R R8
U 1 1 61653F75
P 2200 6200
F 0 "R8" H 2270 6246 50  0000 L CNN
F 1 "4K7" H 2270 6155 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 2130 6200 50  0001 C CNN
F 3 "~" H 2200 6200 50  0001 C CNN
	1    2200 6200
	1    0    0    -1  
$EndComp
$Comp
L Device:R R21
U 1 1 61654750
P 2550 6200
F 0 "R21" H 2620 6246 50  0000 L CNN
F 1 "1K2" H 2620 6155 50  0000 L CNN
F 2 "rosco_m68k:0207_10" V 2480 6200 50  0001 C CNN
F 3 "~" H 2550 6200 50  0001 C CNN
	1    2550 6200
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR?
U 1 1 61654F39
P 2400 5700
AR Path="/5E53B630/61654F39" Ref="#PWR?"  Part="1" 
AR Path="/5E53B952/61654F39" Ref="#PWR?"  Part="1" 
AR Path="/617D19F3/61654F39" Ref="#PWR0116"  Part="1" 
F 0 "#PWR0116" H 2400 5550 50  0001 C CNN
F 1 "VCC" H 2417 5873 50  0000 C CNN
F 2 "" H 2400 5700 50  0001 C CNN
F 3 "" H 2400 5700 50  0001 C CNN
	1    2400 5700
	1    0    0    -1  
$EndComp
Wire Wire Line
	2200 6050 2200 5700
Wire Wire Line
	2200 5700 2400 5700
Wire Wire Line
	2400 5700 2550 5700
Wire Wire Line
	2550 5700 2550 6050
Connection ~ 2400 5700
Wire Wire Line
	2200 6350 2200 7000
Wire Wire Line
	2550 6350 2550 6850
Text GLabel 6450 3600 0    50   Input ~ 0
HWRST
Text GLabel 6450 4000 0    50   Input ~ 0
A1
Text GLabel 6450 4100 0    50   Input ~ 0
A2
Text GLabel 6450 4200 0    50   Input ~ 0
A3
Text GLabel 6450 4300 0    50   Input ~ 0
A19
NoConn ~ 6450 4400
Text GLabel 7450 3500 2    50   Output ~ 0
ANYIACK
Text GLabel 7450 3600 2    50   Output ~ 0
BOOT
NoConn ~ 7450 3800
NoConn ~ 7450 3900
Text GLabel 7450 4000 2    50   Output ~ 0
RUNLED
Text GLabel 7450 4100 2    50   3State ~ 0
RESET
Text GLabel 7450 4200 2    50   3State ~ 0
HALT
NoConn ~ 7450 3700
NoConn ~ 7450 4300
NoConn ~ 7450 4400
Text GLabel 6450 3400 0    50   Input ~ 0
AS
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 61687A3B
P 10300 3700
AR Path="/61687A3B" Ref="C?"  Part="1" 
AR Path="/5E53B810/61687A3B" Ref="C?"  Part="1" 
AR Path="/5E53B952/61687A3B" Ref="C?"  Part="1" 
AR Path="/6103896C/61687A3B" Ref="C?"  Part="1" 
AR Path="/617D19F3/61687A3B" Ref="C10"  Part="1" 
F 0 "C10" H 10360 3715 59  0000 L BNN
F 1 "100nF" H 10360 3515 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 10300 3700 50  0001 C CNN
F 3 "" H 10300 3700 50  0001 C CNN
	1    10300 3700
	1    0    0    -1  
$EndComp
Wire Wire Line
	10300 3900 10300 4850
Wire Wire Line
	10300 3200 10300 3600
Wire Wire Line
	6950 4600 6950 4850
Wire Wire Line
	2500 4600 2500 4850
Connection ~ 2500 4850
Wire Wire Line
	2500 4850 3650 4850
$Comp
L rosco_m68k-rescue:GAL22V10 IC?
U 1 1 616AF603
P 4750 3900
AR Path="/61161E57/616AF603" Ref="IC?"  Part="1" 
AR Path="/6103896C/616AF603" Ref="IC?"  Part="1" 
AR Path="/617D19F3/616AF603" Ref="IC3"  Part="1" 
F 0 "IC3" H 4750 4781 50  0000 C CNN
F 1 "ATF22V10C" H 4750 4690 50  0000 C CNN
F 2 "Package_DIP:DIP-24_W7.62mm_Socket_LongPads" H 4750 3900 50  0001 C CNN
F 3 "https://www.mouser.com/datasheet/2/268/doc0735-1369018.pdf" H 4750 3900 50  0001 C CNN
	1    4750 3900
	1    0    0    -1  
$EndComp
Text GLabel 4250 3400 0    50   Input ~ 0
A6
Text GLabel 4250 3500 0    50   Input ~ 0
A7
Text GLabel 4250 3600 0    50   Input ~ 0
A8
Text GLabel 4250 3700 0    50   Input ~ 0
A9
Text GLabel 4250 3800 0    50   Input ~ 0
A10
Text GLabel 4250 3900 0    50   Input ~ 0
A11
Text GLabel 4250 4000 0    50   Input ~ 0
A12
Text GLabel 4250 4100 0    50   Input ~ 0
A13
Text GLabel 4250 4200 0    50   Input ~ 0
A14
Text GLabel 4250 4300 0    50   Input ~ 0
A15
Text GLabel 4250 4400 0    50   Input ~ 0
A16
Text GLabel 5250 4100 2    50   Input ~ 0
A17
Text GLabel 5250 4000 2    50   Input ~ 0
A18
Text GLabel 5250 3900 2    50   Input ~ 0
LDS
Text GLabel 5250 3800 2    50   Input ~ 0
IOSEL
Text GLabel 5250 3700 2    50   Output ~ 0
DUASEL
NoConn ~ 5250 3600
NoConn ~ 5250 3500
NoConn ~ 5250 3400
NoConn ~ 5250 4200
NoConn ~ 5250 4300
NoConn ~ 5250 4400
Connection ~ 8000 3200
Connection ~ 8000 4850
$Comp
L rosco_m68k-eagle-import:C2,5-3 C?
U 1 1 616BE28D
P 3650 3750
AR Path="/616BE28D" Ref="C?"  Part="1" 
AR Path="/5E53B630/616BE28D" Ref="C?"  Part="1" 
AR Path="/5E53B952/616BE28D" Ref="C?"  Part="1" 
AR Path="/617D19F3/616BE28D" Ref="C32"  Part="1" 
F 0 "C32" H 3710 3765 59  0000 L BNN
F 1 "100nF" H 3710 3565 59  0000 L BNN
F 2 "rosco_m68k:C2.5-3" H 3650 3750 50  0001 C CNN
F 3 "" H 3650 3750 50  0001 C CNN
	1    3650 3750
	1    0    0    -1  
$EndComp
Wire Wire Line
	3650 3650 3650 3200
Wire Wire Line
	3650 3950 3650 4850
Wire Wire Line
	3650 3200 4750 3200
Connection ~ 3650 3200
Wire Wire Line
	5850 3200 4750 3200
Connection ~ 5850 3200
Connection ~ 4750 3200
Wire Wire Line
	3650 4850 4750 4850
Wire Wire Line
	4750 4850 4750 4600
Connection ~ 3650 4850
Wire Wire Line
	5850 4850 4750 4850
Connection ~ 5850 4850
Connection ~ 4750 4850
Wire Wire Line
	5850 4850 6950 4850
Wire Wire Line
	5850 3200 6950 3200
Connection ~ 6950 3200
Wire Wire Line
	6950 3200 8000 3200
Wire Wire Line
	8000 3200 9200 3200
Connection ~ 6950 4850
Wire Wire Line
	6950 4850 8000 4850
Wire Wire Line
	8000 4850 9200 4850
Connection ~ 9200 3200
Wire Wire Line
	9200 3200 10300 3200
Connection ~ 9200 4850
Wire Wire Line
	9200 4850 10300 4850
Text Notes 4450 5000 0    50   ~ 0
DUART_SEL.PLD
NoConn ~ 9700 4100
$Comp
L Device:Jumper JP3
U 1 1 617668AC
P 2900 7000
F 0 "JP3" H 2900 7264 50  0000 C CNN
F 1 "Jumper" H 2900 7173 50  0000 C CNN
F 2 "rosco_m68k:1X02" H 2900 7000 50  0001 C CNN
F 3 "~" H 2900 7000 50  0001 C CNN
	1    2900 7000
	1    0    0    -1  
$EndComp
Wire Wire Line
	2200 7000 2600 7000
Connection ~ 2200 7000
$Comp
L power:GND #PWR?
U 1 1 61767A5B
P 3500 7150
AR Path="/5E53B630/61767A5B" Ref="#PWR?"  Part="1" 
AR Path="/5E53B952/61767A5B" Ref="#PWR?"  Part="1" 
AR Path="/617D19F3/61767A5B" Ref="#PWR05"  Part="1" 
F 0 "#PWR05" H 3500 6900 50  0001 C CNN
F 1 "GND" H 3505 6977 50  0000 C CNN
F 2 "" H 3500 7150 50  0001 C CNN
F 3 "" H 3500 7150 50  0001 C CNN
	1    3500 7150
	1    0    0    -1  
$EndComp
Wire Wire Line
	3200 7000 3500 7000
Wire Wire Line
	3500 7000 3500 7150
$EndSCHEMATC
