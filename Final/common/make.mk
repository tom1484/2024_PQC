


CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
	-Wshadow -Wno-unused-result \
	-mtune=native -mcpu=native -O3


CC ?= gcc
CPP ?= cpp
AR ?= ar
LD ?= $(CC)
OBJCOPY ?= objcopy
SIZE ?= size


