# rosco_m68k Xosera XANSI Console Reference

This is a reference for terminal control sequences supported by the rosco_m68k Xosera XANSI console driver (which can be included
in the 64K or 1MB rosco_m68k firmware and used automatically when Xosera hardware is detected at boot). These represent a largely a
compatible superset of VT100, ANSI and other common terminal codes (as adapted to Xosera).  However, there are also a number of
rosco_m68k XANSI specific extensions to support rosco_m68k and Xosera (flagged with EXTENSION).

## Control Characters

| Character      | Hex  | Name | Description                                                               |
| -------------- | ---- | ---- | ------------------------------------------------------------------------- |
| `\a` or `^G`   | 0x07 | BEL  | alert (visual bell, reverses screen momentarily)                          |
| `\b` or `^H`   | 0x08 | BS   | backspace, move cursor left, stops at left margin                         |
| `\t` or `^I`   | 0x09 | HT   | tab, move to next 8 col. tab or next line EXTENSION (VT100 doesn't wrap)  |
| `\n` or `^J`   | 0x0A | LF   | line feed, cursor down, scrolls up at bottom (also does CR if NEWLINE on) |
| `\v` or `^K`   | 0x0B | VT   | vertical tab, cursor up, scrolls down at top EXTENSION (LF on VT100)      |
| `\f` or `^L`   | 0x0C | FF   | form feed, clear screen, home cursor EXTENSION (LF on VT100)              |
| `\r` or `^M`   | 0x0D | CR   | carriage return (move to left margin only)                                |
| `\x18` or `^X` | 0x18 | CAN  | terminate current CSI or ESC sequence, otherwise ignored                  |
| `\x1A` or `^Z` | 0x1A | SUB  | terminate current CSI or ESC sequence, otherwise ignored                  |
| `\x1B` or `^[` | 0x1B | ESC  | ESC sequence introducer                                                   |
| `\x9B`         | 0x9B | CSI  | 8-bit CSI sequence introducer (equivalent to "ESC`[`" sequence)           |

EXTENSION: When PASSTHROUGH on ("CSI`8m`", aka HIDDEN attribute), all characters will be printed as graphical characters instead of
being interpreted except for ESC and CSI introducers (but these will also be printed when sent twice).  To print the NUL character
('\0' or 0x00), you must use PRINTCHAR (as it is used to terminate the PRINT or PRINTLN string).

When the PASSTHROUGH mode is not enabled, other control charaters not specified above are ignored with no effect.

## ESC Sequences

| Sequence | Name  | Description                                                               |
| -------- | ----- | ------------------------------------------------------------------------- |
| ESC`[`   | CSI   | CSI sequence introducer (equivalent to 8-bit "`\x9b`" CSI)                |
| ESC`c`   | RIS   | reset initial settings EXTENSION restores Xosera text mode                |
| ESC`7`   | DECSC | save cursor position                                                      |
| ESC`8`   | DECRC | restore saved cursor position                                             |
| ESC`(`   | G0    | VT220 font EXTENSION: Xosera font 0 (ST 8x16 default)                     |
| ESC`)`   | G1    | VT220 font EXTENSION: Xosera font 1 (ST 8x8)                              |
| ESC`*`   | G2    | VT220 font EXTENSION: Xosera font 2 (PC 8x8)                              |
| ESC`+`   | G3    | VT220 font EXTENSION: Xosera font 3 (default same as font 0)              |
| ESC`D`   | IND   | move cursor down, scroll at bottom (like LF regardless of NEWLINE mode)   |
| ESC`M`   | RI    | move cursor up, scroll at top                                             |
| ESC`E`   | NEL   | next line (like CR + LF)                                                  |
| ESC`Z`   | DA    | send VT101 identifier reply (older sequence, replies with "ESC`[?1;0c`" ) |

NOTE: Only single character ESC sequences are supported (ESC and one additional character).  This is different than some terminals
for codes G0 - G3 (which may take another "nationality" code character that is not supported).

Other sequences not specified above will terminate ESC mode and are ignored with no effect.

## CSI Sequences

| Sequence         | Name            | Description                                                                                    |
| ---------------- | --------------- | ---------------------------------------------------------------------------------------------- |
| CSI _n_`A`       | CUU             | cursor up, _n_ times (no scroll)                                                               |
| CSI _n_`B`       | CUD             | cursor down, _n_ times (no scroll)                                                             |
| CSI _n_`C`       | CUF             | cursor right, _n_ times (no scroll)                                                            |
| CSI _n_`D`       | CUB             | cursor left, _n_ times (no scroll)                                                             |
| CSI _r_`;`_c_`H` | CUP             | cursor home / position (_r_ row, _c_ column, starting at 1, home default)                      |
| CSI _r_`;`_c_`f` | HVP             | cursor home / position (_r_ row, _c_ column, starting at 1, home default)                      |
| CSI`?3h`         | DECCOLM 132     | 132 columns EXTENSION  106 column "wide" 16:9 video mode (848x480)                             |
| CSI`?3l`         | DECCOLM 80      | 80 columns EXTENSION  80 column "narrow" 4:3 video mode (640x480)                              |
| CSI`?5h`         | DECSCNM on      | screen reverse EXTENSION swap default fore/back (persistant)                                   |
| CSI`?5l`         | DECSCNM off     | screen normal  EXTENSION swap default fore/back (persistant)                                   |
| CSI`?7h`         | DECAWM on       | autowrap mode on (wrap cursor or scroll at right margin, default)                              |
| CSI`?7l`         | DECAWM off      | autowrap mode off (cursor stops at right margin)                                               |
| CSI`?12h`        | ATT160 blink    | blinking inverse cursor (blinks every ~1/2 second, default)                                    |
| CSI`?12l`        | ATT160 no blink | non-blinking inverse cursor                                                                    |
| CSI`?20h`        | LMN on          | newline mode on, LF also does CR                                                               |
| CSI`?20l`        | LMN off         | newline mode off, LF only (default)                                                            |
| CSI`?25h`        | DECTCEM on      | show cursor when waiting for input (default)                                                   |
| CSI`?25l`        | DECTCEM off     | do not show any cursor                                                                         |
| CSI`5n`          | DSR             | report terminal "OK" status with "ESC`[0n`                                                     |
| CSI`6n`          | CPR             | report cursor position "ESC`[`_r_`;`_c_`R`" _r_ is row, _c_ is column                          |
| CSI _n_`c`       | DA              | report device attributes, depending on _n_ (see next entries)                                  |
| CSI`0c`          | VT101 DA ID     | 0 reports VT101 ID "ESC`[?1;0c`"                                                               |
| CSI`68c`         | XANSI DA ID     | 68 reports XANSI ID "ESC`[?68;`_v_`;`_i_`;`_r_`c`" EXTENSION: Xosera ver _v_._i_ XANSI rev _r_ |
| CSI`s`           | SCP             | save cursor position (ANSI version)                                                            |
| CSI`u`           | RCP             | restore saved cursor position (ANSI version)                                                   |
| CSI`J`           | ED              | erase down from cursor line to end of screen                                                   |
| CSI`1J`          | ED              | erase up from cursor line to start of screen                                                   |
| CSI`2J`          | ED              | erase whole screen (NOTE: faithful to DEC VT101, cursor does not move)                         |
| CSI`K`           | EL              | erase from cursor to end of line (inclusive)                                                   |
| CSI`1K`          | EL              | erase from cursor to start of line (inclusive)                                                 |
| CSI`2K`          | EL              | erase from whole cursor line (inclusive)                                                       |
| CSI _n_`m`       | SGR             | set graphic rendition depending on _n_ (see table below), can be combined with `;`             |

Other sequences not specified above will terminate CSI mode and are ignored with no effect.

Numeric parameters for the above (represented in _italics_) are in ASCII decimal with multiple values seperated with a semicolon
("`;`") and if omitted typically default to 0 (except for cursor row and column, which default to 1).

## Set Graphic Rendition Attributes

| SGR Number                        | Name                    | Description                                                   |
| --------------------------------- | ----------------------- | ------------------------------------------------------------- |
| `0`                               | reset                   | reset all attributes and set default color                    |
| `1`                               | bright                  | select bright colors (8-15)                                   |
| `2`                               | dim                     | select bright colors (0-7)                                    |
| `7`                               | reverse                 | swap foreground / background colors                           |
| `8`                               | hidden (pass-through)   | EXTENSION: control character graphic pass-through             |
| `39`                              | def forecolor           | select default forground color                                |
| `30` - `37`                       | foreground color        | select foreground color (30-37 for 0-7)                       |
| `38;5;`_n_                        | new def forecolor       | set new persistant default forground color _n_ (0-15)         |
| `49`                              | def backcolor           | select default background color                               |
| `40` - `47`                       | background color        | select background color (40-47 for 0-7)                       |
| `48;5;`_n_                        | new def backcolor       | set new persistant default background color _n_ (0-15)        |
| `68`                              | rosco_m68k              | EXTENSION: rosco_m68k Xosera XANSI commands (see below)       |
| `68;000;1;`_v_`m`                 | vram_addr =_v_          | Xosera VRAM address for XANSI text screen start               |
| `68;000;2;`_v_`m`                 | line_len =_v_           | text columns (default 0 = calculate for video mode)           |
| `68;000;3;`_v_`m`                 | lines_high =_v_         | text rows (default 0 = calculate for video mode)              |
| `68;010;`_n_`;`_r_`;`_g_`;`_b_`m` | COLOR_MEM[_n_] =_rgb_   | palette entry _n_&nbsp;(0-255)&nbsp;_r_,_g_,_b_ (each 0-255)  |
| `68;012;`_n_`;`_v_`m`             | TILE_CTRL[_n_] =_v_     | Xosera TILE_CTRL 0-65535 word for fonts 0-3 (G0-G3)           |
| `68;020;16;`_v_`m`                | GFX_CTRL =_v_           | Xosera GFX_CTRL 0-65535 word for XANSI graphics mode          |
| `68;030;1;`_v_`m`                 | cursor_glyph =_v_       | 0-65535 word for cursor attributes + glyph (if non zero mask) |
| `68;030;2;`_v_`m`                 | cursor_mask =_v_        | 0-65535 word mask for cursor_glyph (0 = unused, default)      |
| `90` - `97`                       | bright foreground color | select bright foreground color (90-97 for 8-15)               |
| `100` - `107`                     | bright background color | select bright background color (100-107 for 8-15)             |

Other SGR values not specified above will be ignored with no effect.

Numeric parameters for the above (represented in italics) are in ASCII decimal with multiple values seperated with a semicolon
(";") and if omitted typically default to 0 (e.g., "ESC`[m`" will reset attributes).

NOTE: "Bright" and "dim" above assumes default ANSI palette where colors 0-7 are considered dim and colors 8-15 are considered bright.
