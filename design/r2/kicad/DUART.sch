EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 7
Title "ROSCO_M68K GENERAL PURPOSE MC68010 COMPUTER"
Date "2021-10-08"
Rev "2.0"
Comp "The Really Old-School Company Limited"
Comment1 "OSHWA UK000006 (https://certification.oshwa.org/uk000006.html)"
Comment2 "See https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt"
Comment3 "Open Source Hardware licenced under CERN Open Hardware Licence"
Comment4 "Copyright 2019-2021 Ross Bamford and Contributors"
$EndDescr
NoConn ~ -2300 8300
$Comp
L Device:Crystal Q1
U 1 1 5EDD7329
P 7900 3150
F 0 "Q1" H 7900 3418 50  0000 C CNN
F 1 "Crystal" H 7900 3327 50  0000 C CNN
F 2 "Crystal:Crystal_HC49-4H_Vertical" H 7900 3150 50  0001 C CNN
F 3 "~" H 7900 3150 50  0001 C CNN
	1    7900 3150
	1    0    0    -1  
$EndComp
$Comp
L Device:C C1
U 1 1 5EDD83D0
P 7550 3850
F 0 "C1" H 7665 3896 50  0000 L CNN
F 1 "7pF" H 7665 3805 50  0000 L CNN
F 2 "rosco_m68k:C2.5-3" H 7588 3700 50  0001 C CNN
F 3 "~" H 7550 3850 50  0001 C CNN
	1    7550 3850
	-1   0    0    1   
$EndComp
$Comp
L Device:C C2
U 1 1 5EDD8A07
P 8200 3850
F 0 "C2" H 8315 3896 50  0000 L CNN
F 1 "7pF" H 8315 3805 50  0000 L CNN
F 2 "rosco_m68k:C2.5-3" H 8238 3700 50  0001 C CNN
F 3 "~" H 8200 3850 50  0001 C CNN
	1    8200 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	8200 3700 8200 3150
Wire Wire Line
	8050 3150 8200 3150
Wire Wire Line
	7750 3150 7550 3150
Wire Wire Line
	7550 3150 7550 3700
Wire Wire Line
	8200 4000 8200 4300
Wire Wire Line
	7550 4000 7550 4300
Text GLabel 7550 4200 3    50   UnSpc ~ 0
GND
Text GLabel 8200 4200 3    50   UnSpc ~ 0
GND
Text GLabel 6400 3400 2    50   BiDi ~ 0
D0
Text GLabel 4400 3500 0    50   BiDi ~ 0
D1
Text GLabel 6400 3500 2    50   BiDi ~ 0
D2
Text GLabel 4400 3600 0    50   BiDi ~ 0
D3
Text GLabel 6400 3600 2    50   BiDi ~ 0
D4
Text GLabel 4400 3700 0    50   BiDi ~ 0
D5
Text GLabel 6400 3700 2    50   BiDi ~ 0
D6
Text GLabel 4400 3800 0    50   BiDi ~ 0
D7
Text GLabel 4400 2600 0    50   Input ~ 0
RW
Text GLabel 6400 2400 2    50   Input ~ 0
RESET
Text GLabel 4400 2700 0    50   3State ~ 0
DTACK
Connection ~ 7550 3150
Text GLabel 6400 2300 2    50   Input ~ 0
DUASEL
Text GLabel 4400 1900 0    50   Input ~ 0
A1
Text GLabel 4400 2100 0    50   Input ~ 0
A2
Text GLabel 4400 2300 0    50   Input ~ 0
A3
Text GLabel 4400 2400 0    50   Input ~ 0
A4
$Comp
L Connector:Conn_01x06_Male J1
U 1 1 5EE19F70
P 1250 5850
F 0 "J1" H 1358 6231 50  0000 C CNN
F 1 "UART_A" H 1358 6140 50  0000 C CNN
F 2 "rosco_m68k:1X06" H 1250 5850 50  0001 C CNN
F 3 "~" H 1250 5850 50  0001 C CNN
	1    1250 5850
	1    0    0    -1  
$EndComp
$Comp
L Connector:Conn_01x06_Male J2
U 1 1 5EE1B2ED
P 1250 6700
F 0 "J2" H 1358 7081 50  0000 C CNN
F 1 "UART_B" H 1358 6990 50  0000 C CNN
F 2 "rosco_m68k:1X06" H 1250 6700 50  0001 C CNN
F 3 "~" H 1250 6700 50  0001 C CNN
	1    1250 6700
	1    0    0    -1  
$EndComp
Text GLabel 1450 5650 2    50   UnSpc ~ 0
GND
Text GLabel 1450 5750 2    50   Output ~ 0
CTSA
Text GLabel 1450 6050 2    50   Input ~ 0
TXDA
Text GLabel 1450 5950 2    50   Output ~ 0
RXDA
Text GLabel 10650 5200 2    50   UnSpc ~ 0
VCC
Text GLabel 9500 5200 0    50   UnSpc ~ 0
VCCUA
Text GLabel 9500 5650 0    50   UnSpc ~ 0
VCCUB
Text GLabel 1450 5850 2    50   UnSpc ~ 0
VCCUA
Text GLabel 1450 6700 2    50   UnSpc ~ 0
VCCUB
Text GLabel 1450 6500 2    50   UnSpc ~ 0
GND
Text GLabel 1450 6600 2    50   Output ~ 0
CTSB
Text GLabel 1450 6900 2    50   Input ~ 0
TXDB
Text GLabel 1450 6800 2    50   Output ~ 0
RXDB
Text GLabel 6400 3100 2    50   Output ~ 0
SPICS
Text GLabel 6400 3200 2    50   Output ~ 0
SPICLK
Text GLabel 6400 3300 2    50   Output ~ 0
SPIMOSI
Text GLabel 4400 2500 0    50   Input ~ 0
RTSA
Text GLabel 4400 2200 0    50   Input ~ 0
RTSB
Text GLabel 6400 2200 2    50   Input ~ 0
SPIMISO
Connection ~ 8200 3150
Text GLabel 4400 3000 0    50   Output ~ 0
TXDB
Text GLabel 4400 2800 0    50   Input ~ 0
RXDB
Text GLabel 6400 2700 2    50   Input ~ 0
RXDA
Text GLabel 6400 2900 2    50   Output ~ 0
TXDA
$Comp
L Device:C C28
U 1 1 5EF9C0B2
P 1250 1450
F 0 "C28" V 998 1450 50  0000 C CNN
F 1 "100nF" V 1089 1450 50  0000 C CNN
F 2 "rosco_m68k:C2.5-3" H 1288 1300 50  0001 C CNN
F 3 "~" H 1250 1450 50  0001 C CNN
	1    1250 1450
	0    1    1    0   
$EndComp
$Comp
L Device:C C29
U 1 1 5EF9CBDA
P 1250 1900
F 0 "C29" V 998 1900 50  0000 C CNN
F 1 "100nF" V 1089 1900 50  0000 C CNN
F 2 "rosco_m68k:C2.5-3" H 1288 1750 50  0001 C CNN
F 3 "~" H 1250 1900 50  0001 C CNN
	1    1250 1900
	0    1    1    0   
$EndComp
Wire Wire Line
	1000 1100 1000 1450
Wire Wire Line
	1500 1450 1500 1900
Wire Wire Line
	1400 1450 1500 1450
Wire Wire Line
	1100 1450 1000 1450
Connection ~ 1000 1450
Wire Wire Line
	1000 1450 1000 1900
Wire Wire Line
	1100 1900 1000 1900
Connection ~ 1000 1900
Wire Wire Line
	1400 1900 1500 1900
Connection ~ 1500 1900
Text GLabel 1000 1100 1    50   UnSpc ~ 0
VCC
Text GLabel 1500 2500 3    50   UnSpc ~ 0
GND
Text GLabel 6400 1800 2    50   UnSpc ~ 0
VCC
Text GLabel 4400 3900 0    50   UnSpc ~ 0
GND
Text GLabel 6400 3000 2    50   Output ~ 0
CTSA
Text GLabel 4400 3100 0    50   Output ~ 0
CTSB
$Comp
L Device:C C30
U 1 1 5EE63A78
P 1250 2350
F 0 "C30" V 998 2350 50  0000 C CNN
F 1 "100nF" V 1089 2350 50  0000 C CNN
F 2 "rosco_m68k:C2.5-3" H 1288 2200 50  0001 C CNN
F 3 "~" H 1250 2350 50  0001 C CNN
	1    1250 2350
	0    1    1    0   
$EndComp
Wire Wire Line
	1000 1900 1000 2350
Wire Wire Line
	1500 1900 1500 2350
Wire Wire Line
	1400 2350 1500 2350
Wire Wire Line
	1100 2350 1000 2350
$Comp
L rosco_m68k-rescue:XR68C681CJTR-F-XR68C681 IC4
U 1 1 603DDDD7
P 4400 1800
F 0 "IC4" H 5400 2293 60  0000 C CNN
F 1 "XR68C681CJTR-F" H 5400 2187 60  0000 C CNN
F 2 "Package_LCC:PLCC-44_THT-Socket" H 5400 2040 60  0001 C CNN
F 3 "https://www.maxlinear.com/ds/xr68c681v210.pdf" H 5400 2081 60  0000 C CNN
	1    4400 1800
	1    0    0    -1  
$EndComp
Text GLabel 6400 2100 2    50   Input ~ 0
DUAIACK
Wire Wire Line
	8200 2500 8200 3150
Wire Wire Line
	7550 2600 7550 3150
Wire Wire Line
	6400 2600 7550 2600
Wire Wire Line
	8200 2500 6400 2500
Text GLabel 6400 3800 2    50   3State ~ 0
IPL2
NoConn ~ 6400 1900
NoConn ~ 6400 2000
Text GLabel 4400 2000 0    50   UnSpc ~ 0
GND
$Comp
L Connector_Generic:Conn_01x06 J?
U 1 1 61644BC0
P 3950 6350
AR Path="/5E53B4B8/61644BC0" Ref="J?"  Part="1" 
AR Path="/5E53BC83/61644BC0" Ref="J?"  Part="1" 
AR Path="/61622E90/61644BC0" Ref="J4"  Part="1" 
F 0 "J4" H 3900 6700 50  0000 L CNN
F 1 "Conn_01x06" H 3700 5900 50  0000 L CNN
F 2 "rosco_m68k:1X06" H 3950 6350 50  0001 C CNN
F 3 "~" H 3950 6350 50  0001 C CNN
	1    3950 6350
	1    0    0    -1  
$EndComp
Text GLabel 3750 6150 0    50   Input ~ 0
SPICS
Text Notes 4050 6200 0    50   ~ 0
CS
Text Notes 4050 6300 0    50   ~ 0
SCK
Text GLabel 3750 6250 0    50   Input ~ 0
SPICLK
Text GLabel 3750 6350 0    50   Input ~ 0
SPIMOSI
Text GLabel 3750 6450 0    50   Output ~ 0
SPIMISO
Text Notes 4050 6400 0    50   ~ 0
MOSI
Text Notes 4050 6500 0    50   ~ 0
MISO
$Comp
L power:VCC #PWR?
U 1 1 61644BCE
P 3200 6450
AR Path="/5E53BC83/61644BCE" Ref="#PWR?"  Part="1" 
AR Path="/61622E90/61644BCE" Ref="#PWR0101"  Part="1" 
F 0 "#PWR0101" H 3200 6300 50  0001 C CNN
F 1 "VCC" H 3217 6623 50  0000 C CNN
F 2 "" H 3200 6450 50  0001 C CNN
F 3 "" H 3200 6450 50  0001 C CNN
	1    3200 6450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR?
U 1 1 61644BD4
P 3200 6750
AR Path="/5E53BC83/61644BD4" Ref="#PWR?"  Part="1" 
AR Path="/61622E90/61644BD4" Ref="#PWR0102"  Part="1" 
F 0 "#PWR0102" H 3200 6500 50  0001 C CNN
F 1 "GND" H 3205 6577 50  0000 C CNN
F 2 "" H 3200 6750 50  0001 C CNN
F 3 "" H 3200 6750 50  0001 C CNN
	1    3200 6750
	1    0    0    -1  
$EndComp
Wire Wire Line
	3750 6550 3200 6550
Wire Wire Line
	3200 6550 3200 6450
Wire Wire Line
	3750 6650 3200 6650
Wire Wire Line
	3200 6650 3200 6750
Wire Wire Line
	1500 2350 1500 2500
Connection ~ 1500 2350
$Comp
L Device:Jumper JP2
U 1 1 616FCABD
P 10000 5650
F 0 "JP2" H 10000 5914 50  0000 C CNN
F 1 "Jumper" H 10000 5823 50  0000 C CNN
F 2 "rosco_m68k:1X02" H 10000 5650 50  0001 C CNN
F 3 "~" H 10000 5650 50  0001 C CNN
	1    10000 5650
	1    0    0    -1  
$EndComp
$Comp
L Device:Jumper JP1
U 1 1 616FD293
P 10000 5200
F 0 "JP1" H 10000 5464 50  0000 C CNN
F 1 "Jumper" H 10000 5373 50  0000 C CNN
F 2 "rosco_m68k:1X02" H 10000 5200 50  0001 C CNN
F 3 "~" H 10000 5200 50  0001 C CNN
	1    10000 5200
	1    0    0    -1  
$EndComp
Wire Wire Line
	9500 5200 9700 5200
Wire Wire Line
	10300 5200 10500 5200
Wire Wire Line
	10300 5650 10500 5650
Wire Wire Line
	10500 5650 10500 5200
Connection ~ 10500 5200
Wire Wire Line
	10500 5200 10650 5200
Wire Wire Line
	9500 5650 9700 5650
Text GLabel 1450 6150 2    50   Input ~ 0
RTSA
Text GLabel 1450 7000 2    50   Input ~ 0
RTSB
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 6161B40D
P 3150 2400
AR Path="/6161B40D" Ref="R?"  Part="1" 
AR Path="/5E53B952/6161B40D" Ref="R?"  Part="1" 
AR Path="/60FBFA5C/6161B40D" Ref="R?"  Part="1" 
AR Path="/61043B8D/6161B40D" Ref="R?"  Part="1" 
AR Path="/6162E38E/6161B40D" Ref="R?"  Part="1" 
AR Path="/61622E90/6161B40D" Ref="R1"  Part="1" 
F 0 "R1" V 3291 2450 59  0000 L BNN
F 1 "330R" V 3180 2450 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 3150 2400 50  0001 C CNN
F 3 "" H 3150 2400 50  0001 C CNN
	1    3150 2400
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:LED5MM LED?
U 1 1 6161B413
P 3150 2700
AR Path="/6161B413" Ref="LED?"  Part="1" 
AR Path="/5E53B952/6161B413" Ref="LED?"  Part="1" 
AR Path="/60FBFA5C/6161B413" Ref="LED?"  Part="1" 
AR Path="/61043B8D/6161B413" Ref="LED?"  Part="1" 
AR Path="/6162E38E/6161B413" Ref="LED?"  Part="1" 
AR Path="/61622E90/6161B413" Ref="LED1"  Part="1" 
F 0 "LED1" H 3400 2800 59  0000 R TNN
F 1 "GREEN" H 3500 2700 59  0000 R TNN
F 2 "rosco_m68k:LED5MM" H 3150 2700 50  0001 C CNN
F 3 "" H 3150 2700 50  0001 C CNN
	1    3150 2700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:R-EU_0207_10 R?
U 1 1 6161C7AA
P 3650 2400
AR Path="/6161C7AA" Ref="R?"  Part="1" 
AR Path="/5E53B952/6161C7AA" Ref="R?"  Part="1" 
AR Path="/60FBFA5C/6161C7AA" Ref="R?"  Part="1" 
AR Path="/61043B8D/6161C7AA" Ref="R?"  Part="1" 
AR Path="/6162E38E/6161C7AA" Ref="R?"  Part="1" 
AR Path="/61622E90/6161C7AA" Ref="R2"  Part="1" 
F 0 "R2" V 3791 2450 59  0000 L BNN
F 1 "330R" V 3680 2450 59  0000 L BNN
F 2 "rosco_m68k:0207_10" H 3650 2400 50  0001 C CNN
F 3 "" H 3650 2400 50  0001 C CNN
	1    3650 2400
	0    -1   -1   0   
$EndComp
$Comp
L rosco_m68k-eagle-import:LED5MM LED?
U 1 1 6161C7B0
P 3650 2700
AR Path="/6161C7B0" Ref="LED?"  Part="1" 
AR Path="/5E53B952/6161C7B0" Ref="LED?"  Part="1" 
AR Path="/60FBFA5C/6161C7B0" Ref="LED?"  Part="1" 
AR Path="/61043B8D/6161C7B0" Ref="LED?"  Part="1" 
AR Path="/6162E38E/6161C7B0" Ref="LED?"  Part="1" 
AR Path="/61622E90/6161C7B0" Ref="LED2"  Part="1" 
F 0 "LED2" H 3900 2800 59  0000 R TNN
F 1 "RED" H 4000 2700 59  0000 R TNN
F 2 "rosco_m68k:LED5MM" H 3650 2700 50  0001 C CNN
F 3 "" H 3650 2700 50  0001 C CNN
	1    3650 2700
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR04
U 1 1 6161F2BF
P 3400 1900
F 0 "#PWR04" H 3400 1750 50  0001 C CNN
F 1 "VCC" H 3417 2073 50  0000 C CNN
F 2 "" H 3400 1900 50  0001 C CNN
F 3 "" H 3400 1900 50  0001 C CNN
	1    3400 1900
	1    0    0    -1  
$EndComp
Wire Wire Line
	3150 2200 3150 2050
Wire Wire Line
	3150 2050 3400 2050
Wire Wire Line
	3400 2050 3400 1900
Wire Wire Line
	3650 2200 3650 2050
Wire Wire Line
	3650 2050 3400 2050
Connection ~ 3400 2050
Wire Wire Line
	4400 3200 3650 3200
Wire Wire Line
	3650 2900 3650 3200
Wire Wire Line
	4400 3300 3150 3300
Wire Wire Line
	3150 2900 3150 3300
Text GLabel 4400 3400 0    50   Output ~ 0
SPICS2
$Comp
L Connector:Conn_01x01_Male J7
U 1 1 6164AE6A
P 4000 5650
F 0 "J7" H 4100 5500 50  0000 C CNN
F 1 "Conn_01x01_Male" H 4108 5740 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x01_P2.54mm_Vertical" H 4000 5650 50  0001 C CNN
F 3 "~" H 4000 5650 50  0001 C CNN
	1    4000 5650
	-1   0    0    1   
$EndComp
Text GLabel 3800 5650 0    50   Input ~ 0
SPICS2
$EndSCHEMATC
