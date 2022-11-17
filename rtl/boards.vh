`ifdef RIEGEL

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_UART0
`define EN_RTC
`define EN_PS2
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_CSPI_SDCARD
`define EN_SRAM16
`define EN_HRAM
`define EN_GPU
`define EN_GPU_TEXT
`define EN_VIDEO
`define EN_VIDEO_VGA
`define EN_VIDEO_DDMI
//`define EN_KABELLOS

`elsif EIS

`define FPGA_ICE40
`define OSC48
`define SYSCLK50
`define VCLK25
`define EN_UART0
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
`define EN_VIDEO_VGA
`define EN_VIDEO_DDMI

`elsif BONBON

`define FPGA_ICE40
`define OSCRP
`define SYSCLK20
`define EN_LOWBRAM
`define EN_UART0
`define EN_RTC
`define EN_SDCARD
`define EN_CLK10KHZ
`define EN_CSPI_FLASH
`define EN_QQSPI
`define EN_GPU
`define EN_GPU_TEXT
`define EN_VIDEO
`define EN_VIDEO_VGA
`define EN_VIDEO_DDMI

`elsif KEKS

`define FPGA_ICE40
`define OSC100
`define OSCRP
`define SYSCLK50
`define VCLK25
`define EN_UART0
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

`endif
