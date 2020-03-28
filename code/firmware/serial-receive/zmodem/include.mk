CFLAGS := $(CFLAGS) -Imbzm/include -DZEMBEDDED
OBJECTS := $(OBJECTS) mbzm/zheaders.o mbzm/znumbers.o mbzm/zserial.o 		\
			mbzm/crcccitt.o mbzm/crc32.o zmodem/zmodem_support.o 
			