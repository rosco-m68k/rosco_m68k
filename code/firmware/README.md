# Firmware & Software

This directory contains various different firmware projects for the
rosco_m68k, including the current **v1.3** firmware, as well as the 
legacy 1.2, 1.1 and 1.0 versions. 

The r1 firmware is a **rosco_m68k_v1** serial bootloader that uses 
Kermit. Later versions also support loading from SD card, as well 
as various standard peripherals (the V9958 board, DUART etc).

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| rosco_m68k_v1.3     | Full-featured firmware for all r1.x boards     | 
| rosco_m68k_v1.2     | Improved serial bootloader for r1.2 boards     |
| rosco_m68k_v1.1     | Improved serial bootloader for r1 boards       |
| rosco_m68_v1        | Bootloader, loads software via serial (UART)   |
| early_easy68k_tests | Obsolete, Easy68K code used for early testing  |
| old-firmware        | Previous iteration, some code to reuse         |
| rhombus-monitor     | Machine-monitor from Rhombus project *         |

* Rhombus-monitor is ported from the Rhombus project, which is a 
  68020-based minimal m68k system based on Motorola application
  note 1015. It can be found at https://github.com/zenmetsu/rhombus


