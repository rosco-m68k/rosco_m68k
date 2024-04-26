OBJECTS+=sdfat/sdcard.o sdfat/load.o
DEFINES+=-DSPI_FASTER -DSD_FASTER -DSD_MINIMAL -DSDFAT_LOADER
INCLUDES+=-Isdfat/include
BBSD_DEFINES:=-DSDFAT_LOADER -DROSCO_M68K
BBSD_INCLUDES:=-I../stage1/blockdev/include
BBSD_CFLAGS=$(CFLAGS) $(BBSD_DEFINES) $(BBSD_INCLUDES)
								
sdfat/load.o: sdfat/load.c
	$(CC) $(BBSD_CFLAGS) -c -o $@ $<
