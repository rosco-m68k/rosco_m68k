# Make rosco_m68k boostrap intro
#

SPLASH_DEBUG?=false

IMAGEBASE?=splash_green
IMAGEEXT=pcx
IMAGESRC=splash/$(IMAGEBASE).$(IMAGEEXT)

STATICLIB=intro-lib.a

OBJECTS+=splash/intro.o splash/show_pcx.o splash/delay.o splash/rand.o

DEFINES+=-DXOSERA_SPLASH
INCLUDES+=-Isplash -Isplash/include

ifeq ($(SPLASH_DEBUG), true)
OBJECTS+=splash/dprint.o
DEFINES+=SPLASH_DEBUG
endif

splash/intro.o: splash/splash.h

splash/splash.h: $(IMAGESRC)
	echo "#ifndef _SPLASH_DATA_H" > $@
	echo "#define _SPLASH_DATA_H" >> $@
	xxd -i $(IMAGESRC) | sed -E "s/$(IMAGEBASE)_$(IMAGEEXT)/data/g" | sed -E "s/splash_data\[\] =/splash_data\[\] __attribute__\(\(section\(\".rodata\"\)\)\)=/g" >> $@

	echo "#endif" >> $@

clean: clean-splash-data

clean-splash-data:
	$(RM) splash/splash.h
