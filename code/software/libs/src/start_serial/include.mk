LIB=start_serial
LIBOBJECTS=$(DIR)/init.o $(DIR)/kinit.o

# ---===---
DIR := $(shell dirname $(lastword $(MAKEFILE_LIST)))
UPPERLIB := $(shell tr '[:lower:]' '[:upper:]' <<< $(LIB))
BINARY := lib$(LIB).a
CFLAGS  := $(CFLAGS) -DBUILD_ROSCOM68K_$(UPPERLIB)_LIB
OBJECTS := $(OBJECTS) $(LIBOBJECTS)
LIBS := $(LIBS) $(DIR)/$(BINARY)

$(DIR)/$(BINARY): $(LIBOBJECTS)
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@
