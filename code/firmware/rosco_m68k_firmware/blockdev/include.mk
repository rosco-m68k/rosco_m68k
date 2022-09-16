# Blockdev
OBJECTS+=blockdev/syscalls_asm.o
INCLUDES+=-Iblockdev/include
DEFINES+=-DBLOCKDEV_SUPPORT

# Bit-banged SPI
OBJECTS+=blockdev/bbspi.o
ifeq ($(REVISION1X),true)
OBJECTS+=blockdev/mfp_gpio.o
else
OBJECTS+=blockdev/dua_spi_asm.o
endif

# Bit-banged SD
ifeq ($(WITH_BBSD),true)
OBJECTS+=blockdev/bbsd.o
DEFINES+=-DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY
endif

# ATA
ifeq ($(WITH_ATA),true)
OBJECTS+=blockdev/ata.o
DEFINES+=-DROSCO_M68K_ATA 
endif

ifeq ($(HUGEROM),true)
blockdev/%.o: blockdev/%.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -O3 -o $@ $<
endif
