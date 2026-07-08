# root/utils/strings/Makefile

MAKEFLAGS += --no-print-directory

# 1. Root Discovery
ROOT_DIR := $(shell while [ ! -d includes ]; do cd ..; if [ "$$(pwd)" = "/" ]; then break; fi; done; pwd)
-include $(ROOT_DIR)/build.mk

# 2. Defaults
export AS        ?= as
export LD        ?= ld
export AR        ?= ar
export AS_INC    ?= -I$(ROOT_DIR)/includes

BUILD_MODE ?= release
export BUILD_DIR := $(ROOT_DIR)/build/$(BUILD_MODE)

# 3. Dynamic Name Selection (Must be defined BEFORE 'all')
ifeq ($(BUILD_MODE),debug)
    TARGET := lib$(notdir $(CURDIR))-dev.a
else
    TARGET := lib$(notdir $(CURDIR)).a
endif

# 4. Pathing
REL_PATH := $(shell realpath --relative-to=$(ROOT_DIR) . 2>/dev/null || echo ".")
OBJ_DIR  := $(ROOT_DIR)/build/$(BUILD_MODE)/objs/$(REL_PATH)
BIN_DIR  := $(ROOT_DIR)/build/$(BUILD_MODE)/bin

# 5. Target Definitions
SRCS     := $(wildcard *.s)
OBJS     := $(patsubst %.s, $(OBJ_DIR)/%.o, $(SRCS))

# 6. Flags
ifeq ($(BUILD_MODE),debug)
    BASE_ASFLAGS := --gstabs+
else
    BASE_ASFLAGS := 
endif

# 7. Rules
.PHONY: all clean debug release

all: $(BIN_DIR)/$(TARGET)

release:
	@$(MAKE) BUILD_MODE=release all

debug:
	@$(MAKE) BUILD_MODE=debug all

$(BIN_DIR)/$(TARGET): $(OBJS)
	@mkdir -p $(@D)
	$(AR) rcs $@ $^

$(OBJ_DIR)/%.o: %.s
	@mkdir -p $(@D)
	$(AS) $(BASE_ASFLAGS) $(if $(filter debug,$(BUILD_MODE)),-a=$(patsubst %.o,%.lst,$@),) $(AS_INC) $< -o $@

clean:
	rm -rf $(ROOT_DIR)/build/release/objs/$(REL_PATH)
	rm -rf $(ROOT_DIR)/build/debug/objs/$(REL_PATH)
	rm -f $(ROOT_DIR)/build/release/bin/lib$(notdir $(CURDIR)).a
	rm -f $(ROOT_DIR)/build/debug/bin/lib$(notdir $(CURDIR))-dev.a
