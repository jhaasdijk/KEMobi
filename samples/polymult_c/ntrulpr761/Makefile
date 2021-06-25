TARGET761 = ntt761.out
TARGET512 = ntt512.out

C_FILES = goods.c util.c
S_FILES = asm_ntt_forward.s asm_ntt_inverse.s asm_reduce_coefficients.s

OBJ = ${C_FILES:.c=.o}
ASM = ${S_FILES:.s=.o}

default : all

${TARGET761} : main761.o ${OBJ} ${ASM}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

${TARGET512} : main512.o ${OBJ} ${ASM}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

.PHONY : all 761 512
all : ${TARGET761} ${TARGET512}
	@echo "Building target:" $^
	@echo "Done"

761 : ${TARGET761}
	@echo "Building target:" $^
	@echo "Done"

512 : ${TARGET512}
	@echo "Building target:" $^
	@echo "Done"

.PHONY : clean cleanobj cleandep
clean : cleanobj cleandep
	@echo "Removing executable"
	rm ${TARGET761}
	rm ${TARGET512}

cleanobj :
	@echo "Removing object files"
	rm *.o

cleandep :
	@echo "Removing GNU Make dependency output"
	rm *.d

# Include shared Makefile components
include ../../common/config.mk
include ../../common/rules.mk