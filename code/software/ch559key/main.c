/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|          software
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k OSP
 * See top-level LICENSE.md for licence information.
 *
 * PoC for USB HID with CH559
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <rosco_m68k/machine.h>

#include "usbinput.h"

static CharDevice device;

int kmain() {

    if (!mcCheckDeviceSupport()) {
        printf("No device support; Bailing\n");
        return 1;
    }

    printf("We have %d device(s)\n", mcGetDeviceCount());

    if (mcGetDeviceCount() < 2) {
        printf("Insufficient devices (need 2, found %d)\n", mcGetDeviceCount());
        return 1;
    }

    if (!mcGetDevice(1, &device)) {
        printf("Failed to get keyboard device; Bailing\n");
        return 1;
    }

    printf("Got UART B device type 0x%02x at 0x%08lx\n", device.device_type, device.data);
    printf("Recvptr = 0x%08lx : Checkptr = 0x%08lx\n", device.recvptr, device.checkptr);

    if (!usb_input_init(&device)) {
        printf("Failed to init USB device; Bailing\n");
        return 1;
    }

    printf("Read loop...\n");

    while (true) {
        if (usb_input_keyboard_check_char()) {
            printf("%c", usb_input_keyboard_recv_char());
        }
    }
}

