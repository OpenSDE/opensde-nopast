CC=gcc
CFLAGS=-Wall -Wextra
LDFLAGS=
LIB_LDFLAGS=-ldl -shared -fPIC

FUSE_CFLAGS=$(shell pkg-config fuse --cflags)
CFLAGS += $(FUSE_CFLAGS)
FUSE_LDFLAGS=$(shell pkg-config fuse --libs)
LDFLAGS += $(FUSE_LDFLAGS)

ifeq ($(DEBUG),yes)
	CFLAGS += -DDEBUG=1
	CFLAGS += -g -O0
else
	CFLAGS += -O2
endif

FL_FUSE=fl_fuse

.PHONY: clean

$(FL_FUSE): fl_fuse.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	@rm -vf *.o
	@rm -vf fl_fuse

