/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <stdint.h>
#include <machine.h>
#include <debug.h>

void fix_stack(void);
int dev_cnt(void);

void kmain() {
    if (start_debugger()) {
        printf("Start debugger; Connect via GDB\n");
        breakpoint();
    } else {
        printf("Unable to start debugger :(\n");
    }

    if (mcCheckDeviceSupport()) {
        printf("We have device support\n");

        uint8_t count = dev_cnt();

        printf("There are %d device(s)\n", count);

        for (int i = 0; i < count; i++) {
            CharDevice cd;

            if (mcGetDevice(i, &cd)) {
                printf("Device %d\n", i);
                printf("  data     @ 0x%08lx\n", cd.data);
                printf("  check    @ 0x%08lx\n", cd.checkptr);
                printf("  recv     @ 0x%08lx\n", cd.recvptr);
                printf("  send     @ 0x%08lx\n", cd.sendptr);
                printf("  caps     @ 0x%08x\n", cd.capabilities);
                printf("  flags    @ 0x%08x\n", cd.flags);
                printf("  type     @ 0x%08x\n", cd.device_type);
                printf("\n");
            } else {
                printf("mcGetDevice failed for device %d\n", i);
            }
        }
    } else {
        printf("No device support in firmware\n");
    }

    cleanup_debugger();
}

