/*
 * LIX OS
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * Redistribution and use in source, binary or physical forms, with or without
 * modification, is permitted provided that the following condition is met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * THIS HARDWARE, SOFTWARE, DATA AND/OR DOCUMENTATION ("THE ASSETS") IS
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE ASSETS OR THE USE OR OTHER
 * DEALINGS IN THE ASSETS. USE AT YOUR OWN RISK.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "../common/zucker.h"

void terminal(void);

int term_getch(void) {
	int uart1_dr = ((reg_uart1_ctrl & UART_CTRL_DR) == UART_CTRL_DR);
	if (!uart1_dr) {
		return EOF;
	} else {
		return (char)reg_uart1_data;
	}
}

void term_putch(int c) {
	while ((reg_uart1_ctrl & UART_CTRL_TXBUSY) == UART_CTRL_TXBUSY);
	reg_uart1_data = (char)c;
}

void term_print(const char *p) {
	while (*p)
		term_putch(*(p++));
}

void terminal(void) {

	int lc, rc;

	printf("LIX terminal. press ESC to exit.\n");

	printf("initializing ESP32-C3 ...\n\n");
	term_print("AT\r\n");
	term_print("AT+UART_CUR=115200,8,1,0,3\r\n");
	term_print("AT\r\n");
	term_print("AT+GMR\r\n");

	while (1) {

		lc = getch();
		rc = term_getch();

		if (rc != EOF) {
			putchar(rc);
			fflush(stdout);
		}

		if (lc != EOF) {
			if (lc == CH_ESC) return;
			term_putch(lc);
			if (lc == 0x0d) term_putch(0x0a);
		}

	}

}
