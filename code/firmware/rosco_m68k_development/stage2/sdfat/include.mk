OBJECTS := $(OBJECTS) sdfat/sdcard.o sdfat/load.o															\
	sdfat/fat_io_lib/fat_access.o sdfat/fat_io_lib/fat_cache.o									\
	sdfat/fat_io_lib/fat_filelib.o sdfat/fat_io_lib/fat_format.o								\
	sdfat/fat_io_lib/fat_misc.o sdfat/fat_io_lib/fat_string.o										\
	sdfat/fat_io_lib/fat_table.o sdfat/fat_io_lib/fat_write.o

EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DFATFS_USE_CUSTOM_OPTS_FILE			\
		-DSPI_FASTER -DSD_FASTER -DSD_MINIMAL -DSDFAT_LOADER                    	\
		-Isdfat/include

BBSD_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter		                	\
			      -Wall -Werror -Wpedantic -Wno-unused-function                   	\
            -Iinclude -I../include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)	\
            -DROSCO_M68K -DFATFS_USE_CUSTOM_OPTS_FILE					              	\
            -Isdfat/include -I../blockdev/include																\
            -mno-align-int -mno-strict-align $(DEFINES) -DSDFAT_LOADER
								
sdfat/load.o: sdfat/load.c
	$(CC) $(BBSD_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

