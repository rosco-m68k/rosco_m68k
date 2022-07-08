/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <machine.h>
#include <printf.h>

typedef struct {
    uint32_t    data;
    uint32_t    checkptr;
    uint32_t    recvptr;
    uint32_t    sendptr;
} CHAR_DEVICE;

void kmain() {
    if (mcCheckDeviceSupport()) {
        printf("Character device support detected\n");

        uint16_t count = mcGetDeviceCount();
        printf("Found %d device(s)\n", count);

        for (int i = 0; i < count; i++) {
            CHAR_DEVICE *dev = mcGetDevice(i);

            printf("data    : 0x%08lx\n", dev->data);
            printf("checkptr: 0x%08lx\n", dev->checkptr);
            printf("recvptr : 0x%08lx\n", dev->recvptr);
            printf("sendptr : 0x%08lx\n", dev->sendptr);

            printf("Printing to device %d\n", i);
            fctprintf(mcSendDevice, dev, "Hello, World\n"); 
            printf("\n\n");
        }

        printf("Done\n");

    } else {
        printf("No character device support detected\n");
    }
}



