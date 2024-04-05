/*
 * LIX OS
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * * Redistribution and use in source, binary or physical forms, with or without
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
#include <ctype.h>

#include "lix.h"
#include "sh.h"
#include "fs.h"
#include "../common/zucker.h"

int main(void) {

	printf("\n      _\n");
	printf("     :_;   ___\n");
	printf(" ___ ___ _|  /\n");
	printf("|   |   \\ | /\n");
	printf("|  _|_  |   |\n");
	printf("|_____|_/ |_\\\n");
	printf("       /__|\n");
	printf("\n");
	printf("LIX %s\n\n", LIX_VERSION);

	printf("mounting fs ... ");
	fflush(stdout);

	if (fs_mount() == 0)
		printf("done.\n");
	else
		printf("failed.\n");

/*
	if (fs_size("/BOOT.BIN")) {
		printf("found /BOOT.BIN, loading ... ");
		fflush(stdout);
		int rv = fs_load(0x40100000, "/BOOT.BIN");
		if (rv) {
			printf("load failed.\n");
		} else {
			printf("done; running ...\n");
			asm volatile ("li a0, 0x40100000");
			asm volatile ("jr a0");
			__builtin_unreachable();
		}
	}
*/

	sh();

}
