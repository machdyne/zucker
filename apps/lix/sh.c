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
#include <stdbool.h>
#include <string.h>

#include "lix.h"
#include "fs.h"
#include "xfer.h"
#include "te.h"
#include "../common/zucker.h"

void hex_dump(uint32_t addr);
void text_edit(char *filename);
char *get_arg(char *str, int n);
void sh_help(void);

void terminal(void);

void l_init_lix(bool stdlib);
void l_ep(char *buf);

void sh_help(void) {

	printf("commands:\n");
	printf(" mount             mount a newly inserted SD card\n");
	printf(" ls [dir]          list directory\n");
	printf(" run <file>        load and run a file\n");
	printf(" df                display disk space and usage\n");
	printf(" mkdir <dir>       make directory\n");
	printf(" touch <file>      create an empty file\n");
	printf(" rm [file/dir]     delete file or directory\n");
	printf(" xa [addr]         receive to addr via xfer\n");
	printf(" xf <file>         receive to file via xfer\n");
	printf(" boot              jump to 0x40100000 \n");
	printf(" bootf             jump to 0x80100000 \n");
	printf(" uptime            display uptime in seconds\n");
	printf(" hd [hexaddr]      hex dump\n");
	printf(" te <file>         edit text file (not working yet)\n");
	printf(" uname             print system information\n");
	printf(" (+ 1 2 3)         run lisp code\n");
	printf(" (dump)            display lisp environment\n");
	printf(" term              terminal for uart1 (kabellos)\n");
	printf(" format            completely erase an SD card\n");
	printf(" exit              exit to bootloader\n");

}

void sh(void) {

	char buffer[256];
	int cmdlen;
	char *cmdend;
	char *arg;
	int rv;

	printf("loading lisp stdlib ... ");
	fflush(stdout);
	l_init_lix(true);
	printf("done.\n");

   printf("type help for a list of available commands.");
   printf("\n");

	while (1) {

		printf("lix> ");
		fflush(stdout);

		readline(buffer, 255);
		cmdend = strchr(buffer, ' ');

		if (cmdend == NULL)
			cmdlen = 255;
		else
			cmdlen = cmdend - buffer;

		printf("\n");

		if (buffer[0] == '(') {
			l_ep(buffer);
		}

		if (!strncmp(buffer, "help", cmdlen)) sh_help();
		if (!strncmp(buffer, "uname", cmdlen))
			printf("lix %s\n", LIX_VERSION);
		if (!strncmp(buffer, "uptime", cmdlen))
			printf("uptime: %li\n", reg_rtc);

		// TERMINAL
		if (!strncmp(buffer, "term", cmdlen)) {
			terminal();
		}

		// LIST DIRECTORY
		if (!strncmp(buffer, "ls", cmdlen)) {
			arg = get_arg(buffer, 1);
			if (arg != NULL)
				fs_list_dir(arg);
			else
				fs_list_dir("/");
		}

		// MAKE DIRECTORY
		if (!strncmp(buffer, "mkdir", cmdlen)) {
			arg = get_arg(buffer, 1);
			if (arg != NULL)
				fs_mkdir(arg);
			else
				printf("error: no file/directory specified\n");
		}

		// TOUCH FILE
		if (!strncmp(buffer, "touch", cmdlen)) {
			arg = get_arg(buffer, 1);
			if (arg != NULL)
				fs_touch(arg);
			else
				printf("error: no file/directory specified\n");
		}

		// REMOVE FILE/DIRECTORY
		if (!strncmp(buffer, "rm", cmdlen)) {
			arg = get_arg(buffer, 1);
			if (arg != NULL)
				fs_unlink(arg);
			else
				printf("error: no file/directory specified\n");
		}

		// LOAD FILE
		if (!strncmp(buffer, "load", cmdlen)) {
			arg = get_arg(buffer, 1);
			rv = fs_load(0x40100000, arg);
			if (rv) {
				printf("load failed\n");
			} else {
				printf("load ok\n");
			}
		}

		// HEX DUMP
		if (!strncmp(buffer, "hd", cmdlen)) {
			arg = get_arg(buffer, 1);
			uint32_t addr;
			if (sscanf(arg, "%lx", &addr))
				hex_dump(addr);
		}

		// TEXT EDITOR
		if (!strncmp(buffer, "te", cmdlen)) {
			arg = get_arg(buffer, 1);
			te_edit(arg);
		}

		// RUN FILE
		if (!strncmp(buffer, "run", cmdlen)) {
			arg = get_arg(buffer, 1);
			rv = fs_load(0x40100000, arg);
			if (rv) {
				printf("load failed\n");
			} else {
				printf("running ...\n");
				asm volatile ("li a0, 0x40100000");
				asm volatile ("jr a0");
				__builtin_unreachable();
			}
		}

		// RECEIVE TO ADDR VIA XFER
		if (!strncmp(buffer, "xa", cmdlen)) {
			arg = get_arg(buffer, 1);
			uint32_t addr, bytes;
			if (!sscanf(arg, "%lx", &addr))
				addr = 0x40100000;
			printf("xfer addr 0x%lx; ready to receive (press D to cancel) ...\n",
				addr);
			bytes = xfer_recv(addr);
			printf("received %li bytes to 0x%lx.\n", bytes, addr);
		}

		// RECEIVE TO FILE VIA XFER
		if (!strncmp(buffer, "xf", cmdlen)) {
			arg = get_arg(buffer, 1);
			uint32_t bytes_received, bytes_written;
			uint32_t addr = 0x40100000;
			printf("uploading to file %s.\n", arg);
			printf("xfer addr 0x%lx; ready to receive (press D to cancel) ...\n",
				addr);
			bytes_received = xfer_recv(addr);
			printf("received %li bytes to 0x%lx.\n", bytes_received, addr);
			if (bytes_received) {
				printf("writing to file %s ... ", arg);
				fflush(stdout);
				bytes_written = fs_write_file(arg, (void *)0x40100000,
					bytes_received);
				if (bytes_written == bytes_received)
					printf("done.\n");
				else
					printf("failed.\n");
			}
		}

		// BOOT USER CODE
		if (!strncmp(buffer, "boot", cmdlen)) {
			asm volatile ("li a0, 0x40100000");
			asm volatile ("jr a0");
			__builtin_unreachable();
		}

		if (!strncmp(buffer, "bootf", cmdlen)) {
			asm volatile ("li a0, 0x80100000");
			asm volatile ("jr a0");
			__builtin_unreachable();
		}

		// FREE DISK SPACE
		if (!strncmp(buffer, "df", cmdlen)) {
			uint32_t free = fs_free();
			uint32_t total = fs_total();
			printf("%luMB total %luMB free\n", total/1024, free/1024);
		}

		// MOUNT DRIVE
		if (!strncmp(buffer, "mount", cmdlen)) {
			fs_mount();
		}

		// FORMAT DRIVE
		if (!strncmp(buffer, "format", cmdlen)) {
			printf("type YES to format the SD card: ");
			fflush(stdout);
			fgets(buffer, 255, stdin);
			printf("\n");
			if (!strncmp(buffer, "YES", 3)) {
				printf("formatting (this may take several minutes) ...\n");
				fs_format();
			}
		}
		if (!strncmp(buffer, "exit", cmdlen)) return;

	}

}

void hex_dump(uint32_t addr) {

	uint8_t tmp;

	for (int i = 0; i < 16; i++) {
		printf("%.8lx ", addr);
		printf(" ");
		for (int x = 0; x < 16; x++) {
			tmp = (*(volatile uint8_t *)addr);
			printf("%.2x ", tmp);
			addr += 1;
		}
		printf("\n");
	}

}

char *get_arg(char *str, int n) {

   char *token;
   int tn = 0;

	token = strtok(str, " ");

   while (token != NULL && tn != n) {
      token = strtok(NULL, " ");
		tn++;
   }

   return token;

}
