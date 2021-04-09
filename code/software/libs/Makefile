# Make rosco_m68k ROM images
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=-g -O2
DEFINES:=$(DEFINES) -DROSCO_M68K_SYSLIBS
CFLAGS=-std=c11 -ffreestanding -ffunction-sections -fdata-sections \
				-nostartfiles -Wall -pedantic -Werror \
				-mcpu=68010 -march=68010 -mtune=68010 \
				-mno-align-int -mno-strict-align $(DEFINES)
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
ARFLAGS=
CC=m68k-elf-gcc
LD=m68k-elf-ld
AR=m68k-elf-ar
RANLIB=m68k-elf-ranlib
AS=vasmm68k_mot
RM_F=rm -f
RM_RF=$(RM_F) -r
MKDIR_P=mkdir -p
CP_R=cp -r

INSTALL_DIR=./build
INSTALL_LIB=$(INSTALL_DIR)/lib
INSTALL_INC=$(INSTALL_DIR)/include

# Avoid plain "make" building only the first target encountered, causing confusion
decoy:
	@echo Please use \"make all\" to build all the libraries.

include src/cstdlib/include.mk
include src/sdfat/include.mk
include src/machine/include.mk
include src/gpio/include.mk
include src/easy68k/include.mk
include src/debug_stub/include.mk
include src/start_serial/include.mk
include src/vterm/include.mk
include src/libm/include.mk
include src/printf/include.mk

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

.PHONY: all install clean clobber

all: $(LIBS)

install: $(LIBS)
	$(MKDIR_P) $(INSTALL_INC)
	$(MKDIR_P) $(INSTALL_LIB)
	$(MKDIR_P) $(INSTALL_LIB)/ld/serial
	$(CP_R) $(INCLUDES) $(INSTALL_INC)
	$(CP_R) $(LIBS) $(INSTALL_LIB)
	$(CP_R) src/start_serial/link_scripts/* $(INSTALL_LIB)/ld/serial

clean: 
	$(RM_F) $(OBJECTS) $(LIBS)

clobber: clean
	$(RM_RF)	$(INSTALL_DIR)

