#include <stdio.h>
#include "../common/zucker.h"

int main() {

	uint32_t i = 0;
	uint32_t lsecs = reg_rtc;

	while (1) {

		printf("Hello world #%li!\r\n", i);
		i += 1;

		// wait about a second
		while (reg_rtc == lsecs);
		lsecs = reg_rtc;

	}

}
