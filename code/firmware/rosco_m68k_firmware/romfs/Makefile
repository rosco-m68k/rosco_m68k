DD?=dd
MFORMAT?=mformat
MCOPY?=mcopy

ROSCO_CODE?=../../..
ROSCO_SOFT?=$(ROSCO_CODE)/software

COMMON_FILES=										\
	micropython/rosco_m68k/build/upyrosco.bin		\
	$(ROSCO_SOFT)/memcheck/memcheck.bin

MENU_320?=menu_320.txt
MENU_640?=menu_640.txt

FILES_320?=											\
	$(COMMON_FILES)

FILES_640?=											\
	$(COMMON_FILES)

BLOCKSIZE?=8192

IMAGE_PRE?=romfs_
IMAGE_SUF?=.lfs

IMAGE_320=$(IMAGE_PRE)320$(IMAGE_SUF)
IMAGE_640=$(IMAGE_PRE)640$(IMAGE_SUF)

STAGING=staging
STAGING_320=$(STAGING)_320
STAGING_640=$(STAGING)_640

MKLITTLEFS_DIR?=mklittlefs
MKLITTLEFS_CMD?=mklittlefs
MKLITTLEFS=$(MKLITTLEFS_DIR)/$(MKLITTLEFS_CMD)

.PHONY: all clean

all: $(IMAGE_320) $(IMAGE_640)

$(IMAGE_320): $(STAGING_320) $(MKLITTLEFS)
	$(MKLITTLEFS) -c $< -b $(BLOCKSIZE) -s 327680 $@

$(IMAGE_640): $(STAGING_640) $(MKLITTLEFS)
	$(MKLITTLEFS) -c $< -b $(BLOCKSIZE) -s 655360 $@

$(STAGING_320): $(MENU_320) $(FILES_320)
	mkdir -p $@
	cp -r $^ $@
	mv $@/$(MENU_320) $@/menu.txt

$(STAGING_640): $(MENU_640) $(FILES_640)
	mkdir -p $@
	cp -r $^ $@
	mv $@/$(MENU_640) $@/menu.txt

micropython/rosco_m68k/build/upyrosco.bin:
	$(MAKE) -C micropython/rosco_m68k all

%.bin: $(ROSCO_SOFT)/libs/build
	$(MAKE) -C $(dir $@) $(notdir $@)

$(ROSCO_SOFT)/libs/build:
	$(MAKE) -C $(dir $@) install

$(MKLITTLEFS):
	$(MAKE) -C $(MKLITTLEFS_DIR) $(MKLITTLEFS_CMD)

clean:
	rm -rf $(IMAGE_320) $(IMAGE_640) $(STAGING_320) $(STAGING_640)
	$(MAKE) -C micropython/rosco_m68k clean

clobber: clean
	$(MAKE) -C $(ROSCO_SOFT)/sdfat_menu clean
	$(MAKE) -C $(ROSCO_SOFT)/memcheck clean
	$(MAKE) -C mklittlefs clean

