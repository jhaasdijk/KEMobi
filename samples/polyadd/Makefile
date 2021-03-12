TARGET  = ${notdir ${CURDIR}}
SRC_DIR = .
C_FILES = ${wildcard ${SRC_DIR}/*.c}
S_FILES = ${wildcard ${SRC_DIR}/*.s}
OBJ = ${C_FILES:.c=.o}
ASM = ${S_FILES:.s=.o}

default : all

${TARGET} : ${OBJ} ${ASM}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

.PHONY : all
all : ${TARGET}
	@echo "Building target:" $^
	@echo "Done"

.PHONY : clean cleanobj cleandep
clean : cleanobj cleandep
	@echo "Removing executable"
	rm ${TARGET}

cleanobj :
	@echo "Removing object files"
	rm *.o

cleandep :
	@echo "Removing GNU Make dependency output"
	rm *.d

# Include shared Makefile components
include ../common/config.mk
include ../common/rules.mk