TARGET  = ${notdir ${CURDIR}}
SRC_DIR = .
COURCES = ${wildcard ${SRC_DIR}/*.c}
SOURCES = ${COURCES}
OBJECTS = ${SOURCES:.c=.o}

default : all

${TARGET} : ${OBJECTS}
	@echo "Linking" $@ "from" $^ "..."
	${LD} ${LDFLAGS} -o $@ $^ ${LDLIBS}

${OBJECTS} : %.o: %.c
	@echo "Compiling" $@ "from" $< "..."
	${CC} ${CFLAGS} -o $@ -c $<

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
include ../common/make.mk