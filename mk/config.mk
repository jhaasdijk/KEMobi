# Shared Makefile components which can be reused throughout the repository
# Tested and used with GNU Make 4.2.1
#
# -- config.mk
# This file is used to define shared flags and variables

# Ensure strict POSIX make rules.
.POSIX :

# Empty the the list of default suffixes
.SUFFIXES :
# Include C files, sources
.SUFFIXES : .c .h
# Include C products, object files, make dependencies, assembler
.SUFFIXES : .o .d .s

# Choice of assembler, compiler, linker, utilities for object files
AS = as
CC = gcc
LD = gcc
OBJCOPY = objcopy
OBJDUMP = objdump

# Turn on all optimizations specified by -O2 and more
OPT = -O3 -march=armv8-a+simd -mtune=cortex-a72 -mcpu=cortex-a72+simd

# Additional flags that need to be added explicitly
EXP = -fomit-frame-pointer

# Turn on extended warnings
WAR = -Wall -Wcast-align -Wfloat-equal -Wpointer-arith -Wredundant-decls \
	-Wshadow -Wswitch-default -Wswitch-enum -Wundef -Wunreachable-code

# Defining a C standard to which we conform
STD = -std=gnu17

CFLAGS = ${OPT} ${EXP} ${WAR} ${STD}

LDFLAGS = -Wl,--start-group -lc -lgcc -Wl,--end-group\
	-Wl,--gc-sections,--print-gc-sections

LDLIBS =