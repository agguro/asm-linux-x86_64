MAKEFLAGS += --no-print-directory

ifeq ($(ROOT_DIR),)
    export ROOT_DIR   := $(CURDIR)
    export BUILD_MODE ?= release
    export AS        ?= nasm
    export LD        ?= /usr/bin/ld
    export AR        ?= ar
    export NASM_INC  ?= -I$(ROOT_DIR)/includes
endif

export BUILD_DIR = $(ROOT_DIR)/build/$(BUILD_MODE)
TARGET_BASE := $(notdir $(patsubst %/,%,$(CURDIR)))

# Determine target types (Removed BINARY as we only want libs)
SHARED   = $(OBJ_DIR)/$(TARGET_BASE).so
STATIC   = $(OBJ_DIR)/$(TARGET_BASE).a

ifeq ($(ROOT_DIR),$(CURDIR))
    OBJ_DIR = $(BUILD_DIR)
else
    REL_PATH = $(patsubst $(ROOT_DIR)/%,%,$(CURDIR))
    OBJ_DIR  = $(BUILD_DIR)/$(REL_PATH)
endif

OBJS = $(OBJ_DIR)/$(TARGET_BASE).o

# Flags
ifeq ($(BUILD_MODE),debug)
    ASFLAGS  = -g -F dwarf
    LST_FLAG = -l $(OBJ_DIR)/$(TARGET_BASE).lst
else
    ASFLAGS  = 
    LST_FLAG =
endif

.PHONY: all clean debug release

# Updated 'all' to only build libraries
all: $(SHARED) $(STATIC)

release:
	@$(MAKE) BUILD_MODE=release
debug:
	@$(MAKE) BUILD_MODE=debug

ifneq ($(BUILD_MODE),debug)
    .INTERMEDIATE: $(OBJS)
endif

# --- Compilation Rule ---
$(OBJS): $(TARGET_BASE).asm
	@mkdir -p $(OBJ_DIR)
	$(AS) -f elf64 $(ASFLAGS) $(NASM_INC) $(LST_FLAG) $< -o $@

# --- Shared Library (.so) ---
$(SHARED): $(OBJS)
	$(LD) -shared $(OBJS) -o $@

# --- Static Library (.a) ---
$(STATIC): $(OBJS)
	$(AR) rcs $@ $(OBJS)

clean:
	rm -rf $(ROOT_DIR)/build
