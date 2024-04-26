OBJECTS := $(OBJECTS) idehdd/ata.o idehdd/load.o
DEFINES+=-DIDE_LOADER
INCLUDES+=-Iidehdd/include
