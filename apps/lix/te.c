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
#include <stdlib.h>
#include <string.h>

#define MAX_STRLEN 1024

#ifdef CURSES
#include <ncurses.h>
#define VT100_CURSOR_UP       "\e[A"
#define VT100_CURSOR_DOWN     "\e[B"
#define VT100_CURSOR_RIGHT    "\e[C"
#define VT100_CURSOR_LEFT     "\e[D"
#define VT100_CURSOR_HOME     "\e[;H"
#define VT100_CURSOR_MOVE_TO  "\e[%i;%iH"
#define VT100_CURSOR_CRLF     "\e[E"
#define VT100_ERASE_SCREEN    "\e[J"
#define VT100_ERASE_LINE      "\e[K"
#define CH_ESC 0x1b
#define CH_LF  0x0a
#define CH_CR  0x0d
#define CH_FF  0x0c
#define CH_BS  0x08
#define CH_DEL 0x7f
#endif

#ifdef LIX
#include "../common/zucker.h"
#include "include/te.h"
#endif

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

void te_insert(int l, int pos, char c);
void te_delete(int line, int pos);
void te_dump(void);


typedef struct te_lines_t {
	struct te_line_t *first;
	struct te_line_t *last;
} te_lines_t;

typedef struct te_line_t {
	char *text;
	struct te_line_t *prev;
	struct te_line_t *next;
} te_line_t;

int mode = MODE_MOVE;
int state = STATE_NONE;

extern int curs_x, curs_y;
int f_lines;

te_lines_t *lines;


void te_edit(char *filename) {
	te_init();
	while(te_yield());
}

void te_init(void) {

	te_line_t *line;

	f_lines = 1;

	lines = calloc(1, sizeof(te_lines_t));
	line = calloc(1, sizeof(te_line_t));

	line->text = calloc(1, 1);

	line->prev = NULL;
	line->next = NULL;

	lines->first = line;
	lines->last = line;

#ifdef CURSES
	initscr();
	noecho();
#endif

	printf(VT100_CURSOR_HOME);
	printf(VT100_ERASE_SCREEN);
	fflush(stdout);

	curs_x = 0;
	curs_y = 0;

	te_redraw();

}

void te_status(void) {
	printf(VT100_CURSOR_MOVE_TO, 24, 0);
	printf(VT100_ERASE_LINE);
	printf("te x%i y%i", curs_x, curs_y);
	printf(VT100_CURSOR_MOVE_TO, curs_y + 1, curs_x + 1);
	fflush(stdout);
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
				if (c == 'A') { curs_y--; printf(VT100_CURSOR_UP); }
				if (c == 'B') { curs_y++; printf(VT100_CURSOR_DOWN); } 
				if (c == 'C') { curs_x++; printf(VT100_CURSOR_RIGHT); }
				if (c == 'D') { curs_x--; printf(VT100_CURSOR_LEFT); }
				fflush(stdout);
				state = STATE_NONE;
				break;
			}

			if (state == STATE_NONE) {
				if (c == CH_BS || c == CH_DEL) {
					curs_x--;
					if (curs_x > 0)
						te_delete(curs_y, curs_x);
					te_redraw();
				} else if (c == CH_LF || c == CH_CR) {
					curs_x = 0;
					if (curs_y + 1 >= f_lines) {
						te_insert_line(curs_y);
						f_lines++;
					}
					curs_y++;
					te_redraw();
				} else {
					te_insert(curs_y, curs_x, c);
					te_redraw();
					curs_x++;
				}
			}
			break;

	}

	if (curs_x < 0) curs_x = 0;
	if (curs_x > COLS - 1) curs_x = COLS - 1;
	if (curs_y < 0) curs_y = 0;
	if (curs_y > ROWS - 1) curs_y = ROWS - 1;

	te_status();

	return 1;

}

void te_redraw() {

	int l = 0;

	te_line_t *ptr = lines->first;

	printf(VT100_CURSOR_HOME);
	printf(VT100_ERASE_SCREEN);

	while (ptr) {

		printf(VT100_CURSOR_MOVE_TO, l+1, 1);
		puts(ptr->text);
		
		ptr = ptr->next;
		l++;

	}

}

void te_insert(int line, int pos, char c) {

	int l = 0;

	te_line_t *ptr = lines->first;

	while (ptr) {

		if (l == line) {
			int linelen = strlen(ptr->text);
			char *newtext = calloc(1, linelen + 2);
			if (newtext == NULL) return;
			memcpy(newtext, ptr->text, pos);
			newtext[pos] = c;
			memcpy(newtext + pos + 1, ptr->text + pos, linelen - pos);
			free(ptr->text);
			ptr->text = newtext;
			break;
		}

		ptr = ptr->next;
		l++;

	};

}

void te_insert_line(int line) {

	int l = 0;

	te_line_t *ptr = lines->first;

	while (ptr) {

		if (l == line) {

			te_line_t *newline = calloc(1, sizeof(te_line_t));
			char *newtext = calloc(1, 1);

			newline->text = newtext;
			newline->prev = ptr;
			newline->next = ptr->next;

			ptr->next = newline;

			break;
		}

		ptr = ptr->next;
		l++;

	};

}

void te_delete(int line, int pos) {

	int l = 0;

	te_line_t *ptr = lines->first;

	while (ptr) {

		if (l == line) {
			int linelen = strlen(ptr->text);
			char *newtext = calloc(1, linelen);
			if (newtext == NULL) return;
			if (pos == 0) {
				memcpy(newtext, ptr->text + 1, linelen - pos - 1);
			} else {
				memcpy(newtext, ptr->text, pos);
				memcpy(newtext + pos, ptr->text + pos + 1, linelen - pos - 1);
			}
			free(ptr->text);
			ptr->text = newtext;
			break;
		}

		ptr = ptr->next;
		l++;

	};

}

// dump line
void te_dump(void) {

	int l = 0;

	te_line_t *ptr = lines->first;

	while (ptr) {

		printf("::%i::%s::\n", l, ptr->text);

		ptr = ptr->next;
		l++;

	};

	printf("done.\n");

}

#ifdef MAIN
int main(int argc, char *argv[]) {

	te_init();
	while(te_yield());

	te_dump();

#ifndef CURSES
	echo();
#endif

	return 0;

}
#endif
