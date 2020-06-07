/*
 * Copyright (c) 2020 rosco_m68k
 */

#include <stdint.h>
#include <stdbool.h>
#include <machine.h>

static volatile uint8_t * const mfp_iera = (uint8_t * const)MFP_IERA;
static volatile uint8_t * const mfp_imra = (uint8_t * const)MFP_IMRA;

extern void INIT_SERIAL_HANDLERS();
extern void SENDCHAR(uint8_t c);
extern uint8_t RECVCHAR();
extern void GOFASTER();

#ifdef WITHKERMIT
extern int receive_kernel();
uint8_t *kernel_load_ptr = (uint8_t)0x40000;
#endif

void new_printf(const char *str) {
    while (*str) {
        SENDCHAR(*str++);
    }
}

void kmain() {
    INIT_SERIAL_HANDLERS();

    *mfp_iera |= 0x1E;    // bits 1,2,3,4 - Enable RX and TX...
    *mfp_imra |= 0x1A;    // ... but leave TX empty masked...

    new_printf("Switch to 28K8 and hit space");
    mcBusywait(100000);

    GOFASTER();
    
    uint8_t c = RECVCHAR();
    while (c != 32) {
        c = RECVCHAR();
    }

#ifdef WITHKERMIT
    new_printf("Waiting to receive via Kermit...\r\n");

    while (!receive_kernel()) {
        new_printf("\x1b[1;31mSEVERE\x1b[0m: Receive failed; Ready for retry...\r\n");
    }

    mcBusywait(100000);
    new_printf("Receive _seems_ okay...\r\n");
#endif
   
    new_printf("Going into echo loop...\r\n");

    while (true) { 
        uint8_t c = RECVCHAR();

        if (c != 0) {
            SENDCHAR(c);
        }
    }
    mcHalt();

}

