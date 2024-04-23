OBJECTS := $(OBJECTS) sdfat/sdcard.o sdfat/load.o

EXTRA_CFLAGS := $(EXTRA_CFLAGS)																								\
		-DSPI_FASTER -DSD_FASTER -DSD_MINIMAL -DSDFAT_LOADER                    	\
		-Isdfat/include

BBSD_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter		                	\
            -Wall -Werror -Wpedantic -Wno-unused-function                   	\
            -I../stage1/include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)						\
            -DROSCO_M68K -I../stage1/blockdev/include																\
            $(DEFINES) -DSDFAT_LOADER
								
sdfat/load.o: sdfat/load.c
	$(CC) $(BBSD_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<
