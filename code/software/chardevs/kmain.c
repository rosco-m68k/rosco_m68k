/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <machine.h>
#include <printf.h>

void kmain() {
    if (mcCheckDeviceSupport()) {
        printf("Character device support detected\n");

        uint16_t count = mcGetDeviceCount();
        printf("Found %d device(s)\n", count);

        for (int i = 0; i < count; i++) {
            CharDevice dev;
            if (mcGetDevice(i, &dev))   {
                printf("type    : 0x%02x\n",  dev.device_type);
                printf("data    : 0x%08lx\n", dev.data);
                printf("checkptr: 0x%08lx\n", dev.checkptr);
                printf("recvptr : 0x%08lx\n", dev.recvptr);
                printf("sendptr : 0x%08lx\n", dev.sendptr);

                printf("Printing to device %d\n", i);
                fctprintf(mcSendDevice, &dev, "Hello, World\n"); 
                printf("\n\n");
            } else {
                printf("mcGetDevice for device %d failed.\n", i);
            }
        }

        printf("Done\n");

        while (1);

    } else {
        printf("No character device support detected\n");
    }
}



