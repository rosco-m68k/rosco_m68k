OBJECTS := $(OBJECTS) videoXoseraANSI/xosera_ansiterm_init.o videoXoseraANSI/xosera_ansiterm_m68k.o videoXoseraANSI/xosera_m68k_api.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DXOSERA_ANSI_CON -IvideoXoseraANSI
