/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         libraries
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k OSP
 * See top-level LICENSE.md for licence information.
 *
 * USB HID Input Driver
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_USB_INPUT_H
#define __ROSCO_USB_INPUT_H

#include <rosco_m68k/machine.h>

typedef enum {
    USB_INPUT_EVENT_KEY,
    USB_INPUT_EVENT_MOUSE,
} USBInputEventType;

typedef struct {
    USBInputEventType       type;
    union {
        struct {
            uint8_t         placeholder;
        } key;
        struct {
            uint8_t         placeholder;
        } mouse;
    } event;
} USBInputEvent;

bool usb_input_init(CharDevice *raw_device);
bool usb_input_keyboard_check_char();
char usb_input_keyboard_recv_char();

#endif