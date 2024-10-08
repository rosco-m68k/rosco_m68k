# Make concept loader for rosco_m68k
#
# vim: set noet ts=8 sw=8
# Portions copyright (c) 2021 Xark
# MIT LICENSE
#

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

FLAGS=-ffunction-sections -fdata-sections -fomit-frame-pointer						\
      -Wall -Wextra -Werror -Wno-unused-function -pedantic							\
      -g -O2 $(DEFINES)

CFLAGS=-std=c2x -Wno-format -Iwelcome/include $(FLAGS)
CXXFLAGS=-std=c++20 -fno-exceptions -fno-rtti $(FLAGS)
ASFLAGS=-mcpu=$(CPU) -march=$(ARCH)
VASMFLAGS=-Felf -m$(CPU) -quiet -Lnf -I $(XOSERA_M68K_API) $(DEFINES)
LDFLAGS=-Wl,--gc-sections
EXTRA_CFLAGS?=
DEFINES?=

EXTRA_LIBS?=
LIBS=$(EXTRA_LIBS) -lxosera_m68k

CC=m68k-elf-rosco-gcc
LD=m68k-elf-rosco-gcc
AR=m68k-elf-rosco-ar
RANLIB=m68k-elf-rosco-ranlib
NM=m68k-elf-rosco-nm
OBJDUMP=m68k-elf-rosco-objdump
OBJCOPY=m68k-elf-rosco-objcopy
SIZE=m68k-elf-rosco-size
VASM=vasmm68k_mot
CHMOD=chmod
MKDIR=mkdir
LSOF=lsof
RM=rm -f
CP=cp

COPASM=$(XOSERA_M68K_API)/bin/copasm

# GCC-version-specific settings
ifneq ($(findstring GCC,$(shell $(CC) --version 2>/dev/null)),)
CC_VERSION:=$(shell $(CC) -dumpfullversion)
CC_MAJOR:=$(firstword $(subst ., ,$(CC_VERSION)))
# If this is GCC 12, 13, or 14, add flag --param=min-pagesize=0 to CFLAGS
ifeq ($(CC_MAJOR),12)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),13)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),14)
CFLAGS+=--param=min-pagesize=0
endif
endif

ifeq ($(FIRMWARE_BUILD), true)
DEFINES+=-DROSCO_M68K_FIRMWARE
endif

ifeq ($(ENABLE_ANIM),true)
DEFINES+=-DENABLE_ANIM
endif
export ENABLE_ANIM

ifeq ($(TEST_ANIM),true)
DEFINES+=-DSHOW_TEST_ANIM
endif
export TEST_ANIM

ifeq ($(ENABLE_TIMER),true)
DEFINES+=-DENABLE_TIMER
endif
export ENABLE_TIMER

ifeq ($(MODEL_DEBUG),true)
DEFINES+=-DMODEL_DEBUG
endif
export MODEL_DEBUG

ifeq ($(BLIT_DEBUG),true)
DEFINES+=-DBLIT_DEBUG
endif
export BLIT_DEBUG

ifeq ($(TEST_PATTERN),true)
DEFINES+=-DTEST_PATTERN_DEBUG
endif
export TEST_PATTERN

ifeq ($(BIZCAT),true)
DEFINES+=-DALWAYS_BIZCAT
endif
export BIZCAT

ifeq ($(TOPAZ),true)
DEFINES+=-DALWAYS_TOPAZ
endif
export TOPAZ

ifneq ($(HRES),)
DEFINES+=-DVIEW_HRES=$(HRES)
endif
export HRES

ifneq ($(VRES),)
DEFINES+=-DVIEW_VRES=$(VRES)
endif
export VRES

# GCC-version-specific settings
ifneq ($(findstring GCC,$(shell $(CC) --version 2>/dev/null)),)
CC_VERSION:=$(shell $(CC) -dumpfullversion)
CC_MAJOR:=$(firstword $(subst ., ,$(CC_VERSION)))
# If this is GCC 12 or 13, add flag --param=min-pagesize=0 to CFLAGS
ifeq ($(CC_MAJOR),12)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),13)
CFLAGS+=--param=min-pagesize=0
endif
endif

# For systems without MMU support, aligning LOAD segments with pages is not needed
# In those cases, provide fake page sizes to both save space and remove RWX warnings
ifeq ($(CPU),68030)
LD_LD_SUPPORT_MMU?=true
endif
ifeq ($(CPU),68040)
LD_SUPPORT_MMU?=true
endif
ifeq ($(CPU),68060)
LD_SUPPORT_MMU?=true
endif
LD_SUPPORT_MMU?=false
ifneq ($(LD_SUPPORT_MMU),true)
# Saves space in binaries, but will break MMU use
LDFLAGS+=-z max-page-size=16 -z common-page-size=16
endif

# Output config (assume name of directory)
PROGRAM_BASENAME=$(shell basename $(CURDIR))

# Set other output files using output basname
LIB=lib$(PROGRAM_BASENAME).a
ELF=$(PROGRAM_BASENAME).elf
BINARY=$(PROGRAM_BASENAME).bin
DISASM=$(PROGRAM_BASENAME).dis
MAP=$(PROGRAM_BASENAME).map
SYM=$(PROGRAM_BASENAME).sym
SYM_SIZE=$(PROGRAM_BASENAME)_size.sym

CASMSOURCES=$(wildcard *.casm)
CPASMSOURCES=$(wildcard *.cpasm)
CASMOUTPUT=$(addsuffix .h,$(basename $(CASMSOURCES) $(CPASMSOURCES)))
# Assume source files in Makefile directory are source files for project
CSOURCES=$(wildcard *.c)
CXXSOURCES=$(wildcard *.cpp)
CINCLUDES=$(wildcard *.h)
SSOURCES=$(wildcard *.S)
ASMSOURCES=$(wildcard *.asm)
RAWSOURCES=$(wildcard *.raw)
SOURCES+=$(CSOURCES) $(CXXSOURCES) $(SSOURCES) $(ASMSOURCES) $(RAWSOURCES)
# Assume each source files makes an object file
OBJECTS=$(addsuffix .o,$(basename $(SOURCES)))

TO_CLEAN=$(OBJECTS) $(ELF) $(BINARY) $(LIB) $(MAP) $(SYM) $(SYM_SIZE) $(DISASM) $(addsuffix .casm.ii,$(basename $(CPASMSOURCES))) $(CASMOUTPUT) $(addsuffix .lst,$(basename $(SSOURCES) $(ASMSOURCES) $(CASMSOURCES)))

.PHONY: all clean tests

all: tests $(BINARY) $(DISASM) sdl2/test

$(LIB) : $(OBJECTS)
	$(AR)   $(ARFLAGS) $@ $^
	$(RANLIB) $@

$(ELF) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@
	$(NM) --numeric-sort $@ >$(SYM)
	$(NM) --size-sort $@ >$(SYM_SIZE)
	$(SIZE) $@
	-$(CHMOD) a-x $@

$(BINARY) : $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BINARY)

$(DISASM) : $(ELF)
	$(OBJDUMP) --disassemble -S $(ELF) >$(DISASM)

$(OBJECTS): $(CASMOUTPUT) $(MAKEFILE_LIST)

%.o : %.c $(CINCLUDES)
	@$(MKDIR) -p $(@D)
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.cpp
	@$(MKDIR) -p $(@D)
	$(CXX) -c $(CXXFLAGS) $(EXTRA_CXXFLAGS) -o $@ $<

%.o : %.asm
	@$(MKDIR) -p $(@D)
	$(VASM) $(VASMFLAGS) $(EXTRA_VASMFLAGS) -L $(basename $@).lst -o $@ $<

# CopAsm copper source
%.h : %.casm
	@$(MKDIR) -p $(@D)
	$(COPASM) -v -l -i $(XOSERA_M68K_API) -o $@ $<

# preprocessed CopAsm copper source
%.h : %.cpasm
	@$(MKDIR) -p $(@D)
	$(CC) -E -xc -D__COPASM__=1 -I$(XOSERA_M68K_API) $< -o $(basename $<).casm.ii
	$(COPASM) -v -l -i $(XOSERA_M68K_API) -o $@ $(basename $<).casm.ii

clean: cleansdl cleantests
	rm -rf $(TO_CLEAN)

tests: tests/Makefile	
	make -C tests test

sdl2/test: tests sdl2/Makefile $(OBJECTS)
	make -C sdl2 test

cleantests:
	make -C tests clean

cleansdl:
	make -C sdl2 clean

