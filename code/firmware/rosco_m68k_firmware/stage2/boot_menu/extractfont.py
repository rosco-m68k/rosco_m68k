# /*
#  *------------------------------------------------------------
#  *                                  ___ ___ _
#  *  ___ ___ ___ ___ ___       _____|  _| . | |_
#  * |  _| . |_ -|  _| . |     |     | . | . | '_|
#  * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
#  *                     |_____|          firmware
#  * ------------------------------------------------------------
#  * Copyright (c)2024 The rosco_m68k Open Source Project
#  * See top-level LICENSE.md for licence information.
#  *
#  * PNG to font for concept boot screen
#  * ------------------------------------------------------------
#  */

import imageio.v2 as iio

i = iio.imread('bizcat.png')

print("#ifndef __FONT_H")
print("#define __FONT_H")
print("")
print("#include <stdint.h>")
print("")
print("#define FONT_WIDTH      8")
print("#define FONT_HEIGHT     16")
print("")
print("static const uint8_t FONT[] = {")

for cy in range(16):
    for cx in range(16):
        print("")
        sx = 4 + (cx * 16)
        sy = 4 + (cy * 32)

        for y in range(sy, sy+32, 2):
            print("    0b", end="")
            for x in range(sx, sx+16, 2):
                if 255 in i[y][x]:
                    print("1", end="")
                else:
                    print("0", end="")

            print(",")

print("};")
print("#endif")


