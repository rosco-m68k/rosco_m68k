# Make rosco_m68k example program for C
#
# Copyright (c) 2020-2022 Xark and contributors
# MIT LICENSE

ROSCO_M68K_DEFAULT_DIR=../../..

ifndef ROSCO_M68K_DIR
$(info NOTE: ROSCO_M68K_DIR not set, using libs: ../../../code/software/libs)
ROSCO_M68K_DIR=$(ROSCO_M68K_DEFAULT_DIR)
else
$(info NOTE: Using ROSCO_M68K_DIR libs in: $(ROSCO_M68K_DIR))
endif

-include $(ROSCO_M68K_DIR)/code/software/software.mk

EXTRA_CFLAGS=
EXTRA_LIBS=
# EXTRA_VASMFLAGS?=-showopt
