EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr User 16992 9063
encoding utf-8
Sheet 7 7
Title ""
Date "2020-02-25"
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Wire Wire Line
	8400 900  8300 900 
Wire Wire Line
	8300 900  8300 1500
Wire Wire Line
	8300 1500 8300 2100
Wire Wire Line
	8300 2100 8300 2600
Wire Wire Line
	8300 2600 8300 2800
Wire Wire Line
	8300 2800 8300 5200
Wire Wire Line
	8600 2600 8300 2600
Wire Wire Line
	8600 2800 8300 2800
Wire Wire Line
	8400 1500 8300 1500
Wire Wire Line
	8400 2100 8300 2100
Connection ~ 8300 2600
Connection ~ 8300 2800
Connection ~ 8300 1500
Connection ~ 8300 2100
Text GLabel 8400 900  0    10   BiDi ~ 0
GND
$Comp
L rosco_m68k-eagle-import:A3L-LOC #FRAME6
U 1 1 DFBB3BDD
P -50 6900
AR Path="/DFBB3BDD" Ref="#FRAME6"  Part="1" 
AR Path="/5E53BCCF/DFBB3BDD" Ref="#FRAME6"  Part="1" 
F 0 "#FRAME6" H -50 6900 50  0001 C CNN
F 1 "BOOT line generator" H -50 6900 50  0001 C CNN
F 2 "" H -50 6900 50  0001 C CNN
F 3 "" H -50 6900 50  0001 C CNN
	1    -50  6900
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:GND #SUPPLY29
U 1 1 0331A01D
P 8300 5300
AR Path="/0331A01D" Ref="#SUPPLY29"  Part="1" 
AR Path="/5E53BCCF/0331A01D" Ref="#SUPPLY029"  Part="1" 
F 0 "#SUPPLY029" H 8300 5300 50  0001 C CNN
F 1 "GND" H 8225 5175 59  0000 L BNN
F 2 "" H 8300 5300 50  0001 C CNN
F 3 "" H 8300 5300 50  0001 C CNN
	1    8300 5300
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7401N IC9
U 4 1 F64B6C48
P 8900 2700
AR Path="/F64B6C48" Ref="IC9"  Part="4" 
AR Path="/5E53BCCF/F64B6C48" Ref="IC9"  Part="4" 
F 0 "IC9" H 9000 2825 59  0000 L BNN
F 1 "74LS01N" H 9000 2500 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 8900 2700 50  0001 C CNN
F 3 "" H 8900 2700 50  0001 C CNN
	4    8900 2700
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 4 1 46D5F877
P 8800 900
AR Path="/46D5F877" Ref="IC7"  Part="4" 
AR Path="/5E53BCCF/46D5F877" Ref="IC7"  Part="4" 
F 0 "IC7" H 8900 1025 59  0000 L BNN
F 1 "7404N" H 8900 700 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 8800 900 50  0001 C CNN
F 3 "" H 8800 900 50  0001 C CNN
	4    8800 900 
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 5 1 46D5F873
P 8800 1500
AR Path="/46D5F873" Ref="IC7"  Part="5" 
AR Path="/5E53BCCF/46D5F873" Ref="IC7"  Part="5" 
F 0 "IC7" H 8900 1625 59  0000 L BNN
F 1 "7404N" H 8900 1300 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 8800 1500 50  0001 C CNN
F 3 "" H 8800 1500 50  0001 C CNN
	5    8800 1500
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 6 1 46D5F87F
P 8800 2100
AR Path="/46D5F87F" Ref="IC7"  Part="6" 
AR Path="/5E53BCCF/46D5F87F" Ref="IC7"  Part="6" 
F 0 "IC7" H 8900 2225 59  0000 L BNN
F 1 "7404N" H 8900 1900 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 8800 2100 50  0001 C CNN
F 3 "" H 8800 2100 50  0001 C CNN
	6    8800 2100
	1    0    0    -1  
$EndComp
Text Notes 12900 7900 0    170  ~ 0
UNUSED\nGATES
NoConn ~ 9200 900 
NoConn ~ 9200 1500
NoConn ~ 9200 2100
NoConn ~ 9200 2700
Text Notes 10150 1200 0    50   ~ 0
In KiCad, unused pins must have the "No Connect" flag.\nIf the do not have this "cross", then ERC will generate errors.
$Comp
L Mechanical:MountingHole H1
U 1 1 5F42C229
P 2350 4350
F 0 "H1" H 2350 4550 50  0000 C CNN
F 1 "MountingHole" H 2350 4475 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 2350 4350 50  0001 C CNN
F 3 "~" H 2350 4350 50  0001 C CNN
	1    2350 4350
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H2
U 1 1 5F42C338
P 2350 4700
F 0 "H2" H 2350 4900 50  0000 C CNN
F 1 "MountingHole" H 2350 4825 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 2350 4700 50  0001 C CNN
F 3 "~" H 2350 4700 50  0001 C CNN
	1    2350 4700
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H3
U 1 1 5F42C57E
P 2350 5050
F 0 "H3" H 2350 5250 50  0000 C CNN
F 1 "MountingHole" H 2350 5175 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 2350 5050 50  0001 C CNN
F 3 "~" H 2350 5050 50  0001 C CNN
	1    2350 5050
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H4
U 1 1 5F42C79A
P 2350 5400
F 0 "H4" H 2350 5600 50  0000 C CNN
F 1 "MountingHole" H 2350 5525 50  0000 C CNN
F 2 "MountingHole:MountingHole_3.2mm_M3" H 2350 5400 50  0001 C CNN
F 3 "~" H 2350 5400 50  0001 C CNN
	1    2350 5400
	1    0    0    -1  
$EndComp
Text Notes 3150 4450 0    50   ~ 0
2020-02-25\nI've added some mounting holes here.\nAdd them to the PCB if you like ...
$EndSCHEMATC
