# POC / Demo of BBSPI and BBSD libraries.

This code is where the bitbanged SPI and SD (BBSPI and BBSD) libraries are being
developed. It may end up being a demo of those libraries once their code moves 
into either libs or (more likely) the firmware.

Expected hookup on J5:

* CS   - Pin 1
* SCK  - Pin 3
* MOSI - Pin 5
* MISO - Pin 7

Your SD card must be FAT formatted, and have a file ROSCODE1.BIN in the root
directory - this should be a rosco_m68k binary (e.g. one of the example 
programs).

This can be compiled either as a burn-in cyclic test program (which will not
run the program loaded from the SD card) or as a loader (which will).

The burn-in test will repeatedly load the binary in a loop, printing a 
running total of the number of times it succeeded vs failed in various ways.

The loader will load ROSCODE1.BIN and, if successful, run the program.
 
