# Rosco_m68k GPIO ILI9341 TFT LCD Module Example

Ideally, this should describe this project in more detail, this is currently a skeleton.

## Building

```bash
make clean all
```

This will build `lcd-ili9341.bin`, which can be uploaded to a rosco_m68k
board with standard firmware.

The `Makefile` also makes some other potentially useful outputs:

* `lcd-ili9341.elf` the program binary along with additional symbol and debugging information (useful when using other GNU tools vs a raw binary)
* `lcd-ili9341.dis` a disassembly of the program (but since it is interspersed with the corresponding source code, it is somewhat more understandable than a raw disassembly)
* `lcd-ili9341.sym` lists symbols used in the program and their address (or value for constants)
* `lcd-ili9341.map` similar to the SYM file this shows where everything was placed in memory by the linker

Here are the connections I used with [this LCD module](http://www.lcdwiki.com/2.2inch_SPI_Module_ILI9341_SKU:MSP2202) (adapt for other modules):

| LCD Module | Label    | Description                  | Rosco       |
| :--------: | :------- | :--------------------------- | :---------- |
| 1          | VCC      | 5V / 3.3V power input        | VCC         |
| 2          | GND      | Ground                       | GND         |
| 3          | CS       | Chip select (active low)     | J5-P1 GPIO1 |
| 4          | RESET    | LCD reset (active low)       | J3-P36 RESET|
| 5          | DC/RS    | Data/command register select | J5-P9 GPIO5 |
| 6          | COPI     | SPI data write to LCD        | J5-P5 GPIO3 |
| 7          | SCK      | SPI clock signal             | J5-P3 GPIO2 |
| 8          | LED      | LED backlight pin            | VCC         |
| 9          | CIPO     | SPI data read from LCD       | J5-P7 GPIO4 |

(Check the documentation for your module, there are many varieties.)

## Makefile targets

If you're feeling adventurous (and have `ckermit` installed), you
can try:

```bash
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).
