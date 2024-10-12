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
 * USB HID Packet Driver
 * ------------------------------------------------------------
 */

#include "usbhid.h"

#ifdef DEBUG_USB_HID
#define DEBUGF(...)     printf(__VA_ARGS__)
#else
#define DEBUGF(...)     (void)0
#endif

void usb_hid_process_input(uint8_t input, USBHID* hid) {
    switch (hid->state) {
    case WAIT_IDENT:
        DEBUGF("  -> 0x%02x [ID]\n", input);
        if (input == 0xfe) {
            hid->state = WAIT_LENGTH_L;
        }
        return;        
    case WAIT_LENGTH_L:
        DEBUGF("  -> 0x%02x [LEN_L]\n", input);
        hid->_scratch = input;
        hid->state = WAIT_LENGTH_H;
        return;
    case WAIT_LENGTH_H:
        DEBUGF("  -> 0x%02x [LEN_H]\n", input);
        hid->current_packet.payload_len = (input << 8) | hid->_scratch;
        hid->state = WAIT_MSGTYPE;
        return;
    case WAIT_MSGTYPE:
        DEBUGF("  -> 0x%02x [MSGTYPE]\n", input);
        hid->current_packet.msgtype = input;
        hid->state = WAIT_TYPE;
        return;
    case WAIT_TYPE:
        DEBUGF("  -> 0x%02x [TYPE]\n", input);
        hid->current_packet.type = input;
        hid->state = WAIT_DEVICE;
        return;
    case WAIT_DEVICE:
        DEBUGF("  -> 0x%02x [DEVICE]\n", input);
        hid->current_packet.device = input;
        hid->state = WAIT_ENDPOINT;
        return;
    case WAIT_ENDPOINT:
        DEBUGF("  -> 0x%02x [ENDPOINT]\n", input);
        hid->current_packet.endpoint = input;
        hid->state = WAIT_VID_L;
        return;
    case WAIT_VID_L:
        DEBUGF("  -> 0x%02x [VID_L]\n", input);
        hid->_scratch = input;
        hid->state = WAIT_VID_H;
        return;
    case WAIT_VID_H:
        hid->current_packet.vid = (input << 8) | hid->_scratch;
        DEBUGF("  -> 0x%02x [VID_H: 0x%04x]\n", input, hid->current_packet.vid);
        hid->state = WAIT_PID_L;
        return;
    case WAIT_PID_L:
        DEBUGF("  -> 0x%02x [PID_L]\n", input);
        hid->_scratch = input;
        hid->state = WAIT_PID_H;
        return;
    case WAIT_PID_H:
        hid->current_packet.pid = (input << 8) | hid->_scratch;
        hid->state = WAIT_PAYLOAD;
        DEBUGF("  -> 0x%02x [PID_H: 0x%04x]\n", input, hid->current_packet.pid);
        return;
    case WAIT_PAYLOAD:
        DEBUGF("  -> 0x%02x [PAYLOAD: len is %d]\n", input, hid->current_packet.payload_len);
        hid->_scratch = 1;
        hid->current_packet.payload[0] = input;

        if (hid->current_packet.payload_len > 1) {
            hid->state = WAIT_MORE_PAYLOAD;
            return;
        }

        hid->state = WAIT_EOP;
        return;
    case WAIT_MORE_PAYLOAD:
        DEBUGF("  -> 0x%02x [PAYLOAD(...): byte %d]\n", input, hid->_scratch);
        hid->current_packet.payload[hid->_scratch++] = input;

        if (hid->_scratch == hid->current_packet.payload_len) {
            hid->state = WAIT_EOP;
        }

        return;
    case WAIT_EOP:
        DEBUGF("  -> 0x%02x [EOP]\n", input);
        if (input == 0x0a) {
            hid->handler(&hid->current_packet);
        } else {
            DEBUGF("WARN: malformed packet discarded\n");
        }

        hid->state = WAIT_IDENT;
        return;
    }
}
