MAKEFLAGS += --no-print-directory

ifeq ($(NASMENV),)
    $(error [FATAL] NASMENV is not defined.)
endif

ifeq ($(ROOT_DIR),)
    export ROOT_DIR   := $(CURDIR)
    export BUILD_MODE ?= release

    export AS        := nasm
    export LD        := /usr/bin/ld
    export NASM_INC  := -I$(ROOT_DIR)/includes

    ifeq ($(BUILD_MODE),debug)
        export ASFLAGS := -g -F dwarf
        export LDFLAGS := --as-needed
    else
        export ASFLAGS :=
        export LDFLAGS := -s --as-needed
    endif
endif

export LIBS ?= --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc
export BUILD_DIR = $(ROOT_DIR)/build/$(BUILD_MODE)

SUBDIRS := $(sort $(dir $(wildcard */Makefile)))

.PHONY: all clean debug release $(SUBDIRS)

all: $(SUBDIRS)

release:
	@$(MAKE) BUILD_MODE=release all

debug:
	@$(MAKE) BUILD_MODE=debug all

$(SUBDIRS):
	@$(MAKE) -C $@

clean:
	rm -rf $(BUILD_DIR)
