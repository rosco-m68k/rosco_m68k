OBJECTS := $(OBJECTS) sdfat/sdcard.o sdfat/load.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS)																								\
		-DSPI_FASTER -DSD_FASTER -DSD_MINIMAL -DSDFAT_LOADER                    	\
		-Isdfat/include
