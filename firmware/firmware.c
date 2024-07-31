/*
 * ZUCKER SOC BOOTLOADER (ZBL)
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define EN_BANNER 1

#define reg_uart_data (*(volatile uint8_t*)0xf0000000)
#define reg_uart_ctrl (*(volatile uint8_t*)0xf0000004)
#define reg_leds (*(volatile uint8_t*)0xf0001000)
#define reg_rtc (*(volatile uint32_t*)0xf0001100)
#define reg_sd (*(volatile uint8_t*)0xf0002000)
#define reg_ps2_data (*(volatile uint8_t*)0xf0003000)
#define reg_ps2_ctrl (*(volatile uint8_t*)0xf0003004)
#define reg_gamepad_l (*(volatile uint32_t*)0xf0005000)
#define reg_gamepad_r (*(volatile uint32_t*)0xf0005004)
#define reg_delay_us (*(volatile uint32_t*)0xf0006000)

#define reg_cfg_sys (*(volatile uint32_t*)0xf000f000)
#define reg_cfg_vid (*(volatile uint32_t*)0xf000f004)
#define reg_cfg_vid_res (*(volatile uint32_t*)0xf000f008)

#define reg_gpu_blit_src (*(volatile uint32_t*)0xf0008000)
#define reg_gpu_blit_dst (*(volatile uint32_t*)0xf0008004)
#define reg_gpu_blit_ctl (*(volatile uint32_t*)0xf0008008)

#define UART_CTRL_TXBUSY 0x02
#define UART_CTRL_DR 0x01

#define PS2_CTRL_OVERFLOW 0x04
#define PS2_CTRL_BUSY 0x02
#define PS2_CTRL_DR 0x01

#define SD_MISO 0x01
#define SD_MOSI 0x02
#define SD_SCK 0x04
#define SD_SS 0x08

#define MEM_VRAM				0x10000000
#define MEM_SRAM				0x20000000
//#define MEM_SRAM_SIZE		0x20000		// 128KB
//#define MEM_SRAM_SIZE		0x80000		// 512KB
#define MEM_SRAM_SIZE		0x100000		// 1MB
#define MEM_HRAM				0x40000000
//#define MEM_HRAM_SIZE		0x800000		// 8MB
#define MEM_HRAM_SIZE		0x2000000	// 32MB
//#define MEM_HRAM_SIZE		0x4000000	// 64MB
#define MEM_FLASH				0x80000000
#define MEM_FLASH_SIZE		0x2000000	// 32MB

#define LIX_MEM_ADDR			0x40000000
#define LIX_FLASH_ADDR		0x80050000
#define LIX_SIZE				262144

#include "scancodes.h"

uint16_t curs_x = 0;
uint16_t curs_y = 0;

uint32_t addr_ptr;
uint32_t mem_total;

// --------------------------------------------------------

uint32_t xfer_recv(uint32_t addr);
uint32_t crc32b(char *data, uint32_t len);
void putchar_vga(const char c);
char scantoascii(uint8_t scancode);

void sd_init(void);
void sd_spi_xfer(uint8_t b);
void sd_delay(void);

void print_hex(uint32_t v, int digits);
void memtest(uint32_t addr_ptr, uint32_t mem_total);
void memcpy(uint32_t dest, uint32_t src, uint32_t n);

int vid_cols;
int vid_rows;
int vid_hres;
int vid_vres;

// --------------------------------------------------------

int putchar(int c)
{
	while ((reg_uart_ctrl & UART_CTRL_TXBUSY) == UART_CTRL_TXBUSY);

	if (c == '\n')
		putchar('\r');

	reg_uart_data = (char)c;
	if (reg_cfg_vid)
		putchar_vga(c);

	return c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void putchar_vga(const char c) {
	int xy = curs_y * vid_cols + curs_x;
	if (c == '\n') {
		curs_x = 0;
		curs_y++;
	} else {
		(*(volatile uint8_t *)(0x10000000 + xy)) = c;
		curs_x++;
		for (int i = curs_x; i < vid_cols - curs_x + 1; i++)
			(*(volatile uint8_t *)(0x10000000 + xy + i)) = ' ';
	}
	if (curs_x >= vid_cols) { curs_x = 0; curs_y++; };
	if (curs_y > vid_rows - 1) {
		curs_y = vid_rows - 1;
		memcpy(0x10000000, 0x10000000 + vid_cols,
			(vid_cols * vid_rows) - vid_cols);
	};
}

int getchar()
{
	int uart_dr = ((reg_uart_ctrl & UART_CTRL_DR) == UART_CTRL_DR);
	int kbd_dr = ((reg_ps2_ctrl & PS2_CTRL_DR) == PS2_CTRL_DR);
	char c;

	if (!uart_dr && !kbd_dr) {
		return EOF;
	} else {
		if (kbd_dr) {
			c = scantoascii(reg_ps2_data);
			if (c) return c; else return EOF;
		} else {
			return reg_uart_data;
		}
	}
}

void getchars(char *buf, int len) {
	int c;
	for (int i = 0; i < len; i++) {
		while ((c = getchar()) == EOF);
		buf[i] = (char)c;
	};
}

char scantoascii(uint8_t scancode) {

	uint8_t tmp;
	
	if (scancode == 0xf0) {
		while ((reg_ps2_ctrl & PS2_CTRL_DR) != PS2_CTRL_DR);
		tmp = reg_ps2_data;
		return tmp * 0;
	}

	for (int i = 0; i < sizeof(ps2_scancodes); i++) {
		if (ps2_scancodes[i] == scancode) return i + 0x30;
	}
	return 0;

};

uint32_t xfer_recv(uint32_t addr_ptr)
{

	uint32_t addr = addr_ptr;
	uint32_t bytes = 0;
	uint32_t crc_ours;
	uint32_t crc_theirs;

	char buf_data[252];
	char buf_crc[4];

	int cmd;
	int datasize;

	print("xfer addr 0x");
	print_hex(addr, 8);
	print("\n");

	while (1) {

		while ((cmd = getchar()) == EOF);
		buf_data[0] = (uint8_t)cmd;

		if ((char)cmd == 'L') {
			while ((datasize = getchar()) == EOF);
			buf_data[1] = (uint8_t)datasize;
			getchars(&buf_data[2], datasize);
			getchars(buf_crc, 4);
			crc_ours = crc32b(buf_data, datasize + 2);
			crc_theirs = buf_crc[0] | (buf_crc[1] << 8) |
				(buf_crc[2] << 16) | (buf_crc[3] << 24);
			if (crc_ours == crc_theirs) {
				for (int i = 0; i < datasize; i++) {
					(*(volatile uint8_t *)(addr + i)) = buf_data[2 + i];
				}
				addr += datasize;
				bytes += datasize;
				putchar('A');
			} else {
				putchar('N');
			}
		}

		if ((char)cmd == 'D') {
			break;
		}

	}

	return bytes;

}

uint32_t crc32b(char *data, uint32_t len) {

	uint32_t byte, crc, mask;

	crc = 0xffffffff;
	for (int i = 0; i < len; i++) {
		byte = data[i];
		crc = crc ^ byte;
		for (int j = 7; j >= 0; j--) {
			mask = -(crc & 1);
			crc = (crc >> 1) ^ (0xedb88320 & mask);
		}
		i = i + 1;
	}
	return ~crc;
}

/*
// put any SD card into SPI mode or it will cause problems on the SPI bus
void sd_init(void) {

	print("init sdcard to spi mode ... ");

	reg_sd = SD_SS | SD_MOSI;

	// dummy clocks
	for (int i = 0; i < 10; i++) {
		sd_spi_xfer(0xff);
	}

	reg_sd = 0x00;	// SS low

	sd_delay();
	sd_spi_xfer(0x40);
	sd_spi_xfer(0x00);
	sd_spi_xfer(0x00);
	sd_spi_xfer(0x00);
	sd_spi_xfer(0x00);
	sd_spi_xfer(0x95);

	reg_sd = SD_MOSI;
	print("got: ");

	for (int z = 0; z < 10; z++) {

		for (int i = 0; i < 50; i++) {

			if ((reg_sd & SD_MISO) == SD_MISO) print("1"); else print("0");

			reg_sd |= SD_SCK;
			sd_delay();
			reg_sd &= ~SD_SCK;
			sd_delay();

		}

		print("\n");

		sd_delay();
		sd_delay();
		sd_delay();

	}

	//	print("done\n");

}

void sd_spi_xfer(uint8_t b) {
	for (int i = 7; i >= 0; i--) {
		if ((b >> i) & 0x01) reg_sd = SD_MOSI; else reg_sd = 0x00;
		if ((b >> i) & 0x01) print("1"); else print("0");
		reg_sd |= SD_SCK;
		sd_delay();
		reg_sd &= ~SD_SCK;
		sd_delay();
	}
	print("\n");
}

void sd_delay(void) {
	uint32_t x, y;
	for (x = 0; x < 100000; x++) y += x * 2;
}
*/

void cmd_echo() {
	int c;

	while (1) {
		if ((c = getchar()) != EOF) {
			if ((char)c == '0') return;
			putchar(c);
		}
	}

}

void cmd_info() {

	uint8_t tmp;
	uint32_t tmp32;

	print("clk: 0x");
	print_hex(reg_cfg_sys & 0xff, 2);
	print("MHz ");

	print("vid_en: 0x");
	print_hex((reg_cfg_vid & 0x80000000) == 0x80000000, 2);
	print(" ");

	print("cols: 0x");
	print_hex(vid_cols, 2);
	print(" ");

	print("rows: 0x");
	print_hex(vid_rows, 2);
	print(" ");

	print("hres: 0x");
	print_hex(vid_hres, 4);
	print(" ");

	print("vres: 0x");
	print_hex(vid_vres, 4);
	print("\n");

	print("leds: 0x");
	tmp = reg_leds;
	print_hex(tmp, 2);
	print(" ");

	print("uptime: 0x");
	tmp32 = reg_rtc;
	print_hex(tmp32, 8);
	print("\n");

}

void ps2_wait() {
	while ((reg_ps2_ctrl & PS2_CTRL_BUSY) == PS2_CTRL_BUSY);
}

void ps2_read() {
	uint8_t tmp;
	if ((reg_ps2_ctrl & PS2_CTRL_DR) == PS2_CTRL_DR) {

		print("ps2_ctrl: ");
		tmp = reg_ps2_ctrl;
		print_hex(tmp, 2);

		print(" ps2_dat: ");
		tmp = reg_ps2_data;
		print_hex(tmp, 2);

		print(" ");
		putchar(scantoascii(tmp));

		print("\n");

	}
}

void cmd_dump_bytes() {

	uint32_t addr = addr_ptr;
	uint8_t tmp;

	for (int i = 0; i < 16; i++) {
		print_hex(addr, 8);
		print(" ");
		for (int x = 0; x < 16; x++) {
			tmp = (*(volatile uint8_t *)addr);
			print_hex(tmp, 2);
			print(" ");
			addr += 1;
		}
		print("\n");
	}

}

void cmd_dump_words() {

	uint32_t addr = addr_ptr;
	uint32_t tmp;

	for (int i = 0; i < 16; i++) {
		print_hex(addr, 8);
		print(" ");
		for (int x = 0; x < 4; x++) {
			tmp = (*(volatile uint32_t *)addr);
			print_hex(tmp, 8);
			print(" ");
			addr += 4;
		}
		print("\n");
	}

}

void cmd_memzero()
{
	print("zeroing ... ");
   volatile uint32_t *addr = (uint32_t *)addr_ptr;
	for (int i = 0; i < (mem_total / sizeof(int)); i++) {
		(*(volatile uint32_t *)(addr + i)) = 0x00000000;
	}
	print("done.\n");
}

void memcpy(uint32_t dest, uint32_t src, uint32_t n) {
   volatile uint32_t *from = (uint32_t *)src;
   volatile uint32_t *to = (uint32_t *)dest;
	for (int i = 0; i < (n / sizeof(uint32_t)); i++) {
		(*(volatile uint32_t *)(to + i)) = *(from + i);
	}
}

//
// --------------------------------------------------------

void cmd_sleep() {

	for (int i = 0; i < 1000000; i++) {
		reg_delay_us;
	}

}

void cmd_help() {

	print("\n [0] toggle address\n");
	print(" [D] dump memory as bytes\n");
	print(" [W] dump memory as words\n");
	print(" [9] reset memory page\n");
	print(" [ ] next memory page\n");
	print(" [I] system info\n");
	print(" [M] test memory\n");
	print(" [X] receive to memory (xfer)\n");
	print(" [1] led on\n");
	print(" [2] led off\n");
	print(" [B] boot to 0x40000000\n");
	print(" [L] boot LIX\n");
	print(" [E] echo mode (exit with 0)\n");
	print(" [H] help\n\n");

}

void cmd_toggle_addr_ptr(void) {

	if (addr_ptr == MEM_HRAM) {
		addr_ptr = MEM_SRAM;
		mem_total = MEM_SRAM_SIZE;
	} else if (addr_ptr == MEM_SRAM) {
		addr_ptr = MEM_VRAM;
		mem_total = vid_cols * vid_rows;
	} else if (addr_ptr == MEM_VRAM) {
		addr_ptr = MEM_FLASH;
		mem_total = MEM_FLASH_SIZE;
	} else if (addr_ptr == MEM_FLASH) {
		addr_ptr = MEM_HRAM;
		mem_total = MEM_HRAM_SIZE;
	}

}

void cmd_xfer() {
	uint32_t b = xfer_recv(addr_ptr);
	print("xfer received ");
	print_hex(b, 8);
	print(" bytes at ");
	print_hex(addr_ptr, 8);
	print("\n");
}

void cmd_load_lix() {
	print("loading LIX ... ");
	memcpy(LIX_MEM_ADDR, LIX_FLASH_ADDR, LIX_SIZE);
	print("done.\n");
}

void main() {

	int cmd;
	int automated = 0;

	reg_leds = 0x01;

//	if (reg_rtc < 3) automated = 1;

	print("ZBL\n");

	vid_cols = (reg_cfg_vid & 0xff00) >> 8;
	vid_rows = reg_cfg_vid & 0xff;

	vid_hres = (reg_cfg_vid_res & 0xffff0000) >> 16;
	vid_vres = reg_cfg_vid_res & 0xffff;

#if defined FPGA_ICE40 && !BOARD_KOLIBRI && !BOARD_KUCHEN && !BOARD_KROTE
	// clear SRAM
	addr_ptr = MEM_SRAM;
	mem_total = MEM_SRAM_SIZE;
	cmd_memzero();
#endif

	addr_ptr = MEM_HRAM;
	mem_total = MEM_HRAM_SIZE;

	reg_leds = 0x00;

#ifdef EN_BANNER
	print(" _____________ _________\n");
	print("/_  | | |   | | /  _|   \\\n");
	print(" / /_   |  -'   \\  _| ' /\n");
 	print("/___/___|___|__\\_\\__|_:_\\\n");
	print("\n");
#endif

	cmd_info();
	cmd_help();

	while (1) {

		print("ZBL@");
		print_hex(addr_ptr, 8);
		print("> ");

		while (1) {

			cmd = getchar();

			if (cmd != EOF) {
				automated = 0;
				break;
			}

			// auto-boot LIX after 5 seconds
			if (automated && reg_rtc >= 5) {
				cmd_load_lix();
				return;
			}

		}

		print("\n");

		switch (cmd) {
			case 'h':
			case 'H':
				cmd_help();
				break;
			case '0':
				cmd_toggle_addr_ptr();
				break;
			case '1':
				reg_leds = 0x01;
				break;
			case '2':
				reg_leds = 0x00;
				break;
			case '9':
				addr_ptr = 0x40000000;
				break;
			case ' ':
				addr_ptr += 256;
				break;
			case 's':
				cmd_sleep();
				break;
			case 'x':
			case 'X':
				cmd_xfer();
				break;
			case 'i':
			case 'I':
				cmd_info();
				break;
			case 'd':
			case 'D':
				cmd_dump_bytes();
				break;
			case 'w':
			case 'W':
				cmd_dump_words();
				break;
			case 'm':
			case 'M':
				memtest(addr_ptr, mem_total);
				break;
			case 'b':
			case 'B':
				print("booting ... ");
				return;
				break;
			case 'l':
			case 'L':
				cmd_load_lix();
				print("booting LIX ... ");
				return;
				break;
			case 'e':
			case 'E':
				cmd_echo();
				break;
			case 'z':
			case 'Z':
				cmd_memzero();
				break;
			default:
				continue;
		}

	}

}
