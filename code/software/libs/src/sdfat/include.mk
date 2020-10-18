DIR := $(shell dirname $(lastword $(MAKEFILE_LIST)))

LIB=sdfat
LIBINCLUDES=$(DIR)/include
LIBOBJECTS := $(DIR)/sdcard.o $(DIR)/sdcard_asm.o														\
	$(DIR)/fat_io_lib/fat_access.o $(DIR)/fat_io_lib/fat_cache.o							\
	$(DIR)/fat_io_lib/fat_filelib.o $(DIR)/fat_io_lib/fat_format.o						\
	$(DIR)/fat_io_lib/fat_misc.o $(DIR)/fat_io_lib/fat_string.o								\
	$(DIR)/fat_io_lib/fat_table.o $(DIR)/fat_io_lib/fat_write.o

#DIR := $(shell dirname $(lastword $(MAKEFILE_LIST)))
UPPERLIB := $(shell echo $(LIB) | tr '[:lower:]' '[:upper:]')
BINARY := lib$(LIB).a
CFLAGS  := $(CFLAGS) -I$(LIBINCLUDES) -DBUILD_ROSCOM68K_$(UPPERLIB)_LIB			\
					 -DFATFS_USE_CUSTOM_OPTS_FILE -Wno-unused-function
OBJECTS := $(OBJECTS) $(LIBOBJECTS)
INCLUDES := $(INCLUDES) $(DIR)/include/*
LIBS := $(LIBS) $(DIR)/$(BINARY)

$(DIR)/$(BINARY): $(LIBOBJECTS)
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@

