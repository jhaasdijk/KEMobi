obj-m += enable_ccr.o

default : all
.PHONY : build install clean all

build :
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(PWD) modules

install :
	@echo Enable userspace access to PMU counters
	sudo insmod enable_ccr.ko

clean :
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(PWD) clean

all : build install