OBJECTS := $(OBJECTS) video9958/vdpcon.o video9958/font.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DVIDEO9958_CON -Ivideo9958/include
