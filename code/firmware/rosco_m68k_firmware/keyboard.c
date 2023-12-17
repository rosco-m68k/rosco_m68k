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

    int chr = try_get_char(device);
    if (chr != 'r') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'o') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 's') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'c') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'o') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != '_') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'k') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'b') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != 'd') {
        return false;
    }

    chr = try_get_char(device);
    if (chr != IDENT_MODE_ASCII) {
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // key count
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // led count
        return false;
    }

    chr = try_get_char(device);
    if (chr == -1) {    // capabilities
        return false;
    }

    chr = try_get_char(device);
    if (chr != 0) {     // reserved - must be 0
        return false;
    }

    chr = try_get_char(device);
    if (chr != 0) {     // reserved2 - must be 0
        return false;
    }

    chr = try_get_char(device);
    if (chr != CMD_ACK) {   // required ack
        return false;
    }

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