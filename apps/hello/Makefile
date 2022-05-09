PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
ARCH = rv32i
CC = $(PREFIX)gcc
CFLAGS = --std=gnu99 -Os -MD -Wall -march=$(ARCH)
LDSCRIPT = ../common/riscv-psram-app.ld

OBJS = hello.o zucker.o

hello: hello.elf hello.bin

zucker.o:
	$(CC) $(CFLAGS) -c ../common/zucker.c -o zucker.o

hello.o:
	$(CC) $(CFLAGS) -c hello.c -o hello.o
	$(CC) $(CFLAGS) -c hello.c -S -o hello.asm

hello.elf: $(OBJS)
	$(CC) -Wl,-T$(LDSCRIPT),-Map,hello.map -o hello.elf $(OBJS)
	$(PREFIX)objdump -S --disassemble hello.elf > hello.dasm

hello.bin:
	$(PREFIX)objcopy -O binary hello.elf hello.bin

clean:
	rm -f hello.elf hello.bin hello.asm hello.dasm hello.map hello.o zucker.o *.d

.PHONY: hello clean

