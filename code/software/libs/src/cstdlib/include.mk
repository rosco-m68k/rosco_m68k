LIB=cstdlib
LIBOBJECTS=$(DIR)/string.o $(DIR)/fgets.o
LIBINCLUDES=$(DIR)/include

# ---===---
DIR := $(shell dirname $(lastword $(MAKEFILE_LIST)))
UPPERLIB := $(shell tr '[:lower:]' '[:upper:]' <<< $(LIB))
BINARY := lib$(LIB).a
CFLAGS  := $(CFLAGS) -I$(LIBINCLUDES) -DBUILD_ROSCOM68K_$(UPPERLIB)_LIB
OBJECTS := $(OBJECTS) $(LIBOBJECTS)
INCLUDES := $(INCLUDES) $(DIR)/include/*
LIBS := $(LIBS) $(DIR)/$(BINARY)

$(DIR)/$(BINARY): $(LIBOBJECTS)
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@
