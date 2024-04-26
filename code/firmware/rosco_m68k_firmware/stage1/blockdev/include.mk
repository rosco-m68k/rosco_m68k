OBJECTS+=blockdev/bbspi.o blockdev/bbsd.o blockdev/syscalls_asm.o
ifeq ($(REVISION1X),true)
OBJECTS+=blockdev/mfp_gpio.o
else
OBJECTS+=blockdev/dua_spi_asm.o
endif
DEFINES+=-DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY -DBLOCKDEV_SUPPORT
INCLUDES+=-Iblockdev/include

ifeq ($(WITH_ATA),true)
OBJECTS+=blockdev/ata_disable_interrupt.o blockdev/ata.o
DEFINES+=-DROSCO_M68K_ATA
endif

BD_CFLAGS=$(CFLAGS) -O3 $(BD_DEFINES) $(BD_INCLUDES)

blockdev/mfp_gpio.o: blockdev/mfp_gpio.c
	$(CC) $(BD_CFLAGS) -c -o $@ $<

blockdev/bbspi.o: blockdev/bbspi.c
	$(CC) $(BD_CFLAGS) -c -o $@ $<

blockdev/bbsd.o: blockdev/bbsd.c
	$(CC) $(BD_CFLAGS) -c -o $@ $<

blockdev/ata.o: blockdev/ata.c
	$(CC) $(BD_CFLAGS) -c -o $@ $<
