ifeq ($(REVISION1X),true)
OBJECTS := $(OBJECTS) blockdev/mfp_gpio.o blockdev/bbspi.o blockdev/bbsd.o                  \
						blockdev/syscalls_asm.o blockdev/ata.o
else
OBJECTS := $(OBJECTS) blockdev/bbspi.o blockdev/bbsd.o blockdev/dua_spi_asm.o              \
						blockdev/syscalls_asm.o blockdev/ata.o
endif
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY -DBLOCKDEV_SUPPORT \
								-DROSCO_M68K_ATA -Iblockdev/include

ifeq ($(HUGEROM),true)
BD_CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror   \
          -Iinclude -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE) -O3         \
          -fomit-frame-pointer -mno-align-int -mno-strict-align $(DEFINES)

blockdev/mfp_gpio.o: blockdev/mfp_gpio.c
	$(CC) -c $(BD_CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

blockdev/bbspi.o: blockdev/bbspi.c
	$(CC) -c $(BD_CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

blockdev/bbsd.o: blockdev/bbsd.c
	$(CC) -c $(BD_CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

blockdev/ata.o: blockdev/ata.c
	$(CC) -c $(BD_CFLAGS) $(EXTRA_CFLAGS) -o $@ $<
endif

