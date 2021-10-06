CFLAGS := $(CFLAGS) -DPERFORM_LINKAGE_CHECK -Ilinkcheck/include
CSOURCES+=$(wildcard linkcheck/*.c)
CINCLUDES+=$(wildcard linkcheck/include/*.h)
