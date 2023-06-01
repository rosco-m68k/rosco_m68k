# Make lcd-ili9341 GPIO example program for rosco_m68k
#
# Copyright (c) 2020-2022 Xark and contributors
# See top-level LICENSE.md for licence information.

ROSCO_M68K_DEFAULT_DIR=../../..

ifndef ROSCO_M68K_DIR
$(info NOTE: ROSCO_M68K_DIR not set, using libs: $(ROSCO_M68K_DEFAULT_DIR)/code/software/libs)
ROSCO_M68K_DIR=$(ROSCO_M68K_DEFAULT_DIR)
else
$(info NOTE: Using ROSCO_M68K_DIR libs in: $(ROSCO_M68K_DIR))
endif

-include $(ROSCO_M68K_DIR)/code/software/software.mk

EXTRA_LIBS=-lvterm

lcd-ili9341.o: images

images:
	$(MAKE) -C images

.PHONY: images
