OBJECTS := $(OBJECTS) sdfat/gpio.o sdfat/bbspi.o sdfat/bbsd.o sdfat/load.o	\
	sdfat/fat_io_lib/fat_access.o sdfat/fat_io_lib/fat_cache.o								\
	sdfat/fat_io_lib/fat_filelib.o sdfat/fat_io_lib/fat_format.o							\
	sdfat/fat_io_lib/fat_misc.o sdfat/fat_io_lib/fat_string.o									\
	sdfat/fat_io_lib/fat_table.o sdfat/fat_io_lib/fat_write.o

EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DROSCO_M68K -DFATFS_USE_CUSTOM_OPTS_FILE		\
		-DSPI_FASTER -DSD_FASTER -DSD_MINIMAL -DSDFAT_LOADER                    \
		-Isdfat/include

BBSD_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter										\
       -Wall -Werror -Wpedantic -Wno-unused-function		              			\
			 -Iinclude -I../include -mcpu=68010 -march=68010 -mtune=68010   			\
			 -DROSCO_M68K -DFATFS_USE_CUSTOM_OPTS_FILE -DSPI_FASTER								\
			 -DSPI_ZERODELAY -DSD_FASTER -DSD_MINIMAL -Isdfat/include							\
			 -mno-align-int -mno-strict-align $(DEFINES) -DSDFAT_LOADER

BBSD_SIZE_CFLAGS=$(BBSD_CFLAGS) -Os 

# Speed is the default, only use size for specific files
sdfat/fat_io_lib/fat_string.o: sdfat/fat_io_lib/fat_string.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

sdfat/fat_io_lib/fat_table.o: sdfat/fat_io_lib/fat_table.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<
	
sdfat/fat_io_lib/fat_filelib.o: sdfat/fat_io_lib/fat_filelib.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

sdfat/fat_io_lib/fat_misc.o: sdfat/fat_io_lib/fat_misc.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

sdfat/fat_io_lib/fat_access.o: sdfat/fat_io_lib/fat_access.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

sdfat/load.o: sdfat/load.c
	$(CC) $(BBSD_SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

