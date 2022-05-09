#ifndef ZUCKER_H
#define ZUCKER_H

#include <stdint.h>

#define reg_uart_data (*(volatile uint8_t*)0xf0000000)
#define reg_uart_ctrl (*(volatile uint8_t*)0xf0000004)
#define reg_leds (*(volatile uint8_t*)0xf0001000)
#define reg_rtc (*(volatile uint32_t*)0xf0001100)
#define reg_sdcard (*(volatile uint8_t*)0xf0002000)
#define reg_ps2_data (*(volatile uint8_t*)0xf0003000)
#define reg_ps2_ctrl (*(volatile uint8_t*)0xf0003004)

#define UART_CTRL_TXBUSY 0x02
#define UART_CTRL_DR 0x01

#define PS2_CTRL_OVERFLOW 0x04
#define PS2_CTRL_BUSY 0x02
#define PS2_CTRL_DR 0x01

// --

int getch(void);
void readline(char *buf, int maxlen);
void echo(void);
void noecho(void);

#define VT100_CURSOR_UP       "\e[A"
#define VT100_CURSOR_DOWN     "\e[B"
#define VT100_CURSOR_RIGHT    "\e[C"
#define VT100_CURSOR_LEFT     "\e[D"
#define VT100_CURSOR_HOME     "\e[;H"
#define VT100_CURSOR_MOVE_TO  "\e[%i;%iH"
#define VT100_CURSOR_CRLF     "\e[E"
#define VT100_CLEAR_HOME      "\e[;H"
#define VT100_ERASE_SCREEN    "\e[J"
#define VT100_ERASE_LINE      "\e[K"

#define CH_ESC	0x1b
#define CH_LF	0x0a
#define CH_CR	0x0d
#define CH_FF	0x0c
#define CH_BS	0x08
#define CH_DEL	0x7f

#endif
