#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIDTH 320
#define HEIGHT 240

typedef struct color_t {

	uint8_t red;
	uint8_t blue;
	uint8_t green;

} color_t;

void draw_pixel(uint16_t x, uint16_t y, color_t color);
void draw_line(int x0, int y0, int x1, int y1, color_t color);

int main(void) {

	color_t red, green, blue;

	red.red = 0xff;
	red.green = 0x0;
	red.blue = 0x0;

	green.red = 0x00;
	green.green = 0xff;
	green.blue = 0x0;

	blue.red = 0x00;
	blue.green = 0x0;
	blue.blue = 0xff;

	void *addr = (void *)0x20000000;
	memset(addr, 0, 320*240/2);

	int px, py, c = 0;

	while (1) {

		px = (rand() % WIDTH) - 5;
		py = (rand() % HEIGHT) - 5;
		c = rand() % 3;

		for (int y = py; y < py+5; y++) {
			for (int x = px; x < px+5; x++) {
				draw_pixel(x, y, c == 0 ? blue : c == 1 ? red : green);
			}
		}

	}

	return(0);

}

void draw_pixel(uint16_t x, uint16_t y, color_t color) {

	uint32_t xy = ((y * WIDTH) + x);
	uint32_t odd = xy % 2;

	uint32_t addr = 0x20000000 + (xy / 2);

	uint8_t pixel = (*(volatile uint8_t*)addr);

	if (odd) {

		pixel &= 0xf0;
 
		if (color.blue) pixel |= 0b0001;
		if (color.green) pixel |= 0b0010;
		if (color.red) pixel |= 0b0100;

	} else {

		pixel &= 0x0f; 

		if (color.blue) pixel |= 0b00010000;
		if (color.green) pixel |= 0b00100000;
		if (color.red) pixel |= 0b01000000;

	}

	(*(volatile uint8_t*)addr) = pixel;

}

void draw_line(int x0, int y0, int x1, int y1, color_t color) { 
	for (float t = 0.0; t < 1.0; t+= 0.01) { 
		int x = x0 + (x1 - x0) * t;
		int y = y0 + (y1 - y0) * t;
		draw_pixel(x, y, color);
	} 
}

