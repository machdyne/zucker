PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
ARCH = rv32i
ABI = ilp32
CC = $(PREFIX)gcc
CFLAGS = --std=gnu99 -Os -MD -Wall -march=$(ARCH) -mabi=$(ABI) -Iinclude -Ifs/fatfs -I../common
LDSCRIPT = ../common/riscv-psram-lix.ld
LIBS = -lm -lgcc

OBJS = lix.o ll.o sh.o xfer.o te.o zucker.o \
	fs/fs.o fs/fatfs/sdmm.o fs/fatfs/ff.o

lix: lix.elf lix.bin

lix.o:
	xxd -i ll_stdlib.l > include/ll_stdlib.h
	$(CC) $(CFLAGS) -c ../common/zucker.c -o zucker.o
	$(CC) $(CFLAGS) -c lix.c -o lix.o
	$(CC) $(CFLAGS) -DLIX -c ll.c -o ll.o
	$(CC) $(CFLAGS) -c sh.c -o sh.o
	$(CC) $(CFLAGS) -c xfer.c -o xfer.o
	$(CC) $(CFLAGS) -c te.c -o te.o
	$(CC) $(CFLAGS) -c fs/fs.c -o fs/fs.o
	$(CC) $(CFLAGS) -c fs/fatfs/sdmm.c -o fs/fatfs/sdmm.o
	$(CC) $(CFLAGS) -c fs/fatfs/ff.c -o fs/fatfs/ff.o
	$(CC) $(CFLAGS) -c fs/fs.c -o fs/fs.o
	#$(CC) $(CFLAGS) -c lix.c -S -o lix.asm

lix.elf: $(OBJS)
	$(CC) -Wl,-T$(LDSCRIPT),-Map,lix.map -o lix.elf $(OBJS) $(LIBS)
	$(PREFIX)objdump -S --disassemble lix.elf > lix.dasm

lix.bin:
	$(PREFIX)objcopy -O binary lix.elf lix.bin

te_unix:
	gcc -o te te.c -lcurses -DMAIN -DCURSES

clean:
	rm -f lix.elf lix.bin lix.asm lix.dasm lix.map *.d fs/*.d fs/fatfs/*.d $(OBJS)

.PHONY: lix clean
