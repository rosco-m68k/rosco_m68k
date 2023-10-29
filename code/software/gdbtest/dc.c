#include <stdio.h>
#include <machine.h>

int dev_cnt() {
    printf("Get device count!!!\n");
    return mcGetDeviceCount();
}
