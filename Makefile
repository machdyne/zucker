RTL_PICO=rtl/sysctl_pico.v rtl/uart.v \
	rtl/ps2.v rtl/spislave.v rtl/rpmem.v rtl/rpint.v \
	rtl/spiflashro.v rtl/hram.v rtl/spram.v rtl/qqspi.v rtl/clkdiv.v \
	rtl/gpu_video.v rtl/gpu_text.v rtl/gpu_vram.v rtl/gpu_font_rom.v \
	rtl/gpu_ddmi.v rtl/tmds_encoder.v \
	rtl/audio.v \
	rtl/pll_ecp5.v \
	rtl/cpu/picorv32/picorv32.v

BOARD_LC = $(shell echo '$(BOARD)' | tr '[:upper:]' '[:lower:]')
BOARD_UC = $(shell echo '$(BOARD)' | tr '[:lower:]' '[:upper:]')

ifeq ($(BOARD_LC), riegel)
	FAMILY = ice40
	DEVICE = hx4k
	PACKAGE = bg121
	PCF = riegel.pcf
	PROG = ldprog -s
	FLASH = ldprog -f
else ifeq ($(BOARD), eis)
	FAMILY = ice40
	DEVICE = hx4k
	PACKAGE = bg121
	PCF = eis.pcf
	PROG = ldprog -is
	FLASH = ldprog -if
else ifeq ($(BOARD), bonbon)
	FAMILY = ice40
	DEVICE = up5k
	PACKAGE = sg48
	PCF = bonbon.pcf
	PROG = ldprog -b
	FLASH = ldprog -bf
else ifeq ($(BOARD), keks)
	FAMILY = ice40
	DEVICE = hx8k
	PACKAGE = ct256
	PCF = keks.pcf
	PROG = ldprog -ks
	FLASH = ldprog -kf
else ifeq ($(BOARD), brot)
	FAMILY = ice40
	DEVICE = up5k
	PACKAGE = sg48
	PCF = brot_v4.pcf
	PROG = ldprog -s
	FLASH = ldprog -f
else ifeq ($(BOARD), krote)
	FAMILY = ice40
	DEVICE = hx4k
	PACKAGE = bg121
	PCF = krote.pcf
	PROG = ldprog -s
	FLASH = ldprog -f
else ifeq ($(BOARD), icoboard)
	FAMILY = ice40
	DEVICE = hx8k
	PACKAGE = ct256
	PCF = icoboard.pcf
	PROG = icoprog -p < output/soc.bin
	FLASH = icoprog -f < output/soc.bin
	FLASH_OFFSET = -O
else ifeq ($(BOARD), schoko)
	FAMILY = ecp5
	DEVICE = 45k
	PACKAGE = CABGA256
	LPF = schoko_v1.lpf
	PROG = openFPGALoader -c dirtyJtag
	FLASH = openFPGALoader -c dirtyJtag -f
	FLASH_OFFSET = -o
endif

FAMILY_UC = $(shell echo '$(FAMILY)' | tr '[:lower:]' '[:upper:]')

zucker: zucker_pico

ifeq ($(FAMILY), ice40)
zucker_pico: zucker_ice40_pico
else
zucker_pico: zucker_ecp5_pico
endif

zucker_ice40_pico:
	mkdir -p output/$(BOARD_LC)
	yosys -D$(BOARD_UC) -q -p \
		"synth_ice40 -top sysctl -json output/$(BOARD_LC)/soc.json" $(RTL_PICO)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --pcf boards/$(PCF) \
		--asc output/$(BOARD_LC)/soc.txt --json output/$(BOARD_LC)/soc.json \
		--pcf-allow-unconstrained --opt-timing

zucker_ecp5_pico:
	mkdir -p output/$(BOARD_LC)
	yosys -D$(BOARD_UC) -q -p \
		"synth_ecp5 -top sysctl -json output/$(BOARD_LC)/soc.json" $(RTL_PICO)
	nextpnr-ecp5 --$(DEVICE) --package $(PACKAGE) --lpf boards/$(LPF) \
		--json output/$(BOARD_LC)/soc.json \
		--textcfg output/$(BOARD_LC)/soc.config


firmware:
	cd firmware && make BOARD=$(BOARD_UC) FAMILY=$(FAMILY_UC)

prog: clean_firmware prog_soc
flash: flash_soc flash_lix

ifeq ($(FAMILY), ice40)
soc:
	icebram firmware/firmware_seed.hex firmware/firmware.hex < \
		output/$(BOARD_LC)/soc.txt | icepack > output/$(BOARD_LC)/soc.bin
else
soc:
	ecpbram -i output/$(BOARD_LC)/soc.config \
		-o output/$(BOARD_LC)/soc_final.config \
		-f firmware/firmware_seed.hex \
		-t firmware/firmware.hex
	ecppack -v --compress --freq 2.4 output/$(BOARD_LC)/soc_final.config \
		--bit output/$(BOARD_LC)/soc.bit
endif

prog_soc: firmware soc
	$(PROG) output/$(BOARD_LC)/soc.bin

flash_soc: firmware soc
	$(FLASH) output/$(BOARD_LC)/soc.bin

flash_lix: apps
	$(FLASH) apps/lix/lix.bin $(FLASH_OFFSET) 50000

apps:
	cd apps && make

clean: clean_firmware clean_apps
	rm -f output/*

clean_apps:
	cd apps && make clean

clean_firmware:
	cd firmware && make clean

.PHONY: clean_firmware firmware apps
