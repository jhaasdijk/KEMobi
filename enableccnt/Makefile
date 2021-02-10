obj-m += enable_ccr.o

all:
	make -C /usr/src/linux-headers-5.10.11-v8+/ M=$(PWD) modules
 
clean:
	make -C /usr/src/linux-headers-5.10.11-v8+/ M=$(PWD) clean