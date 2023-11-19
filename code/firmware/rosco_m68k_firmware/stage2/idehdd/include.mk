OBJECTS := $(OBJECTS) idehdd/ata.o idehdd/load.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DIDE_LOADER -Iidehdd/include
