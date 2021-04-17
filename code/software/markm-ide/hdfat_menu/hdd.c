#include <stdint.h>
#include <stdbool.h>
#include <fat_filelib.h>
#include "ata.h"
#include "part.h"

static PartHandle phandle;
static uint8_t part = 4;

int FAT_media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return part_read(&phandle, part, buffer, sector, sector_count);
}

int FAT_media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return 0;
}

bool HD_FAT_initialize() {
    ata_init();

    if (part_init(&phandle, ATA_SLAVE) < 0) {
        printf("Partition table init failed\n");
        return false;
    }

    // Find first valid partition
    for (int i = 0; i < 4; i++) {
        if (part_valid(&phandle, i)) {
            part = i;
            break;
        }
    }

    if (part == 4) {
        printf("No valid partitions on disk\n");
        return false;
    } else {
        printf("Using partition %d\n", part);

        if (fl_attach_media(FAT_media_read, FAT_media_write) != FAT_INIT_OK) {
            return false;
        } else {  
            return true;
        }
    }
}
