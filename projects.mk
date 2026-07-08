# --- Library Manifest ---
libconversion_OBJS := utils/conversion/u64toa.o utils/conversion/u64tobin.o utils/conversion/u64tohex.o
libio_OBJS         := utils/io/print_stringz.o utils/io/print_uint8array.o
libmath_OBJS       := utils/math/fisher_yates_shuffle.o utils/math/merge_shuffle.o utils/math/nlz.o utils/math/popcount.o utils/math/sattolo_shuffle.o utils/math/signed_rotate.o
libstrings_OBJS    := utils/strings/strlen.o
libhackers_delight_OBJS := utils/hackers_delight/hacker_bin2bcd.o utils/hackers_delight/hacker_nibble2hexascii.o

# --- Program Requirements ---
BASE_LIBS := -lconversion -lio -lmath -lstrings -lhackers_delight

# TUI Basics - Only add specific lines if they need extra libs
tui/basics/arguments/arguments_LIBS := $(BASE_LIBS)
tui/basics/cpuid/cpuid_LIBS           := $(BASE_LIBS)
tui/basics/cwd/cwd_LIBS               := $(BASE_LIBS)
tui/basics/dealcards/dealcards_LIBS   := $(BASE_LIBS)
tui/basics/dirinfo/dirinfo_LIBS       := $(BASE_LIBS)
tui/basics/hello/hello_LIBS           := -lio
tui/basics/inputdemo/inputdemo_LIBS   := $(BASE_LIBS)
tui/basics/keyfilter/keyfilter_LIBS   := $(BASE_LIBS)
tui/basics/palindrome/palindrome_LIBS := $(BASE_LIBS)
tui/basics/printenv/printenv_LIBS     := -lio
tui/basics/readfile/readfile_LIBS     := $(BASE_LIBS)
tui/basics/rotatebits/rotatebits_LIBS := $(BASE_LIBS)
tui/basics/uuid/uuid_LIBS             := $(BASE_LIBS)
tui/basics/waitforenterkeypress/waitforenterkeypress_LIBS := $(BASE_LIBS)
tui/basics/waitforkeypress/waitforkeypress_LIBS := $(BASE_LIBS)
tui/basics/winsize/winsize_LIBS       := $(BASE_LIBS)