# POC / Demo of BBSPI and BBSD libraries.

This code is where the bitbanged SPI and SD (BBSPI and BBSD) libraries are being
developed. It may end up being a demo of those libraries once their code moves 
into either libs or (more likely) the firmware.

Expected hookup on J5:

* CS   - Pin 1
* SCK  - Pin 3
* MOSI - Pin 5
* MISO - Pin 7

N.B. This is tested with a sample size of exactly one SD card. YMMV!

TODOS:

* Lots of TODOs in the code
* Everything returns bool. This is not helpful when debugging - use codes instead
* SD code could be tightened up considerably
* ... and lots more most likely :D
