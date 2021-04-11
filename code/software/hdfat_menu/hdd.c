#include <stdint.h>
#include <stdbool.h>
#include <machine.h>
#include <fat_filelib.h>

#define IO_BASE 0x00F80000
#define IDE_BASE (IO_BASE + 0x0040)

#define IDE_REG_RD_DATA 0
#define IDE_REG_RD_ERROR 1
#define IDE_REG_RD_SECTOR_COUNT 2
#define IDE_REG_RD_LBA_7_0 3
#define IDE_REG_RD_LBA_15_8 4
#define IDE_REG_RD_LBA_23_16 5
#define IDE_REG_RD_LBA_27_24 6
#define IDE_REG_RD_STATUS 7

#define IDE_REG_RD_ALT_STATUS 14

#define IDE_REG_WR_DATA 0
#define IDE_REG_WR_FEATURES 1
#define IDE_REG_WR_SECTOR_COUNT 2
#define IDE_REG_WR_LBA_7_0 3
#define IDE_REG_WR_LBA_15_8 4
#define IDE_REG_WR_LBA_23_16 5
#define IDE_REG_WR_LBA_27_24 6
#define IDE_REG_WR_COMMAND 7

#define IDE_REG_WR_DEVICE_CONTROL 14

#define LBA_MASK 0x07FFFFFF

enum REG_STATUS_BIT { STATUS_ERR, STATUS_IDX, STATUS_CORR, STATUS_DRQ, STATUS_DSC, STATUS_DF, STATUS_DRDY, STATUS_BSY };

static volatile uint16_t *idereg = (volatile uint16_t *)IDE_BASE;

static volatile uint16_t vstatus, verror;
static volatile bool virq = false;
static volatile bool vread = false;
static volatile bool vwrite = false;

static volatile union {
  uint32_t dword[128];
  uint16_t word[256];
  uint8_t byte[512];
} vbuffer;

static
__attribute__ ((interrupt)) void autovector_ipl_3_handler(void) {
  virq = true;
  vstatus = idereg[IDE_REG_RD_STATUS] & 0x00FF;
  verror = idereg[IDE_REG_RD_ERROR] & 0x00FF;
  if (vread) {
      if (vstatus & 0x0008)             // DRQ bit
          for (int i = 0; i < 256; i++)
              vbuffer.word[i] = idereg[IDE_REG_RD_DATA];
  }
//  printf("Interrupt 3\r\n");
}

int FAT_media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    vread = true;
    vwrite = false;

//    printf("Waiting for BSY to clear\r\n");
    while (idereg[IDE_REG_RD_ALT_STATUS] & 0x0080)
      continue;

//    printf("Waiting for DRDY\r\n");
    while ((idereg[IDE_REG_RD_ALT_STATUS] & 0x00C0) != 0x0040)
      continue;


    for (uint32_t current = sector; current < sector+sector_count; current++) {
//        printf("Sending the READ SECTORS command for sector %d\r\n", current);        
        
//        idereg[IDE_REG_RD_LBA_27_24] = (current & 0x07000000) >> 24;
        idereg[IDE_REG_RD_LBA_23_16] = (current & 0x00FF0000) >> 16;
        idereg[IDE_REG_RD_LBA_15_8] =  (current & 0x0000FF00) >> 8;
        idereg[IDE_REG_RD_LBA_7_0] =   (current & 0x000000FF);

        idereg[IDE_REG_RD_SECTOR_COUNT] = 1;
        idereg[IDE_REG_WR_COMMAND] = 0x0020;

        // Wait for interrupt
        while (!virq) continue;
        virq = false;

        uint8_t status = vstatus;
        if (status & (1<<STATUS_ERR)) {
            printf("WARN: Read error: 0x%08x\n in sector 0x%08x", verror, current);
            // return (int)verror;
            // return 0;
        }

        // TODO could avoid this copying...
        uint32_t *lbuf = (uint32_t*)buffer;        
        if (vstatus & 0x0008) {
            for (int i = 0; i < 128; i++) {
                *(lbuf++) = vbuffer.dword[i];
            }
        } else {          
            return 0;
        }

        buffer += 512;
    }

    return 1;
}

int FAT_media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    vwrite = true;
    vread = false;

//    printf("Waiting for BSY to clear\r\n");
    while (idereg[IDE_REG_RD_ALT_STATUS] & 0x0080)
      continue;

//    printf("Waiting for DRDY\r\n");
    while ((idereg[IDE_REG_RD_ALT_STATUS] & 0x00C0) != 0x0040)
      continue;


    for (uint32_t current = sector; current < sector+sector_count; current++) {
//          printf("Sending the WRITE SECTORS command, followed by data\r\n");
        vread = false;
        vwrite = true;
  
//        idereg[IDE_REG_RD_LBA_27_24] = (current & 0x07000000) >> 24;
        idereg[IDE_REG_RD_LBA_23_16] = (current & 0x00FF0000) >> 16;
        idereg[IDE_REG_RD_LBA_15_8] =  (current & 0x0000FF00) >> 8;
        idereg[IDE_REG_RD_LBA_7_0] =   (current & 0x000000FF);

        idereg[IDE_REG_RD_SECTOR_COUNT] = 1;
        idereg[IDE_REG_WR_COMMAND] = 0x0030;
        if (idereg[IDE_REG_RD_STATUS] & 0x0001) {         // ERR bit
            printf("Write Error %04X\r\n", idereg[IDE_REG_RD_ERROR]);
            return 0;
        } else {
            // printf("Checking for DRQ\r\n");
            while ((idereg[IDE_REG_RD_ALT_STATUS] & 0x0008) != 0x0008)  // DRQ bit
                continue;

            uint16_t *vbuffer = (uint16_t*)buffer;

            for (int i = 0; i < 256; i++) {
                idereg[IDE_REG_RD_DATA] = *(vbuffer++);
            }
            
            buffer += 512;
        }

    }

    return 1;
}


bool HD_FAT_initialize() {
    void (**vector)(void);

    printf("Setting Autovector IPL handlers\n\r");
    vector = (void (**)(void))(&_INITIAL_STACK);
    vector[27] = autovector_ipl_3_handler;

    printf("Disabling interrupt\r\n");
    idereg[IDE_REG_WR_DEVICE_CONTROL] = 0x0002;

    printf("Waiting for BSY to clear\r\n");
    while (idereg[IDE_REG_RD_ALT_STATUS] & 0x0080)
      continue;

    printf("Selecting the master device\r\n");
    idereg[IDE_REG_WR_LBA_27_24] = 0x00E0;

    printf("Waiting for DRDY\r\n");
    while ((idereg[IDE_REG_RD_ALT_STATUS] & 0x00C0) != 0x0040)
      continue;

    printf("Enabling interrupt\r\n");
    idereg[IDE_REG_WR_DEVICE_CONTROL] = 0x0000;

    printf("Init done\n");

    if (fl_attach_media(FAT_media_read, FAT_media_write) != FAT_INIT_OK) {
        return false;
    } else {  
        return true;
    }
}
