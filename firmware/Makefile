PREFIX=/opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS=
ARCH=rv32i
ABI=ilp32

BRAM_WORDS=1536

BOOT=boot_picorv32.S

firmware: firmware.hex firmware.bin firmware_seed.hex

firmware.elf: firmware.lds $(BOOT) firmware.c
	$(PREFIX)gcc $(CFLAGS) -Os -march=$(ARCH) -mabi=$(ABI) -ffreestanding -nostdlib -Wall -o firmware.elf $(BOOT) firmware.c firmware_picosoc.c --std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map,--strip-debug -lgcc
	 $(PREFIX)objdump -S --disassemble firmware.elf > firmware.asm

firmware_seed.hex:
	icebram -g 32 $(BRAM_WORDS) > firmware_seed.hex

firmware.hex: firmware.bin
	python3 makehex.py firmware.bin $(BRAM_WORDS) > firmware.hex
	@echo "Firmware size: $$(grep .. firmware.hex | wc -l) / $$(wc -l < firmware.hex)"

firmware.bin: firmware.elf
	$(PREFIX)objcopy -O binary firmware.elf firmware.bin

clean:
	rm -f firmware.elf firmware.hex firmware.bin firmware.map firmware.asm

.PHONY: firmware clean
