OBJECTS := $(OBJECTS) sdcard/gpio.o sdcard/bbspi.o sdcard/bbsd.o sdcard/syscalls_asm.o 
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DROSCO_M68K_SDCARD -DSD_BLOCK_READ_ONLY -DSDCARD_SUPPORT -Isdcard/include

