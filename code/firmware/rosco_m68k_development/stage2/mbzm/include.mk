OBJECTS := $(OBJECTS) mbzm/zheaders.o mbzm/znumbers.o mbzm/zserial.o          \
	mbzm/crc16.o mbzm/crc32.o mbzm/mbzm_support.o

EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DZMODEM_LOADER -DZEMBEDDED -Imbzm/include

MBZM_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter                     \
       -Wall -Werror -Wpedantic -Wno-unused-function -O3               		  \
			 -Iinclude -I../include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)\
			 $(DEFINES)

mbzm/zheaders.o: mbzm/zheaders.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

mbzm/znumbers.o: mbzm/znumbers.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

mbzm/zserial.o: mbzm/zserial.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

mbzm/crc16.o: mbzm/crc16.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

mbzm/crc32.o: mbzm/crc32.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

mbzm/mbzm_support.o: mbzm/mbzm_support.c
	$(CC) $(MBZM_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

