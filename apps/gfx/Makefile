
PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-
ARCH = rv32i
CC = $(PREFIX)gcc
CFLAGS = --std=gnu99 -Os -MD -Wall -march=$(ARCH)
LDSCRIPT = ../common/riscv-psram-app.ld

OBJS = gfx.o zucker.o

gfx: tileset.h gfx.elf gfx.bin

tileset.h:
	xxd -i tileset.bin tileset.h

zucker.o:
	$(CC) $(CFLAGS) -c ../common/zucker.c -o zucker.o

gfx.o:
	$(CC) $(CFLAGS) -c gfx.c -o gfx.o
	$(CC) $(CFLAGS) -c gfx.c -S -o gfx.asm

gfx.elf: $(OBJS)
	$(CC) -Wl,-T$(LDSCRIPT),-Map,gfx.map -o gfx.elf $(OBJS)
	$(PREFIX)objdump -S --disassemble gfx.elf > gfx.dasm

gfx.bin:
	$(PREFIX)objcopy -O binary gfx.elf gfx.bin

clean:
	rm -f gfx.elf gfx.bin gfx.asm gfx.dasm gfx.map gfx.o zucker.o *.d

.PHONY: gfx clean

