CFLAGS := $(CFLAGS) -DROSCO_M68K -DFATFS_USE_CUSTOM_OPTS_FILE -DSPI_FASTER	\
	-DSPI_ZERODELAY -DSD_FASTER -DSD_MINIMAL -Isdfat/include
OBJECTS := $(OBJECTS) sdfat/gpio.o sdfat/bbspi.o sdfat/bbsd.o sdfat/load.o	\
	sdfat/fat_io_lib/fat_access.o sdfat/fat_io_lib/fat_cache.o								\
	sdfat/fat_io_lib/fat_filelib.o sdfat/fat_io_lib/fat_format.o							\
	sdfat/fat_io_lib/fat_misc.o sdfat/fat_io_lib/fat_string.o									\
	sdfat/fat_io_lib/fat_table.o sdfat/fat_io_lib/fat_write.o
