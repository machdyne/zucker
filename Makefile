RTL_PICO=rtl/sysctl_pico.v rtl/sysclk.v rtl/uart.v rtl/ps2.v \
	rtl/spiflashro.v rtl/hram.v rtl/qqspi.v rtl/clkdiv.v \
	rtl/gpu_vga.v rtl/gpu_text.v rtl/gpu_vram.v rtl/gpu_font_rom.v \
	rtl/cpu/picorv32/picorv32.v

YOSYS=yosys
NEXTPNR=nextpnr-ice40

all: firmware zucker_riegel_pico apps

zucker_riegel_pico:
	mkdir -p output
	yosys -DRIEGEL -DOSC48 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx4k --package bg121 --pcf boards/riegel.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing
	icebox_explain output/soc.txt > output/soc.ex
	icetime -d hx4k -c 50 -mtr output/soc.rpt output/soc.txt

zucker_krote_pico:
	mkdir -p output
	yosys -DRIEGEL -DOSC100 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx4k --package bg121 --pcf boards/krote.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing
	icebox_explain output/soc.txt > output/soc.ex
	icetime -d hx4k -c 50 -mtr output/soc.rpt output/soc.txt

zucker_icoboard_pico:
	mkdir -p output
	yosys -DICOBOARD -DOSC100 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx8k --package ct256 --pcf boards/icoboard.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained --opt-timing
	icebox_explain output/soc.txt > output/soc.ex
	icetime -d hx8k -c 50 -mtr output/soc.rpt output/soc.txt

firmware:
	cd firmware && make

prog: clean_firmware prog_riegel

prog_riegel: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	ldprog -s output/soc.bin

prog_krote: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	ldprog -s output/soc.bin

prog_icoboard: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	icoprog -p < output/soc.bin

flash_riegel_soc:
	ldprog -f output/soc.bin

flash_riegel_lix:
	ldprog -f apps/lix/lix.bin 25800

flash_riegel: flash_riegel_soc flash_riegel_lix

apps:
	cd apps && make

clean: clean_firmware clean_apps
	rm -f output/*

clean_apps:
	cd apps && make clean

clean_firmware:
	cd firmware && make clean

.PHONY: clean_firmware firmware apps
