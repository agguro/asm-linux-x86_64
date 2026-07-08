MAKEFLAGS += --no-print-directory

ifeq ($(NASMENV),)
    $(error [FATAL] NASMENV is not defined.)
endif

# 1. Omgevings-fallback voor standalone gebruik
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

# 2. Garandeer de dynamische BUILD_DIR switch
export BUILD_DIR = $(ROOT_DIR)/build/$(BUILD_MODE)

# 3. Vangnet voor de basis-libs (Dynamic linker + libc)
ifeq ($(findstring -lc,$(LIBS)),)
    export LIBS += --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc
endif

# 4. Keten-aanvulling voor GTK3 (Voegt ALTIJD de GTK-vlaggen toe)
ifeq ($(findstring -lgtk-3,$(LIBS)),)
    export LIBS += $(shell pkg-config --libs gtk+-3.0 2>/dev/null || echo "-lgtk-3 -lgdk-3 -lgobject-2.0 -lglib-2.0")
endif

# 5. Submappen scannen en targets afhandelen
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
	rm -rf $(ROOT_DIR)/build