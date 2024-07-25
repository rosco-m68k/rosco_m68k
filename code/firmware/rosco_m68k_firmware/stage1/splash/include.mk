# Make rosco_m68k boostrap intro
#

SPLASH_DEBUG?=false

STATICLIB=intro-lib.a

OBJECTS+=splash/intro.o splash/show_pcx.o splash/delay.o splash/rand.o

DEFINES+=-DXOSERA_SPLASH
INCLUDES+=-Isplash -Isplash/include

IMAGEBASE?=full_splash_03_424_8bit
IMAGEEXT=pcx
IMAGESRC=splash/$(IMAGEBASE).$(IMAGEEXT)

ifeq ($(BOARD_ROM_SIZE),1MB)
AUDIOBASE?=dropped_major_c1_shorter_11khz
HAVE_AUDIO=true
DEFINES+=-DHAVE_SPLASH_AUDIO
else ifeq ($(BOARD_ROM_SIZE),512KB)
AUDIOBASE=dropped_major_c1_shortest_11khz
HAVE_AUDIO=true
DEFINES+=-DHAVE_SPLASH_AUDIO
else
HAVE_AUDIO=false
endif
AUDIOEXT=raw
AUDIOSRC=splash/$(AUDIOBASE).$(AUDIOEXT)

ifeq ($(SPLASH_DEBUG), true)
OBJECTS+=splash/dprint.o
DEFINES+=SPLASH_DEBUG
endif

ifeq ($(HAVE_AUDIO),true)
splash/intro.o: splash/splash.h splash/bong.h
else
splash/intro.o: splash/splash.h
endif

splash/splash.h: $(IMAGESRC)
	echo "#ifndef _SPLASH_DATA_H" > $@
	echo "#define _SPLASH_DATA_H" >> $@
	xxd -i $(IMAGESRC) | sed -E "s/$(IMAGEBASE)_$(IMAGEEXT)/data/g" | sed -E "s/splash_data\[\] =/splash_data\[\] __attribute__\(\(section\(\".rodata\"\)\)\)=/g" >> $@

	echo "#endif" >> $@

ifeq ($(HAVE_AUDIO),true)
splash/bong.h: $(AUDIOSRC)
	echo "#ifndef _BONG_DATA_H" > $@
	echo "#define _BONG_DATA_H" >> $@
	xxd -i $(AUDIOSRC) | sed -E "s/splash_$(AUDIOBASE)_$(AUDIOEXT)/bong_data/g" | sed -E "s/bong_data\[\] =/bong_data\[\] __attribute__\(\(section\(\".rodata\"\)\)\)=/g" >> $@
	echo "#endif" >> $@
endif

clean: clean-splash-data

clean-splash-data:
	$(RM) splash/splash.h splash/bong.h
