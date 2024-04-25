#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../common/zucker.h"
#include "tileset.h"

#define WIDTH 320
#define HEIGHT 240

#define EN_BLIT32 1

#ifdef BAREMETAL

#define reg_gpu_blit_src (*(volatile uint32_t*)0xf0008000)
#define reg_gpu_blit_dst (*(volatile uint32_t*)0xf0008004)
#define reg_gpu_blit_ctl (*(volatile uint32_t*)0xf0008008)

void gpu_blit(uint32_t src, uint32_t dst, uint8_t width, uint8_t rows, uint8_t stride);

void gpu_blit(uint32_t src, uint32_t dst, uint8_t width, uint8_t rows, uint8_t stride) {
	while ((reg_gpu_blit_ctl & 0x80000000) != 0);
	reg_gpu_blit_src = src;
	reg_gpu_blit_dst = dst;
	reg_gpu_blit_ctl = 0xff000000 | (stride << 16) | (rows << 8) | width;
}

void _exit(int exit_status)
{
   asm volatile ("li a0, 0x00000000");
   asm volatile ("jr a0");
   __builtin_unreachable();
}

#endif

typedef struct color_t {

	uint8_t red;
	uint8_t blue;
	uint8_t green;

} color_t;

void draw_pixel(uint16_t x, uint16_t y, color_t color);
void draw_sprite(uint8_t idx, uint16_t x, uint16_t y);

void draw_line(int x0, int y0, int x1, int y1, color_t color);

int main(void) {
/*
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
*/

	void *addr = (void *)0x20009600;
	memset(addr, 0, 320*240/2);

	memcpy(addr, (void *)tileset_bin, sizeof(tileset_bin));

	int px, py, idx;

	for (int i = 0; i < 1000; i++) {

		(*(volatile uint8_t*)(0x10000000 + i)) = 'G';

		px = (rand() % WIDTH) - 5;
		py = (rand() % HEIGHT) - 5;
		idx = rand() % 60;

		draw_sprite(idx, px, py);

/*
		for (int y = py; y < py+5; y++) {
			for (int x = px; x < px+5; x++) {
				draw_pixel(x, y, c == 0 ? blue : c == 1 ? red : green);
			}
		}
*/

	}

	exit(0);

}

void draw_sprite(uint8_t idx, uint16_t x, uint16_t y) {

#ifdef EN_BLIT32
   // width = 32 pixels / 2 bytes per pixel
   // rows = 32 pixels
   // stride = 40 = 320 / 2 pixels per byte / 4 bytes per word
   // src = end_of_sram_addr + sprite_offset
   // dst = stride * screen row + (screen col / 2 bytes per word)
   gpu_blit(0x00002580 + (idx * 40) + (idx * 16),
		0x00000000 + y * 40 + (x / 4), 16, 32, 40);
#else // BLIT16
   // width = 32 pixels / 2 bytes per pixel
   // rows = 32 pixels
   // stride = 80 = 320 / 2 pixels per byte / 2 bytes per word
   // src = end_of_sram_addr + sprite_offset
   // dst = stride * screen row + (screen col / 2 bytes per word)
   gpu_blit(0x00004b00 + (idx * 80) + (idx * 16),
		0x00000000 + y * 80 + (x / 2), 16, 32, 80);
#endif

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

