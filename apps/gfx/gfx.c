#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIDTH 640
#define HEIGHT 480

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
	memset(addr, 0, 640*480/2);

	for (int x = 50; x < 60; x++)
		draw_pixel(x, 50, red);

	for (int x = 50; x < 60; x++)
		draw_pixel(x, 150, green);

	for (int x = 50; x < 60; x++)
		draw_pixel(x, 250, blue);

	for (int y = 50; y < 60; y++)
		draw_line(100, y, 300, y, red);

}

void draw_pixel(uint16_t x, uint16_t y, color_t color) {

	uint32_t xy = ((y * WIDTH) + x);
	uint32_t odd = xy % 2;

	uint32_t addr = 0x20000000 + (xy / 2);

	uint8_t pixel = (*(volatile uint8_t*)addr);

	if (odd) {

		pixel &= 0xf0;
 
		if (color.red) pixel |= 0b0001;
		if (color.green) pixel |= 0b0010;
		if (color.blue) pixel |= 0b0100;

	} else {

		pixel &= 0x0f; 

		if (color.red) pixel |= 0b00010000;
		if (color.green) pixel |= 0b00100000;
		if (color.blue) pixel |= 0b01000000;

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

