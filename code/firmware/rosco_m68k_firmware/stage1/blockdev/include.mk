OBJECTS+=blockdev/syscalls_asm.o
DEFINES+=-DBLOCKDEV_SUPPORT
INCLUDES+=-Iblockdev/include

OBJECTS+=blockdev/bbspi.o blockdev/bbsd.o
ifeq ($(REVISION1X),true)
OBJECTS+=blockdev/mfp_gpio.o
else
OBJECTS+=blockdev/dua_spi_asm.o
endif
DEFINES+=-DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY

ifeq ($(WITH_ATA),true)
OBJECTS+=blockdev/ata_disable_interrupt.o blockdev/ata.o
DEFINES+=-DROSCO_M68K_ATA
endif

BD_EXTRA_CFLAGS=-O3

blockdev/%.o: CLFAGS+=$(BD_EXTRA_CFLAGS)
