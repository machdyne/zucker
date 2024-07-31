// UNIVERSAL CONFIG
// ----------------

`define EN_UART0
`define UART0_HW_FLOW

// BOARD CONFIG
// ------------

`ifdef RIEGEL

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_UART0
`define EN_SPI
`define EN_RTC
`define EN_PS2
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_CSPI_SDCARD
`define EN_SRAM16
`define EN_HRAM
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT16
`define EN_VIDEO
`define EN_VIDEO_VGA
//`define EN_VIDEO_DDMI
//`define EN_KABELLOS

`elsif EIS

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_UART0
`define EN_SPI
`define EN_RTC
`define EN_RPDEBUG
`define EN_MUSLI_KBD
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_CSPI_SDCARD
`define EN_SRAM16
`define EN_HRAM
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_VIDEO
`define EN_VIDEO_DDMI

`elsif KOLIBRI

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define EN_UART0
`define EN_SPI
`define EN_RTC
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_HRAM

`elsif BONBON

`define FPGA_ICE40
`define OSCRP
`define SYSCLK20
`define EN_LOWBRAM
`define EN_UART0
`define EN_SPI
`define EN_RTC
`define EN_SDCARD
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_QQSPI
//`define EN_GPU
//`define EN_GPU_TEXT
//`define EN_VIDEO
//`define EN_VIDEO_VGA
//`define EN_VIDEO_DDMI

`elsif KEKS

`define FPGA_ICE40
`define OSC100
`define OSCRP
`define SYSCLK50
`define VCLK25
`define EN_UART0
`define EN_SPI
//`define EN_RTC
`define EN_CLK10KHZ
//`define EN_CSPI_RPMEM
//`define EN_CART
`define EN_RPINT
`define EN_RPDEBUG
`define EN_SRAM32
`define EN_HRAM
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_VIDEO
`define EN_VIDEO_VGA
`define EN_VIDEO_DDMI
//`define EN_VIDEO_COMPOSITE
`define EN_AUDIO

`elsif KUCHEN

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_SDRAM
`define EN_UART0
`define EN_SPI
`define EN_CSPI_FLASH
`define EN_SDCARD
`define EN_RTC
`define EN_CLK10KHZ
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_VIDEO
`define EN_VIDEO_DDMI

`elsif SCHOKO

`define FPGA_ECP5
`define OSC48
`define SYSCLK50
`define VCLK25
//`define EN_SDRAM
`define EN_QQSPI
`define EN_BSRAM32
`define EN_CSPI_FLASH
`define EN_SDCARD
`define EN_UART0
`define EN_SPI
`define EN_RTC
`define EN_CLK10KHZ
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT32
`define EN_VIDEO
`define EN_VIDEO_VGA
`define EN_VIDEO_DDMI

`elsif KONFEKT

`define FPGA_ECP5
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_SDRAM
`define EN_BSRAM32
`define EN_CSPI_FLASH
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_SPI
`define EN_RTC
`define EN_CLK10KHZ
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT32
`define EN_VIDEO
`define EN_VIDEO_DDMI

`elsif OBST

`define FPGA_ECP5
`define OSC48
`define SYSCLK50
//`define VCLK25
//`define EN_BSRAM32
`define EN_SRAM32
`define EN_SRAM_FAST
`define EN_SPI
`define EN_CSPI_FLASH
`define EN_SDCARD
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_RTC
`define EN_CLK10KHZ
`define EN_PS2
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_MONO
//`define EN_GPU_FB_PIXEL_DOUBLING
//`define EN_GPU_BLIT
//`define EN_GPU_BLIT32
`define EN_VIDEO
`define EN_VIDEO_VGA
`define EN_QQSPI

`elsif MINZE

`define FPGA_ECP5
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_SDRAM
`define EN_BSRAM32
`define EN_CSPI_FLASH
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_SPI
`define EN_SDCARD
`define EN_RTC
`define EN_CLK10KHZ
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT32
`define EN_VIDEO
`define EN_VIDEO_VGA

`elsif VANILLE

`define FPGA_ECP5
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_SDRAM
`define EN_SRAM16
`define EN_CSPI_FLASH
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_SPI
`define EN_CSPI_SDCARD
`define EN_CSPI_SDCARD_SCK
`define EN_RTC
`define EN_CLK10KHZ
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT16
`define EN_VIDEO
`define EN_VIDEO_DDMI

`elsif KROTE

`define FPGA_ICE40
`define OSC100
`define SYSCLK25
`define VCLK25
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_RTC
`define EN_SPI
`define EN_CSPI_FLASH
`define EN_CLK10KHZ
`define EN_QQSPI

`elsif KOLSCH_V0

`define FPGA_GATEMATE
`define OSC50
`define SYSCLK25
`define VCLK25
`define EN_UART0
`define EN_RTC
`define EN_CLK10KHZ

`elsif KOLSCH_V1

`define FPGA_GATEMATE
`define OSC50
`define SYSCLK25
`define VCLK25
`define EN_UART0
`define EN_RTC
`define EN_CLK10KHZ
//`define EN_SDRAM

`elsif KOLSCH_V2

`define FPGA_GATEMATE
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_UART0
`undef UART0_HW_FLOW
`define EN_RTC
`define EN_CLK10KHZ
`define EN_SDRAM
`define EN_SDRAM_64MB
`define EN_BSRAM32
`define EN_GPU
`define EN_GPU_TEXT
`define EN_GPU_FB
`define EN_GPU_FB_PIXEL_DOUBLING
`define EN_GPU_BLIT
`define EN_GPU_BLIT32
`define EN_VIDEO
`define EN_VIDEO_VGA

`elsif LOWE

`define FPGA_GATEMATE
`define OSC50
`define SYSCLK25
`define VCLK25
`define EN_UART0
`define EN_RTC
`define EN_CLK10KHZ
`define EN_QQSPI

`elsif CCEVAL

`define FPGA_GATEMATE
`define OSC10
`define SYSCLK25
`define VCLK25
`define EN_UART0
`define EN_RTC
`define EN_CLK10KHZ
`define EN_QQSPI

`endif
