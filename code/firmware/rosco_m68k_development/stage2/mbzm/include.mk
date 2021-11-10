OBJECTS := $(OBJECTS) mbzm/crc16.o mbzm/crc32.o mbzm/zheaders.o             \
			mbzm/znumbers.o mbzm/zserial.o mbzm/zmodem_support.o            \
			mbzm/printf.o mbzm/putchar.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -Imbzm/include -DZMODEM_LOADER -DZEMBEDDED  \
			-DPRINTF_INCLUDE_CONFIG_H -DPRINTF_DISABLE_SUPPORT_FLOAT -DZDEBUG

