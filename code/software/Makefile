# Make rosco_m68k rebuilds everything under "software"
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

SOFTWARE := $(filter-out libs,$(wildcard */.))

all: libs $(SOFTWARE)

libs:
				@echo === Rebuilding and installing rosco_m68 libraries
				$(MAKE) -C libs clean all install

software: $(SOFTWARE)

$(SOFTWARE): libs
				@echo === Rebuilding $@
				$(MAKE)	-C $@ clean all

.PHONY:	all libs $(SOFTWARE)
