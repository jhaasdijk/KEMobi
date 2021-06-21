# Include shared Makefile components. They need to be included at the beginning
# of the file if we want to append to an existing value (e.g. CFLAGS, LDLIBS).
MKROOT := ../../../mk
include ${MKROOT}/config.mk
include ${MKROOT}/rules.mk

# Define and append additional values to CFLAGS
INC := -I. -Isubroutines
MAC := -DKAT -DKATNUM=`cat KATNUM` "-DCRYPTO_NAMESPACE(x)=x"
CFLAGS += ${INC} ${MAC}

# Define and append additional values to LDLIBS
LIB := -lcrypto -ldl
LDLIBS += ${LIB}

# Define the target, i.e. the name for the executable
TARGET := ntrulpr761.out

# Find and declare all the C files we want to compile
SRC_DIRS := ./
SRC := ${shell find ${SRC_DIRS} -name '*.c'}
OBJ := ${SRC:.c=.o}

# Declare KAT related files, values
KAT := kat_kem.int kat_kem.req kat_kem.rsp
KATNUM := ${shell cat KATNUM}
KATNUM := $$(( 2 * ${KATNUM} ))

default : all

${TARGET} : ${OBJ}
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

all : build	test check

.PHONY : clean cleankat cleanobj

clean : cleankat cleanobj
	@echo "Removing executable ${TARGET}"
	@rm ${TARGET}

cleankat :
	@echo "Removing KAT files"
	@rm ${KAT}

cleanobj :
	@echo "Removing object files"
	@rm ${OBJ}
