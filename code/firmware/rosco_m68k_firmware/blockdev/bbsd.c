/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k Bit-Banged SD Card over SPI
 * ------------------------------------------------------------
 */


#include <stdbool.h>
#include <stdint.h>

#include "bbsd.h"
#include "bbspi.h"

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

static inline uint8_t CalcCRC7(uint8_t* bytes, int32_t len);
static inline uint16_t CalcCRC16(uint8_t* bytes, int32_t len);

static uint8_t tableCRC7[256] = {
    0x00, 0x09, 0x12, 0x1B, 0x24, 0x2D, 0x36, 0x3F,
    0x48, 0x41, 0x5A, 0x53, 0x6C, 0x65, 0x7E, 0x77,
    0x19, 0x10, 0x0B, 0x02, 0x3D, 0x34, 0x2F, 0x26,
    0x51, 0x58, 0x43, 0x4A, 0x75, 0x7C, 0x67, 0x6E,
    0x32, 0x3B, 0x20, 0x29, 0x16, 0x1F, 0x04, 0x0D,
    0x7A, 0x73, 0x68, 0x61, 0x5E, 0x57, 0x4C, 0x45,
    0x2B, 0x22, 0x39, 0x30, 0x0F, 0x06, 0x1D, 0x14,
    0x63, 0x6A, 0x71, 0x78, 0x47, 0x4E, 0x55, 0x5C,
    0x64, 0x6D, 0x76, 0x7F, 0x40, 0x49, 0x52, 0x5B,
    0x2C, 0x25, 0x3E, 0x37, 0x08, 0x01, 0x1A, 0x13,
    0x7D, 0x74, 0x6F, 0x66, 0x59, 0x50, 0x4B, 0x42,
    0x35, 0x3C, 0x27, 0x2E, 0x11, 0x18, 0x03, 0x0A,
    0x56, 0x5F, 0x44, 0x4D, 0x72, 0x7B, 0x60, 0x69,
    0x1E, 0x17, 0x0C, 0x05, 0x3A, 0x33, 0x28, 0x21,
    0x4F, 0x46, 0x5D, 0x54, 0x6B, 0x62, 0x79, 0x70,
    0x07, 0x0E, 0x15, 0x1C, 0x23, 0x2A, 0x31, 0x38,
    0x41, 0x48, 0x53, 0x5A, 0x65, 0x6C, 0x77, 0x7E,
    0x09, 0x00, 0x1B, 0x12, 0x2D, 0x24, 0x3F, 0x36,
    0x58, 0x51, 0x4A, 0x43, 0x7C, 0x75, 0x6E, 0x67,
    0x10, 0x19, 0x02, 0x0B, 0x34, 0x3D, 0x26, 0x2F,
    0x73, 0x7A, 0x61, 0x68, 0x57, 0x5E, 0x45, 0x4C,
    0x3B, 0x32, 0x29, 0x20, 0x1F, 0x16, 0x0D, 0x04,
    0x6A, 0x63, 0x78, 0x71, 0x4E, 0x47, 0x5C, 0x55,
    0x22, 0x2B, 0x30, 0x39, 0x06, 0x0F, 0x14, 0x1D,
    0x25, 0x2C, 0x37, 0x3E, 0x01, 0x08, 0x13, 0x1A,
    0x6D, 0x64, 0x7F, 0x76, 0x49, 0x40, 0x5B, 0x52,
    0x3C, 0x35, 0x2E, 0x27, 0x18, 0x11, 0x0A, 0x03,
    0x74, 0x7D, 0x66, 0x6F, 0x50, 0x59, 0x42, 0x4B,
    0x17, 0x1E, 0x05, 0x0C, 0x33, 0x3A, 0x21, 0x28,
    0x5F, 0x56, 0x4D, 0x44, 0x7B, 0x72, 0x69, 0x60,
    0x0E, 0x07, 0x1C, 0x15, 0x2A, 0x23, 0x38, 0x31,
    0x46, 0x4F, 0x54, 0x5D, 0x62, 0x6B, 0x70, 0x79
};

static uint16_t tableCRC16[256] = {
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
    0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
    0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
    0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
    0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
    0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
    0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
    0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
    0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
    0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
    0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
    0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
    0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
    0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
    0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
    0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
    0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
    0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
    0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
    0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
    0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
    0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
    0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0
};

// returns the CRC7 for a message of "len" bytes
static inline uint8_t CalcCRC7(uint8_t* bytes, int32_t len) {
    uint8_t prevCRC = 0;
    for (int i=0; i<len; i++) {
        prevCRC = tableCRC7[(prevCRC << 1) ^ bytes[i]];
    }
    prevCRC = (prevCRC << 1) | 1;
    return prevCRC;
}

// returns the CRC16 for a message of "len" bytes
static inline uint16_t CalcCRC16(uint8_t* bytes, int32_t len) {
    uint16_t prevCRC = 0;
    for (int i=0; i<len; i++) {
        prevCRC = tableCRC16[((prevCRC >> 8) ^ bytes[i]) & 0xff] ^ (prevCRC << 8);
    }
    return prevCRC;
}

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
    int checksum = ((BBSPI_recv_byte() << 8) | BBSPI_recv_byte()) & 0xFFFF;

    // Check the checksum.  Checksum stored big endian on sd card 
    // Allow for any legacy rosco SD Cards written with a dummy checksum
    if ((CalcCRC16(buffer, 512) == checksum) || (checksum == 0xFFFF)) {
        result = true;
    }

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

    // Send dummy byte prior to block start. Some cards require this.
    BBSPI_send_byte(0xFF);

    // Send block start token
    BBSPI_send_byte(BLOCK_START);

    // Write data into buffer
    BBSPI_send_buffer(buffer, 512);
    
    // Calculate the checksum 
    int16_t checksum = CalcCRC16(buffer, 512);

    // .. and send it big endian first
    BBSPI_send_byte((checksum >> 8) & 0xFF);
    BBSPI_send_byte(checksum & 0xFF);

    // Wait for card to be done...
    if (!wait_for_card(BBSD_WRITE_WAIT_RETRIES)) {
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
        uint8_t result = BBSPI_recv_byte();

        if (result == 0xAA) {
            return BBSD_CARD_TYPE_V2;
        } else {
            return BBSD_CARD_TYPE_UNKNOWN;
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

    // Stage command string, calc CRC7 and send
    uint8_t sd_command[6];
    sd_command[0] = command | 0x40;
    for (int8_t s = 24, j = 1; s >= 0; s -= 8, j++) {
        sd_command[j] = arg >> s;
    }
    sd_command[5] = CalcCRC7(sd_command, 5);

    for (int i=0; i<6; i++) {
        BBSPI_send_byte(sd_command[i]);
    }

    uint8_t result = 0xFF;
    for (uint16_t i = 0; ((result = BBSPI_recv_byte()) & 0x80) && i < BBSD_COMMAND_RESPONSE_RETRIES; i++);
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
