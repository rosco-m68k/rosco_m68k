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

#include <stdbool.h>
#include <string.h>

#include "ring_buffer.h"
#include "usbhid.h"
#include "usbinput.h"
#include "buffered_uart.h"

#define DEVICE_TYPE_KEYBOARD        ((0x06))
#define DEVICE_TYPE_MOUSE           ((0x02))

#define SDB_TICKCNT                 ((0x40c))

#ifdef DEBUG_USB_INPUT
#define DEBUGF(...)     printf(__VA_ARGS__)
#else
#define DEBUGF(...)     (void)0
#endif

#define K_BACKSPACE 0x2a
#define K_CAPS      0x39
#define K_RIGHT     0x4f
#define K_LEFT      0x50
#define K_DOWN      0x51
#define K_UP        0x52

#define K_A         0x04
#define K_Z         0x1d

#define M_LSHIFT    0x02
#define M_RSHIFT    0x20
#define M_ANYSHIFT  0x22

static const char usb_to_ascii_unshift_lut[] = {
    0x00, 0x00, 0x00, 0x00,  'a',  'b',  'c',  'd',  'e',  'f',  'g',  'h',  'i',  'j',  'k',  'l', 
     'm',  'n',  'o',  'p',  'q',  'r',  's',  't',  'u',  'v',  'w',  'x',  'y',  'z',  '1',  '2', 
     '3',  '4',  '5',  '6',  '7',  '8',  '9',  '0', 0x0a, 0x1b, 0x08, 0x09, 0x20,  '-',  '=',  '[', 
     ']', '\\', 0x00,  ';', '\'',  '`',  ',',  '.',  '/', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00,  '/',  '*',  '-',  '+', 0x0A,  '1',  '2',  '3',  '4',  '5',  '6',  '7', 
     '8',  '9',  '0',  '.', 0x00, 0x00, 0x00,  '=', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
};

static const char usb_to_ascii_shift_lut[] = {
    0x00, 0x00, 0x00, 0x00,  'A',  'B',  'C',  'D',  'E',  'F',  'G',  'H',  'I',  'J',  'K',  'L', 
     'M',  'N',  'O',  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',  'X',  'Y',  'Z',  '!',  '@', 
     '#',  '$',  '%',  '^',  '&',  '*',  '(',  ')', 0x0a, 0x1b, 0x08, 0x09, 0x20,  '_',  '+',  '{', 
     '}',  '|', 0x00,  ':',  '"',  '~',  '<',  '>',  '?', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00,  '/',  '*',  '-',  '+', 0x0A,  '1',  '2',  '3',  '4',  '5',  '6',  '7', 
     '8',  '9',  '0',  '.', 0x00, 0x00, 0x00,  '=', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
};

static volatile uint32_t *ticks = (uint32_t*)SDB_TICKCNT;

static USBHID hid;
static RingBuffer key_buffer;
static RingBuffer serial_buffer;

// TODO We don't actually need all this space, we could just track the 6 keys
// codes and times separately, but it'd be slower. Might be acceptable
// though (and save us nearly a KiB)...
//
static uint32_t key_times[256];     // 1KiB

static uint8_t  last_keys[6];       // 6KRO with boot protocol

static bool caps;

static inline char map_usb_keycode(uint8_t code, uint8_t modifiers) {
    char result;
    if ((modifiers & M_ANYSHIFT) == 0) {
        result = usb_to_ascii_unshift_lut[code];
    } else {
        result = usb_to_ascii_shift_lut[code];
    }

    if (caps && code >= K_A && code <= K_Z) {     
        code ^= 0x20;
    }

    return result;
}

static void hid_handler(__attribute__((unused)) USBHIDPacket *packet) {
    #ifdef DEBUG
    for (int i = 0; i < packet->payload_len; i++) {
        DEBUGF("0x%02x ", packet->payload[i]);
    }
    printf("\n\n");
    #endif

    uint32_t now = *ticks;    

    if (packet->type == DEVICE_TYPE_KEYBOARD) {
        DEBUGF("Keyboard packet");
        if (packet->payload_len == 8) {
            DEBUGF(" with correct length\n");
            // TODO This is very inefficient, but probably okay for now given small arrays involved....
            //

            // unpress any previously-pressed keys that are no longer pressed
            for (int i = 0; i < 6; i++) {
                uint8_t last_key = last_keys[i];

                if (last_key) {
                    if (memchr(&packet->payload[2], last_key, 6) == NULL) {
                        // key no longer pressed
                        key_times[last_key] = 0;
                    }
                }
            }

            // update key times for newly-pressed keys in packet
            for (int i = 2; i < 8; i++) {
                // unrolled loop, we can do better than this...
                uint8_t this_key = packet->payload[i];

                if (this_key) {
                    if (memchr(last_keys, this_key, 6) == NULL) {
                        // key newly pressed
                        key_times[this_key] = now;
                        char mapped;

                        // handle this key
                        switch (this_key) {
                        case K_CAPS:
                            caps = !caps;
                            break;
                        case K_BACKSPACE:
                            ring_buffer_char(&key_buffer, 0x08);
                            ring_buffer_char(&key_buffer, 0x20);
                            ring_buffer_char(&key_buffer, 0x08);
                            break;
                        case K_LEFT:
                            ring_buffer_char(&key_buffer, 0x1b);
                            ring_buffer_char(&key_buffer, '[');
                            ring_buffer_char(&key_buffer, 'D');
                            break;
                        case K_RIGHT:
                            ring_buffer_char(&key_buffer, 0x1b);
                            ring_buffer_char(&key_buffer, '[');
                            ring_buffer_char(&key_buffer, 'C');
                            break;
                        case K_DOWN:
                            ring_buffer_char(&key_buffer, 0x1b);
                            ring_buffer_char(&key_buffer, '[');
                            ring_buffer_char(&key_buffer, 'B');
                            break;
                        case K_UP:
                            ring_buffer_char(&key_buffer, 0x1b);
                            ring_buffer_char(&key_buffer, '[');
                            ring_buffer_char(&key_buffer, 'A');
                            break;
                        default:
                            mapped = map_usb_keycode(this_key, packet->payload[0]);
                            if (mapped) {
                                DEBUGF("Mapped key 0x%02x to %c\n", this_key, mapped);
                                ring_buffer_char(&key_buffer, mapped);
                            } else {
                                DEBUGF("WARN: unhandled & unmapped key 0x%02x\n", this_key);
                            }
                            break;
                        }
                    }
                }
            }

            // Make a note of the pressed keys for next time around...
            memcpy(last_keys, &packet->payload[2], 6);
        } else {
            DEBUGF(" with bad length - WARN: ignored\n");
        }
    } else {
        DEBUGF("Non keyboard packet!\n");
    }
}

static void handle_repeat() {
    // TODO nothing yet
}

static void usb_input_poll() {
    uint8_t in;
    while (ring_unbuffer_char(&serial_buffer, &in)) {
        usb_hid_process_input(in, &hid);
    }
}

bool usb_input_keyboard_check_char() {
    usb_input_poll();
    handle_repeat();
    return ring_buffer_ready(&key_buffer);
}

char usb_input_keyboard_recv_char() {
    uint8_t in;

    while (!ring_unbuffer_char(&key_buffer, &in)) {
        usb_input_poll();
        handle_repeat();
    }
    
    return (char)in;
}

bool usb_input_init(CharDevice *raw_device) {
    hid.handler = hid_handler;
    serial_buffer.mask = 0x3ff;
    key_buffer.mask = 0x3ff;

    install_interrupt(raw_device, NULL, &serial_buffer);

    return true;
}