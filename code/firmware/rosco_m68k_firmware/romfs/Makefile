DD?=dd
MFORMAT?=mformat
MCOPY?=mcopy

ROSCO_CODE?=../../..
ROSCO_SOFT?=$(ROSCO_CODE)/software

COMMON_FILES=										\
	micropython/rosco_m68k/build/upyrosco.bin		\
	$(ROSCO_SOFT)/sdfat_menu/sdfat_menu.bin			\
	$(ROSCO_SOFT)/memcheck/memcheck.bin

MENU_360?=menu_360.txt
MENU_720?=menu_720.txt

FILES_360?=											\
	$(COMMON_FILES)

FILES_720?=											\
	$(COMMON_FILES)

IMAGE_PRE?=romfs_
IMAGE_SUF?=.fat

IMAGE_360=$(IMAGE_PRE)360$(IMAGE_SUF)
IMAGE_720=$(IMAGE_PRE)720$(IMAGE_SUF)

.PHONY: all clean

all: romfs_360.fat romfs_720.fat

$(IMAGE_360): $(FILES_360)
	$(DD) if=/dev/zero of=$@ bs=360K count=1
	$(MFORMAT) -F -i $@ -v ROMFS -f 360 -c 1 ::
	$(MCOPY) -i $@ $(MENU_360) ::menu.txt
	$(MCOPY) -i $@ $(FILES_360) ::
	mren -i romfs_360.fat ::upyrosco.bin ::ROSCODE1.BIN

$(IMAGE_720): $(FILES_360)
	$(DD) if=/dev/zero of=$@ bs=720K count=1
	$(MFORMAT) -F -i $@ -v ROMFS -f 720 -c 1 ::
	$(MCOPY) -i $@ $(MENU_720) ::menu.txt
	$(MCOPY) -i $@ $(FILES_720) ::

micropython/rosco_m68k/build/upyrosco.bin:
	$(MAKE) -C micropython/rosco_m68k all

%.bin: $(ROSCO_SOFT)/libs/build
	$(MAKE) -C $(dir $@) $(notdir $@)

$(ROSCO_SOFT)/libs/build:
	$(MAKE) -C $(dir $@) install

clean:
	rm -rf $(IMAGE_360) $(IMAGE_720)

clobber: clean
	$(MAKE) -C $(ROSCO_SOFT)/sdfat_menu clean
	$(MAKE) -C $(ROSCO_SOFT)/memcheck clean
	$(MAKE) -C micropython/rosco_m68k clean

