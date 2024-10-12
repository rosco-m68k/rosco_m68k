/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k OSP
 * See top-level LICENSE.md for licence information.
 *
 * Experimental USB HID with CH559
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "machine.h"

#include "usbinput.h"

extern CharDevice DEVICE_BLOCKS[];

void INSTALL_USB_HID_HANDLERS(void);

bool init_usb_hid_input_subsys(void) {
    // TODO should be checking we have the right number of blocks etc...
    //

    if (DEVICE_BLOCKS[1].device_type != 0x03) {
        return false;
    }

    if (!usb_input_init(&DEVICE_BLOCKS[1])) {
        return false;
    }

    INSTALL_USB_HID_HANDLERS();

    return true;
}

