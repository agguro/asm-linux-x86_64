# root/tui/basics/Makefile
# root/tui/Makefile
MAKEFLAGS += --no-print-directory
# The local Makefile finds the root, then calls the aggregator
ROOT_DIR := $(shell while [ ! -d includes ]; do cd ..; if [ "$$(pwd)" = "/" ]; then break; fi; done; pwd)
include $(ROOT_DIR)/Makefile.aggregator