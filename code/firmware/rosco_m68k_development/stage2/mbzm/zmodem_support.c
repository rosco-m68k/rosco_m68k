/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2021 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * ZMODEM glue for stage 2 loader
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "rtlsupport.h"
#include "serial.h"
#include "printf.h"
#include "zmodem.h"

#define PRINTF printf
#define FPRINTF(...)

// Spec says a data packet is max 1024 bytes, but add some headroom...
#define DATA_BUF_LEN    2048

extern void mcPrint(char *str);

extern uint8_t *kernel_load_ptr;
static uint8_t *current_load_ptr;

/*
 * Implementation-defined receive character function.
 */
ZRESULT zm_recv() {
    return RECVCHAR();
}

/*
 * Implementation-defined send character function.
 */
ZRESULT zm_send(uint8_t chr) {
    SENDCHAR(chr);
    return OK;
}

int zm_receive_kernel() {
    char *rzr_buf[4];
    uint8_t data_buf[DATA_BUF_LEN];
    uint16_t count;
    uint32_t received_data_size = 0;
    ZHDR hdr;

    current_load_ptr = kernel_load_ptr;

    if (zm_await("rz\r", (char*) rzr_buf, 4) == OK) {
        DEBUGF("Got rzr...\n");

        while (true) {
startframe: DEBUGF("\n====================================\n");
            uint16_t result = zm_await_header(&hdr);

            switch (result) {
            case CANCELLED:
                FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                return 0;
            case OK:
                DEBUGF("Got valid header\n");

                switch (hdr.type) {
                case ZRQINIT:
                case ZEOF:
                    DEBUGF("Is ZRQINIT or ZEOF\n");

                    result = zm_send_flags_hdr(ZRINIT, CANOVIO | CANFC32, 0, 0,
                            0);

                    if (result == CANCELLED) {
                        FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                        return 0;
                    } else if (result == OK) {
                        DEBUGF("Send ZRINIT was OK\n");
                    } else if (result == CLOSED) {
                        FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                        return 0;
                    }

                    continue;

                case ZFIN:
                    DEBUGF("Is ZFIN\n");

                    result = zm_send_pos_hdr(ZFIN, 0);

                    if (result == CANCELLED) {
                        FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                        return 0;
                    } else if (result == OK) {
                        DEBUGF("Send ZFIN was OK\n");
                    } else if (result == CLOSED) {
                        FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                    }

                    PRINTF("Transfer complete; Received %0ld byte(s)\n", received_data_size);
                    return 0;

                case ZFILE:
                    DEBUGF("Is ZFILE\n");

                    switch (hdr.flags.f0) {
                    case 0: /* no special treatment - default to ZCBIN */
                    case ZCBIN:
                        DEBUGF("--> Binary receive\n");
                        break;
                    case ZCNL:
                        DEBUGF("--> ASCII Receive; Fix newlines (IGNORED - NOT SUPPORTED)\n");
                        break;
                    case ZCRESUM:
                        DEBUGF("--> Resume interrupted transfer (IGNORED - NOT SUPPORTED)\n");
                        break;
                    default:
                        FPRINTF(stderr, "WARN: Invalid conversion flag [0x%02x] (IGNORED - Assuming Binary)\n", hdr.flags.f0);
                    }

                    count = DATA_BUF_LEN;
                    result = zm_read_data_block(data_buf, &count);
                    DEBUGF("Result of data block read is [0x%04x] (got %d character(s))\n", result, count);

                    if (result == CANCELLED) {
                        FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                        return 0;
                    } else if (!IS_ERROR(result)) {
                        PRINTF("Receiving file: '%s'\n", data_buf);

                        result = zm_send_pos_hdr(ZRPOS, received_data_size);

                        if (result == CANCELLED) {
                            FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                            return 0;
                        } else if (result == OK) {
                            DEBUGF("Send ZRPOS was OK\n");
                        } else if (result == CLOSED) {
                            FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                            return 0;
                        }
                    }

                    // TODO care about XON that will follow?

                    continue;

                case ZDATA:
                    DEBUGF("Is ZDATA\n");

                    while (true) {
                        count = DATA_BUF_LEN;
                        result = zm_read_data_block(data_buf, &count);
                        DEBUGF("Result of data block read is [0x%04x] (got %d character(s))\n", result, count);

                        if (result == CANCELLED) {
                            FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                            return 0;
                        } else if (!IS_ERROR(result)) {
                            DEBUGF("Received %d byte(s) of data\n", count);

                            memcpy(current_load_ptr, data_buf, count - 1);
                            received_data_size += (count - 1);

                            if (result == GOT_CRCE) {
                                // End of frame, header follows, no ZACK expected.
                                DEBUGF("Got CRCE; Frame done [NOACK] [Pos: 0x%08lx]\n", received_data_size);
                                break;
                            } else if (result == GOT_CRCG) {
                                // Frame continues, non-stop (another data packet follows)
                                DEBUGF("Got CRCG; Frame continues [NOACK] [Pos: 0x%08lx]\n", received_data_size);
                                continue;
                            } else if (result == GOT_CRCQ) {
                                // Frame continues, ZACK required
                                DEBUGF("Got CRCQ; Frame continues [ACK] [Pos: 0x%08lx]\n", received_data_size);

                                result = zm_send_pos_hdr(ZACK,
                                        received_data_size);

                                if (result == CANCELLED) {
                                    FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                                    return 0;
                                } else if (result == OK) {
                                    DEBUGF("Send ZACK was OK\n");
                                } else if (result == CLOSED) {
                                    FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                                    return 0;
                                }

                                continue;
                            } else if (result == GOT_CRCW) {
                                // End of frame, header follows, ZACK expected.
                                DEBUGF("Got CRCW; Frame done [ACK] [Pos: 0x%08lx]\n", received_data_size);

                                result = zm_send_pos_hdr(ZACK,
                                        received_data_size);

                                if (result == CANCELLED) {
                                    FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                                    return 0;
                                } else if (result == OK) {
                                    DEBUGF("Send ZACK was OK\n");
                                } else if (result == CLOSED) {
                                    FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                                    return 0;
                                }

                                break;
                            }

                        } else {
                            DEBUGF("Error while receiving block: 0x%04x\n", result);

                            result = zm_send_pos_hdr(ZRPOS, received_data_size);

                            if (result == CANCELLED) {
                                FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                                return 0;
                            } else if (result == OK) {
                                DEBUGF("Send ZRPOS was OK\n");
                                goto startframe;
                            } else if (result == CLOSED) {
                                FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                                return 0;
                            }
                        }
                    }

                    continue;

                default:
                    PRINTF("WARN: Ignoring unknown header type 0x%02x\n", hdr.type);
                    continue;
                }

                break;
            case BAD_CRC:
                DEBUGF("Didn't get valid header - CRC Check failed\n");

                result = zm_send_pos_hdr(ZNAK, received_data_size);

                if (result == CANCELLED) {
                    FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                    return 0;
                } else if (result == OK) {
                    DEBUGF("Send ZNACK was OK\n");
                } else if (result == CLOSED) {
                    FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                    return 0;
                }

                continue;
            default:
                DEBUGF("Didn't get valid header - result is 0x%04x\n", result);

                result = zm_send_pos_hdr(ZNAK, received_data_size);

                if (result == CANCELLED) {
                    FPRINTF(stderr, "Transfer cancelled by remote; Bailing...\n");
                    return 0;
                } else if (result == OK) {
                    DEBUGF("Send ZNACK was OK\n");
                } else if (result == CLOSED) {
                    FPRINTF(stderr, "Connection closed prematurely; Bailing...\n");
                    return 0;
                }

                continue;
            }
        }
    }

    return received_data_size;
}

