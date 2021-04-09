# Make rosco_m68k rebuilds everything under "software"
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

LIBSTARG = clean all install
SOFTWARETARG = clean all

SOFTWARE := $(subst /.,,$(filter-out libs/.,$(wildcard */.)))

all: libs $(SOFTWARE)

clean: LIBSTARG = clean
clean: SOFTWARETARG = clean
clean: libs $(SOFTWARE)

libs:
				@echo =
				@echo === installing rosco_m68k libs
				@echo = 
				$(MAKE) -C libs $(LIBSTARG)

software: $(SOFTWARE)

$(SOFTWARE): libs
				@echo =
				@echo = $@
				@echo = 
				$(MAKE)	-C $@ $(SOFTWARETARG)

.PHONY:	all clean libs $(SOFTWARE)
