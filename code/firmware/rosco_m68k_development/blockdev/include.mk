OBJECTS := $(OBJECTS) blockdev/gpio.o blockdev/bbspi.o blockdev/bbsd.o blockdev/syscalls_asm.o 
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY -DSDCARD_SUPPORT \
								-DPIO_ATA_SUPPORT -DROSCO_M68K_ATA -Iblockdev/include

