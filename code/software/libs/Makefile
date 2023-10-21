# Make rosco_m68k libraries
# 
# Copyright (c) 2020 Ross Bamford
# See LICENSE

CPU?=68010
EXTRA_CFLAGS?=-g -O2
EXTRA_CXXFLAGS?=-g -O2
DEFINES:=$(DEFINES) -DROSCO_M68K_SYSLIBS
FLAGS=-ffreestanding -ffunction-sections -fdata-sections	\
			-nostartfiles       				\
			-mcpu=$(CPU) -march=$(CPU) -mtune=$(CPU)    				\
			$(DEFINES)
CFLAGS=-std=gnu11 $(FLAGS)
CXXFLAGS=-std=c++20 -fno-exceptions -fno-rtti $(FLAGS)
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES)
ARFLAGS=
CC=m68k-elf-gcc
CXX=m68k-elf-g++
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

UBERLIB=librosco_m68k.a

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
include src/sst_flash/include.mk
include src/shmall/include.mk
include src/kernel/include.mk
include src/printf/include.mk
include src/gdb/include.mk

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) $(EXTRA_CXXFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

.PHONY: all install clean clobber

all: $(UBERLIB) $(LIBS)

$(UBERLIB): $(filter-out **/printf-*.o, $(OBJECTS))
	$(AR)	$(ARFLAGS) rs $@ $^
	$(RANLIB) $@

install: $(UBERLIB) $(LIBS)
	$(MKDIR_P) $(INSTALL_INC)
	$(MKDIR_P) $(INSTALL_LIB)
	$(MKDIR_P) $(INSTALL_LIB)/ld/serial
	$(CP_R) $(INCLUDES) $(INSTALL_INC)
	$(CP_R) $(LIBS) $(INSTALL_LIB)
	$(CP_R) $(UBERLIB) $(INSTALL_LIB)
	$(CP_R) src/start_serial/link_scripts/* $(INSTALL_LIB)/ld/serial

clean: 
	$(RM_F) $(OBJECTS) $(LIBS) $(UBERLIB)

clobber: clean
	$(RM_RF)	$(INSTALL_DIR)

