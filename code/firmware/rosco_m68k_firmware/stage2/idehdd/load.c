/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2021-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * IDE HDD loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include "ata.h"
#include "load.h"
#include "machine.h"
#include "part.h"

extern void print_unsigned(uint32_t num, uint8_t base);
extern bool ATA_support_check();

static bool try_boot(uint8_t device_id) {
    ATADevice device;
    if (ATA_init(device_id, &device) == ATA_INIT_OK) {

#ifdef ATA_DEBUG
        if (device_id == ATA_MASTER) {
             FW_PRINT_C("Master ");
        } else {
            FW_PRINT_C("Slave ");
        }
        FW_PRINT_C("initialized\r\n");
#endif

        FW_PRINT_C("ATA Device ");
        print_unsigned(device_id, 10);
        FW_PRINT_C(":\r\n");

        PartHandle part;
        PartInitStatus pinit = Part_init_ATA(&part, &device);

        if (pinit == PART_INIT_OK) {
#ifdef ATA_DEBUG
            FW_PRINT_C("Partition table initialized\r\n");
#endif
            return load_kernel(&part);
        } else if (pinit == PART_INIT_BAD_SIGNATURE) {
            FW_PRINT_C("  Bad partition signature\r\n");
        } else if (pinit == PART_INIT_READ_FAILURE) {
            FW_PRINT_C("  Partition read failure\r\n");
        } else if (pinit == PART_INIT_GENERAL_FAILURE) {
            FW_PRINT_C("  Partition init general failure\r\n");
        } else {
            FW_PRINT_C("  Partition init - unknown result!\r\n");
        }
#ifdef ATA_DEBUG
    } else {
        FW_PRINT_C("IDE device ");
        print_unsigned(device_id, 10);
        FW_PRINT_C(" not initialized\r\n");
#endif
    }

    return false;
}

bool ide_load_kernel() {
    if (!ATA_support_check()) {
        FW_PRINT_C("Warning: No IDE support in ROM - This may indicate your ROMs are not built correctly!\r\n");
        return false;
    }

    return (try_boot(ATA_MASTER) || try_boot(ATA_SLAVE));
}

