MAKEFLAGS += --no-print-directory

# 1. Fallback voor standalone gebruik
ifeq ($(AS),as)
    AS := nasm
endif

ifeq ($(ROOT_DIR),)
    export ROOT_DIR   := $(CURDIR)
    export BUILD_MODE ?= release

    export AS        ?= nasm
    export LD        ?= /usr/bin/ld
    export NASM_INC  ?= -I$(ROOT_DIR)/includes
    export LIBS      ?= --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc $(shell pkg-config --libs x11 2>/dev/null || echo "-lX11")
endif

# ALTIJD met '=' zodat hij dynamisch meebeweegt met $(BUILD_MODE)!
export BUILD_DIR = $(ROOT_DIR)/build/$(BUILD_MODE)

TARGET := $(notdir $(patsubst %/,%,$(CURDIR)))

# 2. Paden bepalen met '=' (Dynamische evaluatie!)
ifeq ($(ROOT_DIR),$(CURDIR))
    OBJ_DIR = $(BUILD_DIR)
else
    REL_PATH = $(patsubst $(ROOT_DIR)/%,%,$(CURDIR))
    OBJ_DIR  = $(BUILD_DIR)/$(REL_PATH)
endif

BINARY   = $(OBJ_DIR)/$(TARGET)
OBJS     = $(OBJ_DIR)/$(TARGET).o

# 3. Vlaggen bepalen met '=' zodat OBJ_DIR en BUILD_MODE pas gelezen worden tijdens de build
ifeq ($(BUILD_MODE),debug)
    ASFLAGS  = -g -F dwarf
    LDFLAGS  = 
    LST_FLAG = -l $(OBJ_DIR)/$(TARGET).lst
else
    ASFLAGS  = 
    LDFLAGS  = -s
    LST_FLAG =
endif

.PHONY: all clean debug release

all: $(BINARY)

release:
	@$(MAKE) BUILD_MODE=release

debug:
	@$(MAKE) BUILD_MODE=debug

ifneq ($(BUILD_MODE),debug)
    .INTERMEDIATE: $(OBJS)
endif

$(OBJS): $(TARGET).asm
	@mkdir -p $(OBJ_DIR)
	$(AS) -f elf64 $(ASFLAGS) $(NASM_INC) $(LST_FLAG) $< -o $@

$(BINARY): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@ $(LIBS)

clean:
	rm -rf $(OBJ_DIR)

