# Make rosco_m68k ROM kernel
#
# Copyright (c)2023-2024 Ross Bamford & contributors
# MIT LICENSE

ifeq ($(MAKELEVEL),0)
$(error Cannot use kernel as top-level Makefile)
endif

include ../common.mk

KERNEL_DIR=.
KERNEL_FILE=kernel.a
KERNEL=$(KERNEL_DIR)/$(KERNEL_FILE)

EXTRA_CFLAGS?=-g -O1 -fomit-frame-pointer
INCLUDES=-I../stage1/include -Iinclude -Itests/include

CFLAGS+=-ffunction-sections -fdata-sections	\
		-Wall -Wextra -Wno-unused-function 	\
		-Wno-unused-parameter -Wno-format
ARFLAGS=rs

LIBOBJECTS=kmachine.o bitmap.o pmm.o slab.o list.o task.o sched.o api.o

.PHONY: all clean test

all: $(KERNEL)

$(KERNEL): $(LIBOBJECTS)
	$(AR) $(ARFLAGS) $@ $^

test:
	$(MAKE) -C tests

clean:
	$(RM) $(KERNEL) $(LIBOBJECTS)
	$(MAKE) -C tests clean
