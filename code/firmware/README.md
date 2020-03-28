# Firmware & Software

This directory contains various different firmware projects for the
rosco_m68k, including the main **rosco_m68k_v1** serial bootloader 
(the standard firmware that is preinstalled on the board kits).

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| rosco_m68_v1        | Bootloader, loads software via serial (UART)   |
| early_easy68k_tests | Obsolete, Easy68K code used for early testing  |
| old-firmware        | Previous iteration, some code to reuse         |
| rhombus-monitor     | Machine-monitor from Rhombus project *         |

* Rhombus-monitor is ported from the Rhombus project, which is a 
  68020-based minimal m68k system based on Motorola application
  note 1015. It can be found at https://github.com/zenmetsu/rhombus


