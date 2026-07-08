# root/Makefile
BUILD_MODE ?= release
BUILD_BASE := build/$(BUILD_MODE)
AS         := as
LD         := ld
AR         := ar

include projects.mk

# 1. Source Discovery
LIB_NAMES  := conversion io math strings hackers_delight
TUI_SRCS   := $(shell find tui/basics -name "*.s")

# 2. Mode-Specific Path Logic
ifeq ($(BUILD_MODE),debug)
    # DEBUG: Objects and binaries live side-by-side mirroring the source
    OBJ_BASE := $(BUILD_BASE)
    $(foreach src,$(TUI_SRCS),$(eval TARGET_$(src) := $(BUILD_BASE)/$(src:.s=)))
else
    # RELEASE: Objects hide in objs/, binaries go flat into tui/basics/
    OBJ_BASE := $(BUILD_BASE)/objs
    $(foreach src,$(TUI_SRCS),$(eval TARGET_$(src) := $(BUILD_BASE)/tui/basics/$(notdir $(basename $(src)))))
endif

# 3. Target Definitions
LIBS       := $(foreach lib,$(LIB_NAMES),$(BUILD_BASE)/utils/libs/lib$(lib).a)
BINARIES   := $(foreach src,$(TUI_SRCS),$(TARGET_$(src)))

.PHONY: all clean release debug

# 4. Main Rules
all: $(LIBS) $(BINARIES)
ifeq ($(BUILD_MODE),release)
	@echo "Cleaning up temporary objects..."
	@rm -rf $(BUILD_BASE)/objs
endif

debug:
	@$(MAKE) BUILD_MODE=debug all

release:
	@$(MAKE) BUILD_MODE=release all

# --- A. Compilation Rule ---
$(OBJ_BASE)/%.o: %.s
	@mkdir -p $(@D)
	$(AS) $(if $(filter debug,$(BUILD_MODE)),--gstabs+ -a=$@.lst,) -Iincludes $< -o $@

# --- B. Library Rule (Template) ---
define MAKE_LIB_RULE
$$(BUILD_BASE)/utils/libs/lib$(1).a: $$(foreach obj,$$(lib$(1)_OBJS),$$(OBJ_BASE)/$$(obj))
	@mkdir -p $$(@D)
	$$(AR) rcs $$@ $$^
	$$(if $$(filter debug,$$(BUILD_MODE)),nm $$@ > $$@.map,)
endef
$(foreach lib,$(LIB_NAMES),$(eval $(call MAKE_LIB_RULE,$(lib))))

# --- C. Linking Rule (Template) ---
define MAKE_BIN_RULE
$$(TARGET_$(1)): $$(OBJ_BASE)/$(1:.s=.o) $$(LIBS)
	@mkdir -p $$(@D)
	$$(LD) $$(if $$(filter release,$$(BUILD_MODE)),-s) $$< -o $$@ \
		$$(if $$(filter debug,$$(BUILD_MODE)),-Map=$$@.map,) \
		-L$$(BUILD_BASE)/utils/libs \
		--start-group $$(foreach l,$$(LIB_NAMES),-l$$(l)) --end-group \
		$$($(1:.s=)_LIBS)
endef
$(foreach src,$(TUI_SRCS),$(eval $(call MAKE_BIN_RULE,$(src))))

clean:
	rm -rf build