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

export LIBS ?= --dynamic-linker /lib64/ld-linux-x86-64.so.2
export BUILD_DIR = $(ROOT_DIR)/build/$(BUILD_MODE)

# 1. Get all directories containing a Makefile
ALL_DIRS := $(sort $(dir $(wildcard */Makefile)))

# 2. Separate libraries (dirs starting with 'lib') and others (apps/demos)
LIB_DIRS := $(filter lib%/, $(ALL_DIRS))
APP_DIRS := $(filter-out lib%/, $(ALL_DIRS))

# 3. Define the build order: Libraries FIRST, then Applications
SUBDIRS := $(LIB_DIRS) $(APP_DIRS)

.PHONY: all clean debug release $(SUBDIRS)

# Build SUBDIRS in the ordered sequence
all: $(SUBDIRS)

release:
	@$(MAKE) BUILD_MODE=release all

debug:
	@$(MAKE) BUILD_MODE=debug all

# This rule executes make in each subdirectory
$(SUBDIRS):
	@$(MAKE) -C $@

clean:
	rm -rf $(ROOT_DIR)/build
