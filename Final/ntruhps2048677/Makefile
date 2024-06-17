
include make_opt.mk

COMMON_HEADERs = hal.h params.h
COMMON_SOURCEs = hal-cortexa.c

OPT_HEADERs = $(C_HEADERs) $(ASM_HEADERs)
OPT_SOURCEs = $(C_SOURCEs) $(ASM_SOURCEs)

HEADERs = $(COMMON_HEADERs) $(OPT_HEADERs)
SOURCEs = $(COMMON_SOURCEs) $(OPT_SOURCEs)

all: test speed

ori: test speed
acc: test_acc speed_acc

test: $(HEADERs) $(SOURCEs) test.c
	$(CC) $(CFLAGS) -o test test.c $(SOURCEs)

speed: $(HEADERs) $(SOURCEs) speed.c
	$(CC) $(CFLAGS) -o speed speed.c $(SOURCEs)

include ../common/make.mk

.PHONY: clean

clean:
	rm -f test
	rm -f speed


