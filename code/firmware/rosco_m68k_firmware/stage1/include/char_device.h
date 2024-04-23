/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2010-2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * C prototypes for char device routines implemented in assembly.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_CHAR_DEVICE_H
#define _ROSCOM68K_CHAR_DEVICE_H

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    uint32_t    data;
    uint32_t    checkptr;
    uint32_t    recvptr;
    uint32_t    sendptr;
    uint32_t    reserved0;
    uint32_t    reserved1;
    uint32_t    reserved2;
    uint16_t    capabilities;
    uint8_t     flags;
    uint8_t     device_type;
} __attribute__((packed)) CharDevice;

uint16_t GET_CHAR_DEVICE_COUNT();
bool GET_CHAR_DEVICE_C(uint8_t num, CharDevice *device);
bool CHAR_DEV_CHECKCHAR_C(CharDevice *device);
char CHAR_DEV_RECVCHAR_C(CharDevice *device);
void CHAR_DEV_SENDCHAR_C(char chr, CharDevice *device);

#endif

