EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DXOSERA_API_MINIMAL -IvideoXoseraANSI
OBJECTS := $(OBJECTS) videoXoseraANSI/xosera_ansiterm_init.o videoXoseraANSI/xosera_ansiterm_m68k.o videoXoseraANSI/xosera_m68k_api.o
