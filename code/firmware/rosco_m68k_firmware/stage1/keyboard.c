/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k keyboard firmware handler
 * ------------------------------------------------------------
 */

#include "machine.h"
#include "char_device.h"

#define CMD_IDENT           ((uint8_t)0xf0)
#define CMD_ACK             ((uint8_t)0xff)
#define IDENT_MODE_ASCII    ((uint8_t)0x01)
#define TIMEOUT_TICKS       20

CharDevice keyboard_device;
static volatile long *ticks = (volatile long *)0x40c;

void INSTALL_KEYBOARD_HANDLERS(void);

static int try_get_char(CharDevice *device) {
    long end = *ticks + 20;

    while (*ticks < end) {
        if (CHAR_DEV_CHECKCHAR_C(device)) {
            return (uint8_t)CHAR_DEV_RECVCHAR_C(device);
        }
    }

    return -1;
}

static bool detect_keyboard(CharDevice *device) {
    // Clear buffer
    while (CHAR_DEV_CHECKCHAR_C(device)) {
        CHAR_DEV_RECVCHAR_C(device);
    }

    // Send "IDENT" command
    CHAR_DEV_SENDCHAR_C(CMD_IDENT, device);

    int chr;
    char *id_str = "rosco_kbd";
    for (int i = 0; i < 9; i++) {
        chr = try_get_char(device);
        if (chr != *id_str++) {
            return false;
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad ident\r\n");
#endif
        }
    }

    chr = try_get_char(device);
    if (chr != IDENT_MODE_ASCII) {
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad mode\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // key count
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad key count\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // led count
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad LED count\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // capabilities
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad capabilities\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr != 0) {     // reserved - must be 0
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad reserved\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr != 0) {     // reserved2 - must be 0
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad reserved 2\r\n");
#endif
        return false;
    }

    chr = try_get_char(device);
    if (chr != CMD_ACK) {   // required ack
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Bad ack\r\n");
#endif
        return false;
    }

#ifdef DEBUG_KEYBOARD_DETECT
    FW_PRINT_C("Detect success\r\n");
#endif
    return true;
}

void initialize_keyboard() {
    if (GET_CHAR_DEVICE_COUNT() < 2) {
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("ERROR: Insufficient devices\r\n");
#endif
        return;
    }

    if (!GET_CHAR_DEVICE_C(1, &keyboard_device)) {
#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("ERROR: Unable to get device\r\n");
#endif
        return;
    }

    if (detect_keyboard(&keyboard_device)) {
        // setup keyboard EFPs...
        INSTALL_KEYBOARD_HANDLERS();

#ifdef DEBUG_KEYBOARD_DETECT
        FW_PRINT_C("Found rosco_m68k keyboard...\r\n");
    } else {
        FW_PRINT_C("No keyboard detected\r\n");
#endif
    }
}
