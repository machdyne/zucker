RTL_PICO=rtl/sysctl_pico.v rtl/uart.v \
	rtl/ps2.v rtl/spislave.v rtl/rpmem.v rtl/rpint.v \
	rtl/spiflashro.v rtl/hram.v rtl/spram.v rtl/qqspi.v rtl/clkdiv.v \
	rtl/gpu_video.v rtl/gpu_text.v rtl/gpu_vram.v rtl/gpu_font_rom.v \
	rtl/gpu_ddmi.v rtl/tmds_encoder.v \
	rtl/audio.v \
	rtl/cpu/picorv32/picorv32.v

YOSYS=yosys
NEXTPNR=nextpnr-ice40

all: firmware zucker_riegel_pico apps

zucker_riegel_pico:
	mkdir -p output
	yosys -DRIEGEL $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx4k --package bg121 --pcf boards/riegel.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing

zucker_bonbon_pico:
	mkdir -p output
	yosys -DBONBON $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --up5k --package sg48 --pcf boards/bonbon.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing

zucker_keks_pico:
	mkdir -p output
	yosys -DKEKS $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx8k --package ct256 --pcf boards/keks.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing

zucker_brot_pico:
	mkdir -p output
	yosys -DBROT -DOSC48 -DFPGA_ICE40 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --up5k --package sg48 --pcf boards/brot_v4.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing

zucker_krote_pico:
	mkdir -p output
	yosys -DKROTE -DOSC100 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx4k --package bg121 --pcf boards/krote.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained \
		--opt-timing

zucker_icoboard_pico:
	mkdir -p output
	yosys -DICOBOARD -DOSC100 $(CFG) -q -p \
		"synth_ice40 -top sysctl -json output/soc.json" \
		$(RTL_PICO)
	nextpnr-ice40 --hx8k --package ct256 --pcf boards/icoboard.pcf \
		--asc output/soc.txt --json output/soc.json --pcf-allow-unconstrained --opt-timing

firmware:
	cd firmware && make

prog: clean_firmware prog_riegel

prog_riegel: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	ldprog -s output/soc.bin

prog_bonbon: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	ldprog -bs output/soc.bin

prog_keks: firmware
	icebram firmware/firmware_seed.hex firmware/firmware.hex < output/soc.txt \
		| icepack > output/soc.bin
	ldprog -ks output/soc.bin

prog_brot: firmware
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
	ldprog -f apps/lix/lix.bin 50000

flash_riegel: flash_riegel_soc flash_riegel_lix

apps:
	cd apps && make

clean: clean_firmware clean_apps
	rm -f output/*

clean_apps:
	cd apps && make clean

clean_firmware:
	cd firmware && make clean

.PHONY: clean_firmware firmware
