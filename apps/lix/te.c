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
#include "include/fs.h"
#endif

#define ROWS 24
#define COLS 80

#define MODE_MOVE 0
#define MODE_EDIT 1

#define STATE_NONE 0
#define STATE_ESC0 1
#define STATE_ESC1 2
#define STATE_CMD 3

void te_init(void);
void te_redraw(void);
void te_status(char *notice);
int te_yield(void);

void te_insert(int l, int pos, char c);
void te_insert_line(int line);
void te_delete(int line, int pos);
void te_dump(void);
int te_load(void);
int te_save(void);

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

int te_curs_x, te_curs_y;
int f_lines;

char *te_filename;
te_lines_t *lines;

void te_edit(char *filename) {
	te_filename = filename;
	te_init();
	if (!te_load()) {
		printf("unable to load file %s\n", te_filename);
		exit(0);
	} else {
		te_redraw();
		te_status("");
		while(te_yield());
	}
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

//	printf(VT100_CURSOR_HOME);
//	printf(VT100_ERASE_SCREEN);
//	fflush(stdout);

	te_curs_x = 0;
	te_curs_y = 0;

//	te_redraw();

}

void te_status(char *notice) {
	printf(VT100_CURSOR_MOVE_TO, 24, 0);
	printf(VT100_ERASE_LINE);
	printf("te %s l%i s%i x%i y%i %s", te_filename, f_lines, state, te_curs_x, te_curs_y, notice);
	printf(VT100_CURSOR_MOVE_TO, te_curs_y + 1, te_curs_x + 1);
	fflush(stdout);
}

int te_yield(void) {

	int c = getch();
	if (c == EOF || c == 0) return 1;

	switch(c) {

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

		case(':'):
			if (state == STATE_ESC0)
				state = STATE_CMD;
			break;

		default:

			if (state == STATE_ESC1) {
				if (c == 'A') { te_curs_y--; printf(VT100_CURSOR_UP); }
				if (c == 'B') { te_curs_y++; printf(VT100_CURSOR_DOWN); } 
				if (c == 'C') { te_curs_x++; printf(VT100_CURSOR_RIGHT); }
				if (c == 'D') { te_curs_x--; printf(VT100_CURSOR_LEFT); }
				fflush(stdout);
				state = STATE_NONE;
			}

			else if (state == STATE_CMD) {
				printf("%c", c);
				if (c == 'q') { return(0); }
				if (c == 'w') {
					if (te_save()) te_status("SAVED"); else te_status("FAILED");
				}
				if (c == 'd') { te_dump(); te_status("DEBUG"); }
				state = STATE_NONE;
				return(1);
				break;
			}

			else if (state == STATE_NONE) {
				if (c == CH_BS || c == CH_DEL) {
					te_curs_x--;
					if (te_curs_x > 0)
						te_delete(te_curs_y, te_curs_x);
					te_redraw();
				} else if (c == CH_LF || c == CH_CR) {
					te_curs_x = 0;
					if (te_curs_y + 1 >= f_lines) {
						te_insert_line(te_curs_y);
						f_lines++;
					}
					te_curs_y++;
					te_redraw();
				} else {
					te_insert(te_curs_y, te_curs_x, c);
					te_redraw();
					te_curs_x++;
				}
			}

			break;

	}

	if (te_curs_x < 0) te_curs_x = 0;
	if (te_curs_x > COLS - 1) te_curs_x = COLS - 1;
	if (te_curs_y < 0) te_curs_y = 0;
	if (te_curs_y > ROWS - 1) te_curs_y = ROWS - 1;

	te_status("");

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

// load file
int te_load(void) {

	int fs = 0;
	char *buf = NULL;

	if (te_filename != NULL) {
#ifdef LIX
		fs = fs_size(te_filename);
		buf = fs_mallocfile(te_filename);
#else
		FILE *f = fopen(te_filename, "rb");
		if (f == NULL) return 0;
		fseek(f, 0, SEEK_END);
		fs = ftell(f);
		fseek(f, 0, SEEK_SET);
		buf = malloc(fs);
		fread(buf, fs, 1, f);
		fclose(f);
#endif
	}

	int pos = 0;
	char c;

	for (int i = 0; i < fs; i++) {

		c = buf[i];

		if (c == '\r') continue;

		if (c == '\n') {
			pos = 0;
			te_insert_line(f_lines - 1);
			++f_lines;
			continue;
		}

		te_insert(f_lines - 1, pos, c);
		++pos;

	}

	free(buf);

	return 1;

}

// write file
int te_save(void) {

	int ts = 0;

	char *buf = malloc(1);
	char *p;
	
	te_line_t *ptr = lines->first;

	while (ptr) {

		int ls = strlen(ptr->text);
		p = realloc(buf, ts + ls + 2);
		if (p == NULL) return 0;
		buf = p;
		memcpy(buf + ts, ptr->text, ls);
		ptr = ptr->next;
		ts += ls + 1;
		buf[ts - 1] = '\n';

	};

	buf[ts] = '\0';

	//printf("saving %i bytes\r\n", ts);
	//printf("--\r\n");
	//printf("%s", buf);
	//printf("--\r\n");

#ifdef LIX
	int w = fs_write_file(te_filename, buf, ts);
	if (w != ts) return(0);
#else
	FILE *f = fopen(te_filename, "wb");
	if (f == NULL) return(0);
	int w = fwrite(buf, ts, 1, f);
	if (!w) { fclose(f); return(0); }
	fclose(f);
#endif

	free(buf);
	return(1);

}

// dump memory
void te_dump(void) {

	int l = 0;

	te_line_t *ptr = lines->first;

	while (ptr) {

		printf("::%i::%s::\r\n", l, ptr->text);

		ptr = ptr->next;
		l++;

	};

}

#ifdef MAIN
int main(int argc, char *argv[]) {

	if (argc > 1) {
		te_edit(argv[1]);
	} else {
		printf("%s <filename>\n", argv[0]);
	}

#ifdef CURSES
	endwin();
#endif

	return 0;

}
#endif
