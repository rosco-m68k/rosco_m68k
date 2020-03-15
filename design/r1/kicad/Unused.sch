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
	3250 4250 3150 4250
Wire Wire Line
	3150 4250 3150 4850
Wire Wire Line
	3150 4850 3150 5450
Wire Wire Line
	3150 5450 3150 5950
Wire Wire Line
	3150 5950 3150 6150
Wire Wire Line
	3450 5950 3150 5950
Wire Wire Line
	3450 6150 3150 6150
Wire Wire Line
	3250 4850 3150 4850
Wire Wire Line
	3250 5450 3150 5450
Connection ~ 3150 5950
Connection ~ 3150 6150
Connection ~ 3150 4850
Connection ~ 3150 5450
$Comp
L rosco_m68k-eagle-import:7401N IC9
U 4 1 F64B6C48
P 3750 6050
AR Path="/F64B6C48" Ref="IC9"  Part="4" 
AR Path="/5E53BCCF/F64B6C48" Ref="IC9"  Part="4" 
F 0 "IC9" H 3850 6175 59  0000 L BNN
F 1 "74LS01N" H 3850 5850 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 3750 6050 50  0001 C CNN
F 3 "" H 3750 6050 50  0001 C CNN
	4    3750 6050
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 4 1 46D5F877
P 3650 4250
AR Path="/46D5F877" Ref="IC7"  Part="4" 
AR Path="/5E53BCCF/46D5F877" Ref="IC7"  Part="4" 
F 0 "IC7" H 3750 4375 59  0000 L BNN
F 1 "7404N" H 3750 4050 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 3650 4250 50  0001 C CNN
F 3 "" H 3650 4250 50  0001 C CNN
	4    3650 4250
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 5 1 46D5F873
P 3650 4850
AR Path="/46D5F873" Ref="IC7"  Part="5" 
AR Path="/5E53BCCF/46D5F873" Ref="IC7"  Part="5" 
F 0 "IC7" H 3750 4975 59  0000 L BNN
F 1 "7404N" H 3750 4650 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 3650 4850 50  0001 C CNN
F 3 "" H 3650 4850 50  0001 C CNN
	5    3650 4850
	1    0    0    -1  
$EndComp
$Comp
L rosco_m68k-eagle-import:7404N IC7
U 6 1 46D5F87F
P 3650 5450
AR Path="/46D5F87F" Ref="IC7"  Part="6" 
AR Path="/5E53BCCF/46D5F87F" Ref="IC7"  Part="6" 
F 0 "IC7" H 3750 5575 59  0000 L BNN
F 1 "7404N" H 3750 5250 59  0001 L BNN
F 2 "rosco_m68k:DIL14" H 3650 5450 50  0001 C CNN
F 3 "" H 3650 5450 50  0001 C CNN
	6    3650 5450
	1    0    0    -1  
$EndComp
NoConn ~ 4050 4250
NoConn ~ 4050 4850
NoConn ~ 4050 5450
NoConn ~ 4050 6050
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
Text Notes 12300 7750 0    59   ~ 0
Copyright ©2019-2020 Ross Bamford and Contributors.\nOpen Source Hardware licenced under CERN Open Hardware Licence. \nSee https://github.com/roscopeco/rosco_m68k/blob/master/LICENCE.hardware.txt\nOSHWA UK000006 (https://certification.oshwa.org/uk000006.html)\n
Text Notes 12650 8300 0    59   ~ 0
UNUSED GATES & MISC
Text Notes 15900 8450 0    59   ~ 0
1
$Comp
L power:GND #PWR?
U 1 1 5FD5F919
P 3150 7200
F 0 "#PWR?" H 3150 6950 50  0001 C CNN
F 1 "GND" H 3155 7027 50  0000 C CNN
F 2 "" H 3150 7200 50  0001 C CNN
F 3 "" H 3150 7200 50  0001 C CNN
	1    3150 7200
	1    0    0    -1  
$EndComp
Wire Wire Line
	3150 6150 3150 7200
$EndSCHEMATC
