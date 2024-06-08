OBJECTS+=									\
	videoXoseraANSI/xosera_ansiterm_init.o	\
	videoXoseraANSI/xosera_ansiterm_m68k.o	\
	videoXoseraANSI/xosera_m68k_api.o
DEFINES+=-DXOSERA_API_MINIMAL
INCLUDES+=-IvideoXoseraANSI
