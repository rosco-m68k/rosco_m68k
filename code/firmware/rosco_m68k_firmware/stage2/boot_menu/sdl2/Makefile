CFLAGS=$(shell pkg-config --cflags sdl2) -I.. -g
LDFLAGS=$(shell pkg-config --libs sdl2)
EXTRA_CFLAGS=

ifeq ($(ENABLE_ANIM),true)
EXTRA_CFLAGS+=-DENABLE_ANIM
endif

ifeq ($(TEST_ANIM),true)
EXTRA_CFLAGS+=-DSHOW_TEST_ANIM
endif

ifeq ($(ENABLE_TIMER),true)
EXTRA_CFLAGS+=-DENABLE_TIMER
endif

ifeq ($(MODEL_DEBUG),true)
EXTRA_CFLAGS+=-DMODEL_DEBUG
endif

ifeq ($(BLIT_DEBUG),true)
EXTRA_CFLAGS+=-DBLIT_DEBUG
endif

ifeq ($(TEST_PATTERN),true)
EXTRA_CFLAGS+=-DTEST_PATTERN_DEBUG
endif

ifeq ($(BIZCAT),true)
EXTRA_CFLAGS+=-DALWAYS_BIZCAT
endif

ifeq ($(TOPAZ),true)
EXTRA_CFLAGS+=-DALWAYS_TOPAZ
endif

ifneq ($(HRES),)
EXTRA_CFLAGS+=-DVIEW_HRES=$(HRES)
endif

ifneq ($(VRES),)
EXTRA_CFLAGS+=-DVIEW_VRES=$(VRES)
endif

.PHONY: all clean

all: test

clean:
	rm -rf *.o test

%.o: ../%.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

sdl_backend.o: sdl_backend.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

test: main.o model.o view.o controller.o list.o test_anim.o sdl_backend.o
	$(CC) $(LDFLAGS) -o $@ $^
