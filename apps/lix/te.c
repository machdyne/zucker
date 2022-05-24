/*
 * Text Editor
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

#include "../common/zucker.h"
#include "te.h"

#define ROWS 24
#define COLS 80

#define MODE_MOVE 0
#define MODE_EDIT 1

#define STATE_NONE 0
#define STATE_ESC0 1
#define STATE_ESC1 2

void te_init(void);
void te_redraw(void);
void te_status(void);
int te_yield(void);

int mode = MODE_MOVE;
int state = STATE_NONE;
int x, y;

void te_edit(char *filename) {
	te_init();
	while(te_yield());
}

void te_init(void) {

	printf(VT100_CLEAR_HOME);
	printf(VT100_ERASE_SCREEN);
	fflush(stdout);

	x = 1;
	y = 1;

//	te_redraw();

}

void te_redraw(void) {
//	te_status();
}

void te_status(void) {
/*
	printf(VT100_CURSOR_MOVE_TO, 24, 0);
	printf(VT100_ERASE_LINE);
	printf("STAHL x%i y%i", x, y);
	printf(VT100_CURSOR_MOVE_TO, y, x);
	fflush(stdout);
*/
}

int te_yield(void) {

	int c = getch();
	if (c == EOF || c == 0) return 1;

	switch(c) {

		case('Q'):
			return(0);
			break;

		case(CH_ESC):
			state = STATE_ESC0;
			break;

		case(CH_FF):
			te_redraw();
			break;

		case('['):
			if (state == STATE_ESC0)
				state = STATE_ESC1;
			break;

		default:
			if (state == STATE_ESC1) {
				if (c == 'A') { y--; printf(VT100_CURSOR_UP); }
				if (c == 'B') { y++; printf(VT100_CURSOR_DOWN); } 
				if (c == 'C') { x++; printf(VT100_CURSOR_RIGHT); }
				if (c == 'D') { x--; printf(VT100_CURSOR_LEFT); }
				fflush(stdout);
				state = STATE_NONE;
				break;
			}

			if (state == STATE_NONE) {
				x++;
				if (c == CH_BS) {
					x -= 2;
					printf(VT100_CURSOR_LEFT);
					printf(" ");
					printf(VT100_CURSOR_LEFT);
					printf(VT100_CURSOR_LEFT);
					printf(VT100_CURSOR_LEFT);
				} else if (c == CH_LF) {
					printf(VT100_CURSOR_CRLF);
				} else {
					printf("%c", c);
				}
				fflush(stdout);
			}
			break;

	}

	if (x < 1) x = 1;
	if (x > COLS - 1) x = COLS - 1;
	if (y < 1) y = 1;
	if (y > ROWS - 1) y = ROWS - 1;

//	te_status();
//	fflush(stdout);

	return 1;

}
