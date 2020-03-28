# Firmware & Software

This directory contains various different firmware and software programs
for the rosco_m68k. 

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| Toolchain.md        | Instructions for building a cross GCC toolchain|
| early_easy68k_tests | Obsolete, Easy68K code used for early testing  |
| serial-receive      | Bootloader, loads software via serial (UART)   |
| poc-kernel          | POC "kernel", compatible with `serial-receive` |
| rosco_m68k_v1       | Eventually will become the "main" firmware     |
| rhombus-monitor     | Machine-monitor from Rhombus project *         |
| shared              | Files shared by the above (equates.S etc)      |

* Rhombus-monitor is ported from the Rhombus project, which is a 
  68020-based minimal m68k system based on Motorola application
  note 1015. It can be found at https://github.com/zenmetsu/rhombus


