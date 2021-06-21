# Shared Makefile components which can be reused throughout the repository
# Tested and used with GNU Make 4.2.1
#
# -- rules.mk
# This file is used to define default pattern rules

%.o : %.c
	@echo "Compiling" $@ "from" $< "..."
	${CC} ${CFLAGS} -o $@ -c $<

%.o : %.s
	@echo "Assembling" $@ "from" $< "..."
	${AS} -o $@ -c $<