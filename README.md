# Zucker SOC

## Overview

Zucker is an experimental System-on-a-Chip (SOC) designed for Lone Dynamics FPGA computers that provides a RISC-V CPU ([PicoRV32](https://github.com/YosysHQ/picorv32)), a simple GPU, memory controllers, a keyboard controller and a UART. This repo also contains firmware, a minimal OS and example applications.

Zucker was created as a demo platform and a starting point for developing gateware and apps on the [Riegel](https://machdyne.com/product/riegel-computer) FPGA computer. The goal of Zucker is to allow Riegel to be used as a stand-alone [timeless](https://machdyne.com/2022/01/12/timeless-computing/) personal computer system when attached to a keyboard and a monitor.

## Supported Boards

- [Riegel](https://machdyne.com/product/riegel-computer)
- [Kröte](https://machdyne.com/product/krote-fpga-board/)
- [IcoBoard](http://icoboard.org/)

## Getting Started

### Building the Gateware and Firmware

Building Zucker requires [Yosys](https://github.com/YosysHQ/yosys), [nextpnr-ice40](https://github.com/YosysHQ/nextpnr), [IceStorm](https://github.com/YosysHQ/icestorm) and a [RV32I toolchain](https://github.com/YosysHQ/picorv32#building-a-pure-rv32i-toolchain).

After everything is installed, you can simply type `make` to build the FPGA configuration image, which will be written to output/soc.bin. This will also build the firmware and demo apps.

### Flashing the MMOD

Once the gateware, firmware and demo apps are built, you can use [ldprog](https://github.com/machdyne/ldprog) to write everything to the MMOD:

```
make flash_riegel
```

## Boot Process

0. USB Bootloader (optional)
1. Zucker Bootloader (ZBL)
2. LIX
3. Apps

### USB Bootloader

See the [Riegel](https://github.com/machdyne/riegel) repo for details on setting up a USB bootloader.

### Zucker Bootloader (ZBL)

The ZBL bootloader firmware is inside the FPGA configuration image. Its primary purpose is to load the next stage (LIX) from the MMOD flash. ZBL can also perform some basic system diagnostics.

The source code for ZBL is located in [firmware.c](firmware/firmware.c) and it's called by [boot\_picorv32.S](firmware/boot\_picorv32.S).

### LIX

LIX is a minimal OS and second stage bootloader. LIX is capable of loading and booting apps from a FAT-formatted SD card. LIX is programmed onto the flash MMOD after the FPGA configuration image.

The source code for LIX is located in [apps/lix](apps/lix).

#### Commands

Type `help` to see a list of commands.

#### User Apps

LIX loads user apps into memory at 0x40100000.

See apps/hello for an example application. You can create your own apps by making a copy of the apps/hello directory.

After compiling your app you can copy it to an SD card and run it from LIX:

```
lix> run myapps/hello.bin
```

You can also upload apps to LIX over the UART using the [xfer](https://github.com/machdyne/xfer) utility.

If a file named BOOT.BIN is located in the root directory of the SD card it will be loaded into main memory and run automatically at boot time.

#### Lisp

LIX also includes a simple Lisp interpreter.

Some usage examples:

```
lix> (+ 1 2 3 4 5)
[num:15.000000]
lix> (map (lambda (x) (* 2 x)) (list 1 2 3 4))
[list: [num:2.000000] [num:4.000000] [num:6.000000] [num:8.000000] ]
```

Display the environment:
```
lix> (dump)
```

Load a LISP program from the SD card:
```
lix> (load myfiles/lisp/hello.l)
```

## Technical Details

### PMODs

The default configuration assumes that a UART PMOD is connected to PMODB.

### Memory Map

| Begin | End | Size | Description |
| ----- | --- | ---- | ----------- |
| ``00000000`` | ``000017ff`` | 6144 | BRAM (ZBL firmware) |
| ``10000000`` | ``100007cf`` | 2000 | BRAM (video text memory) |
| ``20000000`` | ``2007ffff`` | 512KB | SRAM (video graphic memory) |
| ``40000000`` | ``43ffffff`` | 32MB-64MB | HRAM or QQSPI (main memory) |
| ``80000000`` | ``8fffffff`` | - | MMOD (read-only flash memory) |
| ``f0000000`` | ``f0000000`` | 1 | UART data register |
| ``f0000004`` | ``f0000004`` | 1 | UART control register |
| ``f0001000`` | ``f0001000`` | 1 | LED control register |
| ``f0001100`` | ``f0001103`` | 4 | RTC seconds counter register |
| ``f0002000`` | ``f0002000`` | 1 | SD card SPI register |
| ``f0003000`` | ``f0003000`` | 1 | PS/2 data register |
| ``f0003004`` | ``f0003004`` | 1 | PS/2 control register |

### Video Graphics

There is a 640x480 framebuffer at the beginning of the SRAM.

Each byte in the framebuffer contains two pixels: XRGBXRGB. X is an unused bit.

This uses 153600 bytes of the SRAM. The remaining SRAM is unused and available.

Note: Graphics mode is currently disabled by default.

### Video Text

There is a 80x25 character buffer in BRAM at 0x10000000.

Writing an ASCII character to the video text memory will display it on the screen.

Text and graphics can be displayed at the same time.

## License

Zucker is released under the Lone Dynamics Open License. This repo contains code from the [PicoRV32](https://github.com/YosysHQ/picorv32) project, you can find its license in the [rtl/cpu/picorv32](rtl/cpu/picorv32) directory.
