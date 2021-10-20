/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Stage 2 ZMODEM loader support (for MBZM)
 * ------------------------------------------------------------
 */

#include "zmodem.h"
#include "serial.h"
#include "s2machine.h"

#define DEBUGF(...)

extern uint8_t *kernel_load_ptr;
static uint8_t *current_load_ptr;

// Spec says a data packet is max 1024 bytes, but add some headroom...
#define DATA_BUF_LEN    2048

/* ************* Exported functions for the mbzm lib **************** */
ZRESULT zm_recv() {
    return RECVCHAR();
}

ZRESULT zm_send(uint8_t data) {
    SENDCHAR(data);
    return OK;
}

/* ************* The main receive func **************** */
int zm_receive_kernel() {
    uint8_t rzr_buf[4];
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
                goto cleanup;
            case OK:
                DEBUGF("Got valid header\n");

                switch (hdr.type) {
                case ZRQINIT:
                case ZEOF:
                    DEBUGF("Is ZRQINIT or ZEOF\n");

                    result = zm_send_flags_hdr(ZRINIT, CANOVIO, 0, 0, 0);

                    if (result == CANCELLED) {
                        DEBUGF("Transfer cancelled by remote; Bailing...\n");
                        goto cleanup;
                    } else if (result == OK) {
                        DEBUGF("Send ZRINIT was OK\n");
                    } else if (result == CLOSED) {
                        DEBUGF("Connection closed prematurely; Bailing...\n");
                        goto cleanup;
                    }

                    continue;

                case ZFIN:
                    DEBUGF("Is ZFIN\n");

                    result = zm_send_pos_hdr(ZFIN, 0);

                    if (result == CANCELLED) {
                        DEBUGF("Transfer cancelled by remote; Bailing...\n");
                        goto cleanup;
                    } else if (result == OK) {
                        DEBUGF("Send ZFIN was OK\n");
                    } else if (result == CLOSED) {
                        DEBUGF("Connection closed prematurely; Bailing...\n");
                    }

                    DEBUGF("Transfer complete; Received %0d byte(s)\n", received_data_size);
                    goto cleanup;

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
                        DEBUGF("WARN: Invalid conversion flag [0x%02x] (IGNORED - Assuming Binary)\n", hdr.flags.f0);
                    }

                    count = DATA_BUF_LEN;
                    result = zm_read_data_block(data_buf, &count);
                    DEBUGF("Result of data block read is [0x%04x] (got %d character(s))\n", result, count);

                    if (result == CANCELLED) {
                        DEBUGF("Transfer cancelled by remote; Bailing...\n");
                        goto cleanup;
                    } else if (!IS_ERROR(result)) {
                        DEBUGF("Receiving file: '%s'\n", data_buf);

                        result = zm_send_pos_hdr(ZRPOS, received_data_size);

                        if (result == CANCELLED) {
                            DEBUGF("Transfer cancelled by remote; Bailing...\n");
                            goto cleanup;
                        } else if (result == OK) {
                            DEBUGF("Send ZRPOS was OK\n");
                        } else if (result == CLOSED) {
                            DEBUGF("Connection closed prematurely; Bailing...\n");
                            goto cleanup;
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
                            DEBUGF("Transfer cancelled by remote; Bailing...\n");
                            goto cleanup;
                        } else if (!IS_ERROR(result)) {
                            DEBUGF("Received %d byte(s) of data\n", count);

                            // TODO this copying is not optimal and likely too slow for faster UARTs...
                            for (int i = 0; i < count - 1; i++) {
                                *current_load_ptr++ = data_buf[i];
                            }

                            received_data_size += (count - 1);

                            if (result == GOT_CRCE) {
                                // End of frame, header follows, no ZACK expected.
                                DEBUGF("Got CRCE; Frame done [NOACK] [Pos: 0x%08x]\n", received_data_size);
                                break;
                            } else if (result == GOT_CRCG) {
                                // Frame continues, non-stop (another data packet follows)
                                DEBUGF("Got CRCG; Frame continues [NOACK] [Pos: 0x%08x]\n", received_data_size);
                                continue;
                            } else if (result == GOT_CRCQ) {
                                // Frame continues, ZACK required
                                DEBUGF("Got CRCQ; Frame continues [ACK] [Pos: 0x%08x]\n", received_data_size);

                                result = zm_send_pos_hdr(ZACK,
                                        received_data_size);

                                if (result == CANCELLED) {
                                    DEBUGF("Transfer cancelled by remote; Bailing...\n");
                                    goto cleanup;
                                } else if (result == OK) {
                                    DEBUGF("Send ZACK was OK\n");
                                } else if (result == CLOSED) {
                                    DEBUGF("Connection closed prematurely; Bailing...\n");
                                    goto cleanup;
                                }

                                continue;
                            } else if (result == GOT_CRCW) {
                                // End of frame, header follows, ZACK expected.
                                DEBUGF("Got CRCW; Frame done [ACK] [Pos: 0x%08x]\n", received_data_size);

                                result = zm_send_pos_hdr(ZACK,
                                        received_data_size);

                                if (result == CANCELLED) {
                                    DEBUGF("Transfer cancelled by remote; Bailing...\n");
                                    goto cleanup;
                                } else if (result == OK) {
                                    DEBUGF("Send ZACK was OK\n");
                                } else if (result == CLOSED) {
                                    DEBUGF("Connection closed prematurely; Bailing...\n");
                                    goto cleanup;
                                }

                                break;
                            }

                        } else {
                            DEBUGF("Error while receiving block: 0x%04x\n", result);

                            result = zm_send_pos_hdr(ZRPOS, received_data_size);

                            if (result == CANCELLED) {
                                DEBUGF("Transfer cancelled by remote; Bailing...\n");
                                goto cleanup;
                            } else if (result == OK) {
                                DEBUGF("Send ZRPOS was OK\n");
                                goto startframe;
                            } else if (result == CLOSED) {
                                DEBUGF("Connection closed prematurely; Bailing...\n");
                                goto cleanup;
                            }
                        }
                    }

                    continue;

                default:
                    DEBUGF("WARN: Ignoring unknown header type 0x%02x\n", hdr.type);
                    continue;
                }

                break;
            case BAD_CRC:
                DEBUGF("Didn't get valid header - CRC Check failed\n");

                result = zm_send_pos_hdr(ZNAK, received_data_size);

                if (result == CANCELLED) {
                    DEBUGF("Transfer cancelled by remote; Bailing...\n");
                    goto cleanup;
                } else if (result == OK) {
                    DEBUGF("Send ZNACK was OK\n");
                } else if (result == CLOSED) {
                    DEBUGF("Connection closed prematurely; Bailing...\n");
                    goto cleanup;
                }

                continue;
            default:
                DEBUGF("Didn't get valid header - result is 0x%04x\n", result);

                result = zm_send_pos_hdr(ZNAK, received_data_size);

                if (result == CANCELLED) {
                    DEBUGF("Transfer cancelled by remote; Bailing...\n");
                    goto cleanup;
                } else if (result == OK) {
                    DEBUGF("Send ZNACK was OK\n");
                } else if (result == CLOSED) {
                    DEBUGF("Connection closed prematurely; Bailing...\n");
                    goto cleanup;
                }

                continue;
            }
        }
    }

    cleanup: return received_data_size;
}

