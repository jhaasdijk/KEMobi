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
SRC := Decode.c Encode.c int32.c uint32.c nist/rng.c subroutines/crypto_hash_sha512.c subroutines/crypto_sort_uint32.c subroutines/crypto_stream_aes256ctr.c
OBJ := ${SRC:.c=.o}

# Declare KAT related files, values
KAT := kat_kem.int kat_kem.req kat_kem.rsp
KATNUM := ${shell cat KATNUM}
KATNUM := $$(( 2 * ${KATNUM} ))

# Be explicit about what we clean - Never call rm -r from within a Makefile
SRC_CLEAN := ${shell find ${./} -name '*.c'}
OBJ_CLEAN := ${SRC_CLEAN:.c=.o}

# Define benchmark related
SPEED := benchmark.out

default : all

${TARGET} : nist/kat_kem.o kem.o ${OBJ}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

${SPEED} : speed_main.o speed_kem.o speed_util.o ${OBJ}
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
