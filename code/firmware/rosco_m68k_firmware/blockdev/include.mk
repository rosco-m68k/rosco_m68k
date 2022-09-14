OBJECTS+=blockdev/bbspi.o blockdev/bbsd.o                  \
         blockdev/syscalls_asm.o blockdev/ata.o
ifeq ($(REVISION1X),true)
OBJECTS+=blockdev/mfp_gpio.o
else
OBJECTS+=blockdev/dua_spi_asm.o
endif
INCLUDES+=-Iblockdev/include
DEFINES+=-DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY -DBLOCKDEV_SUPPORT -DROSCO_M68K_ATA 

ifeq ($(HUGEROM),true)
blockdev/%.o: blockdev/%.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -O3 -o $@ $<
endif

