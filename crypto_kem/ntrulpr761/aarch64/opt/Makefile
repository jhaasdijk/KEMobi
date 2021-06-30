# Include shared Makefile components. They need to be included at the beginning
# of the file if we want to append to an existing value (e.g. CFLAGS, LDLIBS).
MKROOT := ../../../../mk
include ${MKROOT}/config.mk
include ${MKROOT}/rules.mk

# Define and append additional values to CFLAGS
INC := -I. -Isubroutines
MAC := -D KAT -D KATNUM=`cat KATNUM` "-D CRYPTO_NAMESPACE(x)=x"
CFLAGS += ${INC} ${MAC}

# Define and append additional values to LDLIBS
LIB := -lcrypto -ldl
LDLIBS += ${LIB}

# Define make target, sources
TARGET := ntrulpr761.out
SPEED := benchmark.out

C_FILES := Decode.c Encode.c int32.c uint32.c nist/rng.c
C_FILES += $(wildcard ./subroutines/*.c)
C_FILES += $(wildcard ./ntt/*.c)
S_FILES += $(wildcard ./ntt/*.s)

OBJ := ${C_FILES:.c=.o}
ASM := ${S_FILES:.s=.o}

OBJ_NIST := nist/kat_kem.o kem.o
OBJ_SPEED := speed_main.o speed_kem.o

# Declare KAT related files, values
KAT := kat_kem.int kat_kem.req kat_kem.rsp
KATNUM := ${shell cat KATNUM}
KATNUM := $$(( 2 * ${KATNUM} ))

# Be explicit about what we clean - Never call rm -r from within a Makefile
OBJ_CLEAN := ${C_FILES:.c=.o} ${S_FILES:.s=.o} ${OBJ_NIST} ${OBJ_SPEED}

default : all

${TARGET} : ${OBJ_NIST} ${OBJ} ${ASM}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

${SPEED} : ${OBJ_SPEED} ${OBJ} ${ASM}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

.PHONY : build test check all

# Recipe for building the sources into an executable - compile KAT generator
build : ${TARGET}
	@echo "Building target" $^
	@echo "Done"

# Recipe for testing the executable using KAT - run KAT generator
test :
	@echo "Testing target using KAT"
	@./${TARGET} > kat_kem.int 8> kat_kem.req 9> kat_kem.rsp

# Recipe that uses ${.SHELLSTATUS} to verify the exit status of the last executed command
check :
	@if test ${.SHELLSTATUS} -eq 0; then \
		echo "OK"; \
	else \
		echo "FAIL"; \
	fi

	@bash -c 'diff <(head -n ${KATNUM} kat_kem.int) <(head -n ${KATNUM} kat/kat_kem.int)'
	@bash -c 'diff <(head -n ${KATNUM} kat_kem.req) <(head -n ${KATNUM} kat/kat_kem.req)'
	@bash -c 'diff <(head -n ${KATNUM} kat_kem.rsp) <(head -n ${KATNUM} kat/kat_kem.rsp)'

all : build test check

.PHONY : speed

speed : ${SPEED}
	@echo "Building target" $^
	@echo "Done"

.PHONY : clean cleankat cleanobj

clean : cleankat cleanobj
	@echo "Removing executable ${TARGET}"
	@rm ${TARGET}
	@echo "Removing executable ${SPEED}"
	@rm ${SPEED}

cleankat :
	@echo "Removing KAT files"
	@rm ${KAT}

cleanobj :
	@echo "Removing object files"
	@rm ${OBJ_CLEAN}
