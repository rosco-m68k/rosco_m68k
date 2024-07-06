include ../core/py/mkenv.mk

# Include py core make definitions.
include $(TOP)/py/py.mk
include $(TOP)/extmod/extmod.mk

CROSS_COMPILE ?= m68k-elf-rosco-
RANLIB=$(CROSS_COMPILE)ranlib
OBJCOPY=$(CROSS_COMPILE)objcopy

INC += -I.
INC += -I$(TOP)
INC += -I$(BUILD)

# Set CFLAGS and libraries.
CFLAGS_M68K = -mcpu=68000 -march=68000 -mtune=68000 -DMICROPY_GCREGS_SETJMP=1
CFLAGS = $(INC) -Wall -Werror -Wno-attributes -Wno-return-type -std=c99 $(CFLAGS_M68K) $(COPT)
LDFLAGS = -Wl,-Map=$@.map,--cref $(CFLAGS_M68K) -lm

BASENAME=upyrosco
LIB_BASE=upy_rosco

# Define the required source files.
SRC_C = 										\
    main.c										\
    mphalport.c									\
    shared/readline/readline.c					\
    shared/runtime/gchelper_generic.c			\
    shared/runtime/pyexec.c						\
    shared/runtime/stdout_helpers.c				\

# Define source files containung qstrs.
SRC_QSTR += shared/readline/readline.c shared/runtime/pyexec.c

OBJ = $(PY_CORE_O) $(addprefix $(BUILD)/, $(SRC_C:.c=.o))

all: $(BUILD)/$(BASENAME).bin

$(BUILD)/$(LIB_BASE).a: $(OBJ)
	$(AR)   $(ARFLAGS) $@ $^
	$(RANLIB) $@

$(BUILD)/$(BASENAME).elf: $(OBJ)
	$(ECHO) "LINK $@"
	$(Q)$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)
	$(Q)$(SIZE) $@

$(BUILD)/$(BASENAME).bin: $(BUILD)/$(BASENAME).elf
	$(OBJCOPY) -O binary $< $@

# Include remaining core make rules.
include $(TOP)/py/mkrules.mk
