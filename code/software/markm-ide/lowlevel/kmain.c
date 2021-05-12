/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 *
 * Testing low-level ATA routines
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "ata.h"
#include "part.h"

#define START_SECTOR    0
#define NUM_SECTORS     1
#define BUF_SIZE        NUM_SECTORS*512
#define HEX_LINES       NUM_SECTORS*32

void kmain() {
    PartHandle phandle;

    ata_init();

    if (part_init(&phandle, ATA_SLAVE) < 0) {
        printf("Partition init failed\n");
    }


    uint8_t buf[BUF_SIZE];

    if (ata_read(buf, START_SECTOR, NUM_SECTORS, ATA_SLAVE) != NUM_SECTORS) {
        printf("Error reading, read no sectors\n");
    } else {
        int i, j;
        for (i = 0; i < HEX_LINES; i++) {
            printf("%04X -", i*16);
            for (j = 0; j < 16; j++) {
                printf(" %02X", buf[i*16 + j]);
            }

            printf(" - ");

            for (j = 0; j < 16; j++) {
                printf("%c", (buf[i*16 + j] >= ' ' && buf[i*16 + j] <= '~') ? buf[i*16 + j] : '.');
            }

            printf("\n");
        }
    }
}

