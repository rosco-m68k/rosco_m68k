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

#ifndef __ROSCO_USB_HID_H
#define __ROSCO_USB_HID_H

#include <stdio.h>
#include <stdint.h>

typedef struct {
    uint8_t     device;
    uint8_t     msgtype;
    uint8_t     type;
    uint8_t     endpoint;
    uint16_t    vid;
    uint16_t    pid;
    uint16_t    payload_len;
    uint8_t     payload[0x40];
} USBHIDPacket;

typedef void (*USBHIDPacketHandler)(USBHIDPacket*);

typedef enum {
    WAIT_IDENT,
    WAIT_LENGTH_L,
    WAIT_LENGTH_H,
    WAIT_MSGTYPE,
    WAIT_TYPE,
    WAIT_DEVICE,
    WAIT_ENDPOINT,
    WAIT_VID_L,
    WAIT_VID_H,
    WAIT_PID_L,
    WAIT_PID_H,
    WAIT_PAYLOAD,
    WAIT_MORE_PAYLOAD,
    WAIT_EOP,
} USBHIDState;

typedef struct {
    USBHIDState         state;
    USBHIDPacket        current_packet;
    USBHIDPacketHandler handler;
    uint8_t             _scratch;
} USBHID;

void usb_hid_process_input(uint8_t input, USBHID* hid);

#endif