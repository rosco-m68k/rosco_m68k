/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k Bit-Banged SD Card over SPI
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>

#include "bbspi.h"
#include "bbsd.h"

static bool wait_for_card(uint32_t);
static void reset_card();
static bool wait_for_block_start();
static bool send_idle();
static BBSDCardType get_card_type();
static bool try_acmd41(uint32_t, uint32_t);
static uint8_t raw_sd_command(uint8_t, uint32_t);
static uint8_t raw_sd_command_force(uint8_t, uint32_t, bool);
static uint8_t raw_sd_acommand(uint8_t, uint32_t);
#ifndef SD_BLOCK_READ_ONLY
static bool sd_partial_read_p(BBSDCard*);
#endif

BBSDInitStatus BBSD_initialize(BBSDCard *sd) {
    BBSPI_initialize();

    int idle_tries = 0;
    BBSDInitStatus result = BBSD_INIT_OK;

    while (idle_tries++ < BBSD_MAX_IDLE_RETRIES) {
        reset_card();

        if (!send_idle()) {
            if (idle_tries == BBSD_MAX_IDLE_RETRIES) {
                result = BBSD_INIT_IDLE_FAILED;
                goto finally;
            }
        } else {
            break;
        }
    }

    BBSDCardType card_type = get_card_type();

    if (card_type == BBSD_CARD_TYPE_UNKNOWN) {
        result = BBSD_INIT_CMD8_FAILED;
        goto finally;
    }

    // Try to initialize the card...
    uint32_t supports = card_type == BBSD_CARD_TYPE_V2 ? 0x40000000 : 0;

    if (try_acmd41(BBSD_MAX_ACMD41_RETRIES, supports)) {
        if (card_type == BBSD_CARD_TYPE_V2) {
            // check OCR for SDHC...
            if (raw_sd_command(58, 0)) {
                goto finally;
            } else {
                if ((BBSPI_recv_byte() & 0xC0) == 0xC0) {
                    card_type = BBSD_CARD_TYPE_SDHC;
                }

                // don't care about voltage range...
                BBSPI_recv_byte();
                BBSPI_recv_byte();
                BBSPI_recv_byte();

#ifndef SD_BLOCK_READ_ONLY
                sd->have_current_block = false;

                // TODO this can't currently signal error!
                sd->can_partial_read = sd_partial_read_p(sd);
#endif

            }
        }

        sd->initialized = true;
        sd->type = card_type;
        result = BBSD_INIT_OK;

        // Explicitly disable CRC as some cards are non-compliant with this...
        BBSD_command(sd, 59, 0);
    } else {
        result = BBSD_INIT_ACMD41_FAILED;
    }

finally:
    BBSPI_deassert_cs0();
    return result;
}

uint8_t BBSD_command(BBSDCard *sd, uint8_t command, uint32_t arg) {
    if (sd->initialized) {
        return raw_sd_command(command, arg);
    } else {
        return 0xFF;
    }
}

uint8_t BBSD_acommand(BBSDCard *sd, uint8_t command, uint32_t arg) {
    if (sd->initialized) {
        return raw_sd_acommand(command, arg);
    } else {
        return 0xFF;
    }
}

#ifndef SD_MINIMAL
bool BBSD_readreg(BBSDCard *sd, uint8_t command, uint8_t *buf) {
    if (!sd->initialized) {
        return false;
    }

    bool result = false;

    if (!raw_sd_command(command, 0)) {
        if (wait_for_block_start()) {
            for (uint32_t i = 0; i < 16; i++) {
                buf[i] = BBSPI_recv_byte();
            }

            // Ignore CRCs...
            BBSPI_recv_byte();
            BBSPI_recv_byte();

            result = true;
        }
    }

    BBSPI_deassert_cs0();
    return result;
}

#ifdef SD_SIZE_SUPPORT
bool BBSD_get_csd(BBSDCard *sd, BBSDCard_CSD *csd) {
    return BBSD_readreg(sd, 9, (uint8_t*) csd);
}

static BBSDCard_CSD csdbuf;

uint32_t BBSD_get_size(BBSDCard *sd) {
    if (!BBSD_get_csd(sd, &csdbuf)) {
        return 0;
    }
    if (csdbuf.v1.csd_ver == 0) {
        uint8_t read_bl_len = csdbuf.v1.read_bl_len;
        uint16_t c_size = (csdbuf.v1.c_size_high << 10)
                | (csdbuf.v1.c_size_mid << 2) | csdbuf.v1.c_size_low;
        uint8_t c_size_mult = (csdbuf.v1.c_size_mult_high << 1)
                | csdbuf.v1.c_size_mult_low;

        return (uint32_t) (c_size + 1) << (c_size_mult + read_bl_len - 7);
    } else if (csdbuf.v2.csd_ver == 1) {
        uint32_t c_size = ((uint32_t) csdbuf.v2.c_size_high << 16)
                | (csdbuf.v2.c_size_mid << 8) | csdbuf.v2.c_size_low;

        return (c_size + 1) << 10;
    } else {
        return 0;
    }
}
#endif
#endif

bool BBSD_read_block(BBSDCard *sd, uint32_t block, uint8_t *buffer) {
    if (!sd->initialized) {
        return false;
    }
    bool result = false;

    uint32_t addressable_block;

    if (sd->type == BBSD_CARD_TYPE_SDHC) {
        // SDHC is addressed by block number
        addressable_block = block;
    } else {
        // Other cards use absolute addressing
        addressable_block = block << 9;
    }

    if (BBSD_command(sd, 17, addressable_block) || !wait_for_block_start()) {
        goto finally;
    }

    // Read data into buffer
    BBSPI_recv_buffer(buffer, 512);

    // Get checksum too (and ignore it ;) )
    BBSPI_recv_byte();
    BBSPI_recv_byte();

    result = true;

finally:
    BBSPI_deassert_cs0();
    return result;
}

#ifndef SD_BLOCK_READ_ONLY
bool BBSD_read_data(BBSDCard *sd, uint32_t block, uint16_t start_ofs, uint16_t count, uint8_t *buffer) {
    // Do args make sense?
    if (!sd->initialized || (start_ofs + count) > 512) {
        return false;
    }

    // We've already read 0 bytes :D
    if (count == 0) {
        return true;
    }

    bool result = false;

    // Do we need to re-address the card?
    if (!sd->have_current_block                             // Yes, if we're not currently reading a block, or
            || block != sd->current_block_start             // .. they don't want data from the current block, or
            || start_ofs < sd->current_block_offset) {      // .. they want data from before where we currently are.

        uint32_t addressable_block;
        if (sd->type == BBSD_CARD_TYPE_SDHC) {
            // SDHC is addressed by block number
            addressable_block = block;
        } else {
            // Other cards use absolute addressing
            addressable_block = block << 9;
        }

        if (BBSD_command(sd, 17, addressable_block) || !wait_for_block_start()) {
            goto finally;
        }

        sd->have_current_block = true;
        sd->current_block_start = block;
        sd->current_block_offset = 0;
    }

    // Skip data before offset
    for (; sd->current_block_offset < start_ofs; sd->current_block_offset++) {
        BBSPI_recv_byte();
    }

    // Read data into buffer
    BBSPI_recv_buffer(buffer, 512);

    sd->current_block_offset += count;

    // Finish block if partial read isn't supported
#ifndef SD_UNSAFE_PARTIAL_READ
    if (!sd->can_partial_read) {
        // TODO this isn't supporting the case where partial read has crossed a block boundary! look into that!
        while (sd->current_block_offset++ < 513) {
            BBSPI_recv_byte();
        }

        // Get checksum too (and ignore it ;) )
        BBSPI_recv_byte();
        BBSPI_recv_byte();
    }
#endif

    result = true;

finally:
    BBSPI_deassert_cs0();
    return result;
}
#endif

bool BBSD_write_block(BBSDCard *sd, uint32_t block, uint8_t *buffer) {
    if (!sd->initialized) {
        return false;
    }
    bool result = false;

    uint32_t addressable_block;

    if (sd->type == BBSD_CARD_TYPE_SDHC) {
        // SDHC is addressed by block number
        addressable_block = block;
    } else {
        // Other cards use absolute addressing
        addressable_block = block << 9;
    }

    if (BBSD_command(sd, 24, addressable_block)) {
        goto finally;
    }

    // Send block start token
    BBSPI_send_byte(BLOCK_START);

    // Write data into buffer
    BBSPI_send_buffer(buffer, 512);

    // Send dummy checksum
    BBSPI_send_byte(0xFF);
    BBSPI_send_byte(0xFF);

    // Wait for card to be done...
    if (!wait_for_card(BBSD_COMMAND_WAIT_RETRIES)) {
        result = false;
    } else {
        result = true;
    }

finally:
    BBSPI_deassert_cs0();
    return result;
}


/* ********* PRIVATE *********** */
static bool wait_for_card(uint32_t nops) {
    for (uint32_t i = 0; i < nops; i++) {
        if (BBSPI_recv_byte() == 0xFF) {
            return true;
        }
    }
    return false;
}

static void reset_card() {
    BBSPI_deassert_cs0();

    for (int i = 0; i < BBSD_RESET_CYCLES; i++) {
        BBSPI_send_byte(0xFF);
    }
}

static bool wait_for_block_start() {
    for (uint32_t i = 0; i < BBSD_BLOCK_START_TIMEOUT; i++) {
        uint8_t status = BBSPI_recv_byte();
        if (status != 0xFF) {
            if (status == BLOCK_START) {
                return true;
            } else {
                // something happened, but not what we expected :D
                return false;
            }
        }
    }

    return false;
}

static bool send_idle() {
    for (int i = 0; i < BBSD_IDLE_TIMEOUT; i++) {
        if (raw_sd_command_force(0, 0, true) == R1_IDLE_STATE) {
            return true;
        }
    }

    return false;
}

static BBSDCardType get_card_type() {
    // Let's try a CMD8...
    if (raw_sd_command(8, 0x1AA) & R1_ILLEGAL_COMMAND) {
        return BBSD_CARD_TYPE_V1;
    } else {
        // Ignore all but last byte...
        BBSPI_recv_byte();
        BBSPI_recv_byte();
        BBSPI_recv_byte();
        BBSPI_recv_byte();
        uint8_t result = BBSPI_recv_byte();

        if (result == 0xAA) {
            return BBSD_CARD_TYPE_UNKNOWN;
        } else {
            return BBSD_CARD_TYPE_V2;
        }
    }
}

static bool try_acmd41(uint32_t nops, uint32_t supports) {
    for (uint32_t i = 0; i < nops; i++) {
        if (raw_sd_acommand(41, supports) == R1_READY_STATE) {
            return true;
        }
    }

    return false;
}

static uint8_t raw_sd_command(uint8_t command, uint32_t arg) {
  return raw_sd_command_force(command, arg, false);
}

static uint8_t raw_sd_command_force(uint8_t command, uint32_t arg, bool force) {
    BBSPI_assert_cs0();

    if (!wait_for_card(BBSD_COMMAND_WAIT_RETRIES) && !force) {
        return 0xFF;
    }

    BBSPI_send_byte(command | 0x40);
    for (int8_t s = 24; s >= 0; s -= 8)
        BBSPI_send_byte(arg >> s);

    uint8_t crc = 0xFF;
    if (command == 0)
        crc = 0x95;
    if (command == 8)
        crc = 0x87;
    BBSPI_send_byte(crc);

    uint8_t result = 0xFF;
    for (uint8_t i = 0; ((result = BBSPI_recv_byte()) & 0x80) && i != 0xFF;
            i++)
        ;
    return result;
}

static uint8_t raw_sd_acommand(uint8_t command, uint32_t arg) {
    raw_sd_command(55, 0);
    return raw_sd_command(command, arg);
}

#ifndef SD_BLOCK_READ_ONLY
static bool sd_partial_read_p(BBSDCard *sd) {
    if (!BBSD_get_csd(sd, &csdbuf)) {
        return 0;
    }
    if (csdbuf.v1.csd_ver == 0) {
        return csdbuf.v1.read_bl_partial;
    } else if (csdbuf.v2.csd_ver == 1) {
        return csdbuf.v2.read_bl_partial;
    } else {
        return false;
    }
}
#endif
