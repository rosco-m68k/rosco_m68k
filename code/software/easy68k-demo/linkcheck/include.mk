CFLAGS := $(CFLAGS) -DPERFORM_LINKAGE_CHECK -Ilinkcheck
CSOURCES+=$(wildcard linkcheck/*.c)
CINCLUDES+=$(wildcard linkcheck/include/*.h)
