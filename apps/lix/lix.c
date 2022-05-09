/*
 * LIX OS
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
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

	if (fs_size("/BOOT.BIN")) {
		printf("found /BOOT.BIN.");
		int rv = fs_load(0x40100000, "/BOOT.BIN");
		if (rv) {
			printf("load failed.\n");
		} else {
			printf("running ...\n");
			asm volatile ("li a0, 0x40100000");
			asm volatile ("jr a0");
			__builtin_unreachable();
		}
	}

	printf("\n");
	sh();

}
