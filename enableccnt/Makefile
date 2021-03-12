obj-m += enable_ccr.o

all:
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(PWD) modules
 
clean:
	make -C /usr/src/linux-headers-$(shell uname -r)/ M=$(PWD) clean

install:
	@echo Enable userspace access to PMU counters
	sudo insmod enable_ccr.ko