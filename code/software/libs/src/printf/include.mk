LIB=printf
LIBOBJECTS=$(DIR)/putchar.o
LIBINCLUDES=$(DIR)/include
LOCAL_DEFINES=-DPRINTF_INCLUDE_CONFIG_H

# ---===---
DIR := $(shell dirname $(lastword $(MAKEFILE_LIST)))
UPPERLIB := $(shell echo $(LIB) | tr '[:lower:]' '[:upper:]')
SOFTFLOAT_BINARY := lib$(LIB)-softfloat.a
NOFLOAT_BINARY := lib$(LIB).a
CFLAGS  := $(CFLAGS) -I$(LIBINCLUDES) -DBUILD_ROSCOM68K_$(UPPERLIB)_LIB $(LOCAL_DEFINES)
OBJECTS := $(OBJECTS) $(LIBOBJECTS)
INCLUDES := $(INCLUDES) $(DIR)/include/*
LIBS := $(LIBS) $(DIR)/$(SOFTFLOAT_BINARY) $(DIR)/$(NOFLOAT_BINARY)

printfs: $(DIR)/$(SOFTFLOATBINARY) $(DIR)/$(NOFLOATBINARY)

$(DIR)/printf-softfloat.o:
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $(DIR)/printf-softfloat.o $(DIR)/printf.c

$(DIR)/printf-nofloat.o:
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -DPRINTF_DISABLE_SUPPORT_FLOAT -o $(DIR)/printf-nofloat.o $(DIR)/printf.c

$(DIR)/$(SOFTFLOAT_BINARY): $(LIBOBJECTS) $(DIR)/printf-softfloat.o
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@

$(DIR)/$(NOFLOAT_BINARY): $(LIBOBJECTS) $(DIR)/printf-nofloat.o
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@

