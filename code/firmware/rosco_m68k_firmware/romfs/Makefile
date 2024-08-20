DD?=dd
MFORMAT?=mformat
MCOPY?=mcopy

ROSCO_CODE?=../../..
ROSCO_SOFT?=$(ROSCO_CODE)/software

COMMON_FILES=										\
	micropython/rosco_m68k/build/upyrosco.bin		\
	$(ROSCO_SOFT)/memcheck/memcheck.bin

MENU_360?=menu_360.txt
MENU_720?=menu_720.txt

FILES_360?=											\
	$(COMMON_FILES)

FILES_720?=											\
	$(COMMON_FILES)

BLOCKSIZE?=4096

IMAGE_PRE?=romfs_
IMAGE_SUF?=.lfs

IMAGE_360=$(IMAGE_PRE)360$(IMAGE_SUF)
IMAGE_720=$(IMAGE_PRE)720$(IMAGE_SUF)

STAGING=staging
STAGING_360=$(STAGING)_360
STAGING_720=$(STAGING)_720

MKLITTLEFS_DIR?=mklittlefs
MKLITTLEFS_CMD?=mklittlefs
MKLITTLEFS=$(MKLITTLEFS_DIR)/$(MKLITTLEFS_CMD)

.PHONY: all clean

all: $(IMAGE_360) $(IMAGE_720)

$(IMAGE_360): $(STAGING_360) $(MKLITTLEFS)
	$(MKLITTLEFS) -c $< -b $(BLOCKSIZE) -s 368640 $@

$(IMAGE_720): $(STAGING_720) $(MKLITTLEFS)
	$(MKLITTLEFS) -c $< -b $(BLOCKSIZE) -s 737280 $@

$(STAGING_360): $(MENU_360) $(FILES_360)
	mkdir -p $@
	cp -r $^ $@
	mv $@/$(MENU_360) $@/menu.txt

$(STAGING_720): $(MENU_720) $(FILES_720)
	mkdir -p $@
	cp -r $^ $@
	mv $@/$(MENU_720) $@/menu.txt

micropython/rosco_m68k/build/upyrosco.bin:
	$(MAKE) -C micropython/rosco_m68k all

%.bin: $(ROSCO_SOFT)/libs/build
	$(MAKE) -C $(dir $@) $(notdir $@)

$(ROSCO_SOFT)/libs/build:
	$(MAKE) -C $(dir $@) install

$(MKLITTLEFS):
	$(MAKE) -C $(MKLITTLEFS_DIR) $(MKLITTLEFS_CMD)

clean:
	rm -rf $(IMAGE_360) $(IMAGE_720) $(STAGING_360) $(STAGING_720)
	$(MAKE) -C micropython/rosco_m68k clean

clobber: clean
	$(MAKE) -C $(ROSCO_SOFT)/sdfat_menu clean
	$(MAKE) -C $(ROSCO_SOFT)/memcheck clean
	$(MAKE) -C mklittlefs clean

