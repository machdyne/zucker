/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * newlib system calls, uart/ps2 interface and terminal emulation
 *
 */

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <unistd.h>

#include "zucker.h"
#include "scancodes.h"

void putchar_video(const char c);
char kbdtoascii(void);

int curs_x = 0;
int curs_y = 0;
bool kbd_shift = false;
bool term_echo = true;
bool term_escape = false;
char term_buf[16];
int term_buf_ptr = 0;

void echo(void) { term_echo = true; }
void noecho(void) { term_echo = false; }

ssize_t _read(int file, void *ptr, size_t len)
{
   unsigned char *p = ptr;
	ssize_t i;
	int uart_dr, kbd_dr;
	char chr;
   for (i = 0; i < len; i++) {
		again:
		uart_dr = 0;
		kbd_dr = 0;
		while (!uart_dr && !kbd_dr) {
   		uart_dr = ((reg_uart_ctrl & UART_CTRL_DR) == UART_CTRL_DR);
   		kbd_dr = ((reg_ps2_ctrl & PS2_CTRL_DR) == PS2_CTRL_DR);
		};
		if (kbd_dr) {
			chr = kbdtoascii();
			if (chr != 0) p[i] = chr; else goto again;
		} else {
			p[i] = (char)reg_uart_data;
		}
		if (p[i] == 0x0a) return i + 1;
		if (p[i] == 0x0d) { p[i] = 0x0a; return i + 1; }
		if (term_echo) {
			while ((reg_uart_ctrl & UART_CTRL_TXBUSY) == UART_CTRL_TXBUSY);
			reg_uart_data = p[i];
			putchar_video(p[i]);
		}
   }
   return len;
}

int getch(void) {
	int uart_dr = ((reg_uart_ctrl & UART_CTRL_DR) == UART_CTRL_DR);
	int kbd_dr = ((reg_ps2_ctrl & PS2_CTRL_DR) == PS2_CTRL_DR);
	char c;
	if (!uart_dr && !kbd_dr) {
		return EOF;
	} else {
		if (kbd_dr) {
			c = kbdtoascii();
			if (c) return c; else return EOF;
		} else {
			return (char)reg_uart_data;
		}
	}
}

void readline(char *buf, int maxlen) {

	int c;
	int pl = 0;

	memset(buf, 0x00, maxlen + 1);

	while (1) {

		c = getch();

		if (c == CH_CR || c == CH_LF) {
			break;
		}
		else if (pl && (c == CH_BS || c == CH_DEL)) {
			pl--;
			buf[pl] = 0x00;
			printf(VT100_CURSOR_LEFT);
			printf(" ");
			printf(VT100_CURSOR_LEFT);
			fflush(stdout);
		}
		else if (c > 0) {
			putchar(c);
			fflush(stdout);
			buf[pl++] = c;
		}

		if (pl == maxlen) break;

   }

	return;

}

char kbdtoascii(void) {

	uint8_t sc = reg_ps2_data;

	if (sc == 0x00) return 0;
	if (sc == 0xf0) {
		while ((reg_ps2_ctrl & PS2_CTRL_DR) != PS2_CTRL_DR);
		sc = reg_ps2_data;
		if (sc == 0x12 || sc == 0x59) kbd_shift = false;
		return 0;
	}

	if (sc == 0x12 || sc == 0x59) { kbd_shift = true; return 0; }
	if (sc == 0x5a) return 0x0a;

	for (int i = 0; i < sizeof(ps2_scancodes); i++) {
		if (ps2_scancodes[i] == (kbd_shift ? sc | 0x100 : sc)) return i;
	}
	return 0;

};

ssize_t _write(int file, const void *ptr, size_t len)
{
	const unsigned char *p = ptr;
	for (int i = 0; i < len; i++) {
		if (p[i] == 0x0a) {
			while ((reg_uart_ctrl & UART_CTRL_TXBUSY) == UART_CTRL_TXBUSY);
			reg_uart_data = (unsigned char)0x0d;
		}
		while ((reg_uart_ctrl & UART_CTRL_TXBUSY) == UART_CTRL_TXBUSY);
		reg_uart_data = (unsigned char)p[i];
		putchar_video(p[i]);
	}
	return len;
}

void putchar_video(const char c) {

   int cols = (reg_cfg_vid & 0xff00) >> 8;
   int rows = reg_cfg_vid & 0xff;

	int xy = curs_y * cols + curs_x;

	if (c == 0x00) return;
	if (c == 0x1b) {
		term_escape = true;
		term_buf_ptr = 0;
		memset(term_buf, 0, 16);
		return;
	}

	if (term_escape) {

		term_buf[term_buf_ptr++] = c;

		if (term_buf_ptr >= 14) { term_escape = false; return; }

		if (!strncmp(term_buf, "[A", 2)) { curs_y--; term_escape = false; }
		if (!strncmp(term_buf, "[B", 2)) { curs_y++; term_escape = false; }
		if (!strncmp(term_buf, "[C", 2)) { curs_x++; term_escape = false; }
		if (!strncmp(term_buf, "[D", 2)) { curs_x--; term_escape = false; }
		if (!strncmp(term_buf, "[;H", 3)) {
			curs_x = 0; curs_y = 0; term_escape = false;
		}
		if (!strncmp(term_buf, "[E", 2)) {
			term_escape = false;
			putchar_video('\n');
		}
		if (!strncmp(term_buf, "[K", 2)) {
			memset((void *)(0x10000000 + xy), 0, cols - curs_x);
			term_escape = false;
		}
		if (!strncmp(term_buf, "[J", 2)) {
			for (int i = xy; i < 2000; i++)
				(*(volatile uint8_t *)(0x10000000 + i)) = ' ';
			term_escape = false;
		}

		if (curs_x < 0) curs_x = 0;
		if (curs_x > cols - 1) curs_x = cols - 1;
		if (curs_y < 0) curs_y = 0;
		if (curs_y > rows - 1) curs_y = rows - 1;

		return;

	}

	if (c == '\n') {
		curs_x = 0;
		curs_y++;
	} else {
		(*(volatile uint8_t *)(0x10000000 + xy)) = c;
		curs_x++;
	}

	// erase to end of line
	memset((void *)(0x10000000 + (curs_y * cols) + curs_x), 0, cols - curs_x);

	if (curs_x > cols - 1) { curs_x = 0; curs_y++; };

	// scroll
	if (curs_y > rows - 1) {
		curs_y = rows - 1;
		memcpy((void *)0x10000000, (void *)(0x10000000 + cols),
			(rows * cols) - cols);
		memset((void *)0x10000000 + (rows * cols) - cols, 0, cols);
	};
}

int _open(const char *pathname, int flags) {
	errno = ENOENT;
	return -1;
}

int _close(int fd) {
	return 0;
}

int _fstat(int file, struct stat *st) {
	errno = ENOENT;
	return -1;
}

extern unsigned char _end[];
uint32_t cbrk = (uint32_t)_end;

void *_sbrk(ptrdiff_t increment)
{
	uint32_t obrk = cbrk;
	cbrk += increment;
	return (void *)obrk;
}

void _exit(int exit_status)
{
	asm volatile ("li a0, 0x00000000");
	asm volatile ("jr a0");
	__builtin_unreachable();
}

// ---

void gpu_blit(uint32_t src, uint32_t dst, uint8_t width, uint8_t rows, uint8_t stride) {
	reg_gpu_blit_src = src;
	reg_gpu_blit_dst = dst;
	reg_gpu_blit_ctl = 0xff000000 | (stride << 16) | (rows << 8) | width;
}
