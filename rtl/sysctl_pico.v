/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * System Controller
 *
 */

`include "boards.vh"

`ifdef SYSCLK100
localparam SYSCLK = 100_000_000;
`elsif SYSCLK80
localparam SYSCLK = 80_000_000;
`elsif SYSCLK75
localparam SYSCLK = 75_000_000;
`elsif SYSCLK64
localparam SYSCLK = 64_000_000;
`elsif SYSCLK50
localparam SYSCLK = 50_000_000;
`elsif SYSCLK48
localparam SYSCLK = 48_000_000;
`elsif SYSCLK36
localparam SYSCLK = 36_000_000;
`elsif SYSCLK25
localparam SYSCLK = 25_000_000;
`elsif SYSCLK24
localparam SYSCLK = 24_000_000;
`elsif SYSCLK20
localparam SYSCLK = 20_000_000;
`endif

localparam UART0_BAUDRATE = 115200; 

module sysctl #()
(

`ifdef OSC100
	input CLK_100,
`endif
`ifdef OSC50
	input CLK_50,
`endif
`ifdef OSC48
	input CLK_48,
`endif
`ifdef OSC10
	input CLK_10,
`endif
`ifdef OSCRP
	input CLK_RP,
`endif

	output reg LED_A,
	output reg led_g,
	output reg led_b,

`ifdef CCEVAL
	output led2,
	output led3,
	output led4,
	output led5,
	output led6,
	output led7,
	output led8,
`endif

`ifdef LOWE
	output pmoda1,
	output pmoda2,
	output pmoda3,
	output pmoda4,
	output pmoda7,
	output pmoda8,
	output pmoda9,
	output pmoda10,
`endif

	output UART0_RX,
	input UART0_TX,
`ifdef UART0_HW_FLOW
	input UART0_RTS,
	output reg UART0_CTS,
`endif

`ifdef EN_SPI
	inout SPI_MISO,
	inout SPI_MOSI,
`ifndef FPGA_ECP5
	output SPI_SCK,
`endif
`endif

`ifdef EN_CSPI_FLASH
	output SPI_SS_FLASH,
`endif

`ifdef EN_CSPI_SDCARD
	output SPI_SS_SD,
`ifdef EN_CSPI_SDCARD_SCK	// dedicated SCK
	output SD_SCK,
`endif
`endif

`ifdef EN_CSPI_RPMEM
	output SPI_SS,
	input RP_HOLD,
`endif

`ifdef EN_SDCARD
	output SD_SS,
	inout SD_MISO,
	output SD_MOSI,
	output SD_SCK,
`endif

`ifdef EN_CART
	output CART_SS,
	output CART_MOSI,
	input CART_MISO,
	output CART_SCK,
`endif

`ifdef EN_PS2
	inout PS2_DAT,
	inout PS2_CLK,
`endif

`ifdef EN_MUSLI_KBD
	input MUSLI_SCK,
	input MUSLI_MOSI,
`endif

`ifdef EN_VIDEO_VGA
	output VGA_R,
	output VGA_G,
	output VGA_B,
	output VGA_HS,
	output VGA_VS,
`endif

`ifdef EN_VIDEO_DDMI
	output DDMI_D0_P,
	output DDMI_D1_P,
	output DDMI_D2_P,
	output DDMI_CK_P,
`ifndef FPGA_ECP5
	output DDMI_D0_N,
	output DDMI_D1_N,
	output DDMI_D2_N,
	output DDMI_CK_N,
`endif
`endif

`ifdef EN_VIDEO_COMPOSITE
	output COMP_D0,
	output COMP_D1,
	output COMP_D2,
	output COMP_D3,
`endif

`ifdef EN_AUDIO
	output AUDIO_L,
	output AUDIO_R,
`endif

`ifdef EN_SRAM16
	output SRAM_A0, SRAM_A1, SRAM_A2, SRAM_A3,
		SRAM_A4, SRAM_A5, SRAM_A6, SRAM_A7,
		SRAM_A8, SRAM_A9, SRAM_A10, SRAM_A11,
		SRAM_A12, SRAM_A13, SRAM_A14, SRAM_A15,
		SRAM_A16, SRAM_A17,

	inout SRAM0_D0, SRAM0_D1, SRAM0_D2, SRAM0_D3,
		SRAM0_D4, SRAM0_D5, SRAM0_D6, SRAM0_D7,
		SRAM0_D8, SRAM0_D9, SRAM0_D10, SRAM0_D11,
		SRAM0_D12, SRAM0_D13, SRAM0_D14, SRAM0_D15,

`ifdef VANILLE
	output SRAM0_WE, SRAM0_OE, SRAM0_LB, SRAM0_UB,
`else
	output SRAM0_CE, SRAM0_WE, SRAM0_OE, SRAM0_LB, SRAM0_UB,
`endif
`endif

`ifdef EN_SRAM32
	output SRAM_A0, SRAM_A1, SRAM_A2, SRAM_A3,
		SRAM_A4, SRAM_A5, SRAM_A6, SRAM_A7,
		SRAM_A8, SRAM_A9, SRAM_A10, SRAM_A11,
		SRAM_A12, SRAM_A13, SRAM_A14, SRAM_A15,
		SRAM_A16, SRAM_A17,

	inout SRAM0_D0, SRAM0_D1, SRAM0_D2, SRAM0_D3,
		SRAM0_D4, SRAM0_D5, SRAM0_D6, SRAM0_D7,
		SRAM0_D8, SRAM0_D9, SRAM0_D10, SRAM0_D11,
		SRAM0_D12, SRAM0_D13, SRAM0_D14, SRAM0_D15,

	inout SRAM1_D0, SRAM1_D1, SRAM1_D2, SRAM1_D3,
		SRAM1_D4, SRAM1_D5, SRAM1_D6, SRAM1_D7,
		SRAM1_D8, SRAM1_D9, SRAM1_D10, SRAM1_D11,
		SRAM1_D12, SRAM1_D13, SRAM1_D14, SRAM1_D15,

	output SRAM0_CE, SRAM0_WE, SRAM0_OE, SRAM0_LB, SRAM0_UB,
	output SRAM1_CE, SRAM1_WE, SRAM1_OE, SRAM1_LB, SRAM1_UB,
`endif

`ifdef EN_HRAM
	inout HRAM_ADQ0, HRAM_ADQ1, HRAM_ADQ2, HRAM_ADQ3,
		HRAM_ADQ4, HRAM_ADQ5, HRAM_ADQ6, HRAM_ADQ7,
		HRAM_DQ8, HRAM_DQ9, HRAM_DQ10, HRAM_DQ11,
		HRAM_DQ12, HRAM_DQ13, HRAM_DQ14, HRAM_DQ15,
		HRAM_DQS0, HRAM_DQS1,

	output HRAM_CE, HRAM_CK,
`endif

`ifdef EN_QQSPI
`ifdef BONBON
	output SPI_SS_RAM0,
	output SPI_SS_RAM1,
	output SPI_SS_RAM2,
	output SPI_SS_RAM3,
	inout SPI_IO2,
	inout SPI_IO3,
`elsif BROT
	output SPI_SS_RAM,
	inout SPI_IO2,
	inout SPI_IO3,
`else
	output QQSPI_SS,
	output QQSPI_SCK,
	inout QQSPI_MISO,
	inout QQSPI_MOSI,
	inout QQSPI_SIO2,
	inout QQSPI_SIO3,
	output QQSPI_CS1,
	output QQSPI_CS0,
`endif
`endif

`ifdef EN_SDRAM
	output [12:0] sdram_a,
	inout [15:0] sdram_dq,
	output sdram_cs_n,
	output sdram_cke,
	output sdram_ras_n,
	output sdram_cas_n,
	output sdram_we_n,
	output [1:0] sdram_dm,
	output [1:0] sdram_ba,
	output sdram_clock,
`endif

`ifdef EN_RPINT
	input RP_INT,
	input RP_TX,
	input RP_HOLD,
`endif

);

	// XXX
	assign led_g = UART0_CTS;
	assign led_b = 1;

	// CLOCKS
	// ------

	wire clk;

	wire clk25mhz;
	wire clk50mhz;
	wire clk75mhz;
	wire clk100mhz;
	wire clk125mhz;
	wire clk126mhz;

	reg clk10khz;

`ifdef EN_CLK10KHZ
	reg [12:0] clk10khz_ctr;
	always @(posedge clk) begin
		clk10khz_ctr <= clk10khz_ctr + 1;
		if (clk10khz_ctr == 4999) begin
			clk10khz_ctr <= 0;
			clk10khz <= ~clk10khz;
		end
	end
`endif

	wire pll_locked;

`ifdef FPGA_ICE40
	reg [4:0] ctr25mhz = 5'b00011;
`ifdef VCLK25
	always @(posedge clk125mhz) begin
`else
	always @(posedge clk126mhz) begin
`endif
		ctr25mhz <= { ctr25mhz[0], ctr25mhz[4:1] };
	end
	assign clk25mhz = ctr25mhz[0];
`endif

`ifdef FPGA_GATEMATE
/*
	// 25mhz sysclk
	wire pll_locked = 1;
	reg clk;
	always @(posedge CLK_50) begin
		clk <= ~clk;
	end
*/	

   wire clk270, clk180, clk90, usr_ref_out;

   CC_PLL #(
`ifdef OSC10
      .REF_CLK("10.0"),    // reference input in MHz
`elsif OSC48
      .REF_CLK("48.0"),    // reference input in MHz
`elsif OSC50
      .REF_CLK("50.0"),    // reference input in MHz
`endif
`ifdef SYSCLK20
      .OUT_CLK("20.0"),   // pll output frequency in MHz
`elsif SYSCLK24
      .OUT_CLK("24.0"),   // pll output frequency in MHz
`elsif SYSCLK25
      .OUT_CLK("25.0"),   // pll output frequency in MHz
`elsif SYSCLK36
      .OUT_CLK("36.0"),   // pll output frequency in MHz
`elsif SYSCLK48
      .OUT_CLK("48.0"),   // pll output frequency in MHz
`elsif SYSCLK50
      .OUT_CLK("50.0"),   // pll output frequency in MHz
`endif
      .PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
      .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
      .CI_FILTER_CONST(2), // optional CI filter constant
      .CP_FILTER_CONST(4)  // optional CP filter constant
   ) pll_inst (
`ifdef OSC10
      .CLK_REF(CLK_10),
`elsif OSC48
      .CLK_REF(CLK_48),
`elsif OSC50
      .CLK_REF(CLK_50),
`endif
		.CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
      .USR_LOCKED_STDY_RST(1'b0),
//		.USR_PLL_LOCKED_STDY(pll_locked),
		.USR_PLL_LOCKED(pll_locked),
      .CLK270(clk270),
		.CLK180(clk180),
		.CLK90(clk90),
		.CLK0(clk),
		.CLK_REF_OUT(usr_ref_out)
   );

`ifdef SYSCLK50
	reg clk25mhz;
	always @(posedge clk) begin
		clk25mhz <= ~clk25mhz;
	end
`endif

`ifdef SYSCLK25
	assign clk25mhz = clk;
`endif

`endif

`ifdef BONBON
	wire clk48mhz;
   SB_HFOSC hfosc_i (
      .CLKHFPU(1'b1),
      .CLKHFEN(1'b1),
      .CLKHF(clk48mhz)
   );
	// 48->20
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0010),
		.DIVF(7'b0100111),
		.DIVQ(3'b101),
		.FILTER_RANGE(3'b001),
	) pll_sysclk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk48mhz),
		.PLLOUTCORE(clk),
		.LOCK(pll_locked),
	);
	wire clk126mhz = CLK_RP;
`endif

`ifdef FPGA_ICE40
`ifdef OSC48
`ifdef KOLIBRI
	// 48->50
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0010),
		.DIVF(7'b0110001),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b001),
	) pll_clk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(CLK_48),
		.PLLOUTCORE(clk50mhz),
		.LOCK(pll_locked),
	);
`else
	// 48->50
	SB_PLL40_PAD #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0010),
		.DIVF(7'b0110001),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b001),
	) pll_clk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.PACKAGEPIN(CLK_48),
		.PLLOUTCORE(clk50mhz),
		.LOCK(pll_locked),
	);
	// 50->125
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0000),
		.DIVF(7'b0010011),
		.DIVQ(3'b011),
		.FILTER_RANGE(3'b100),
	) pll_bclk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk50mhz),
		.PLLOUTCORE(clk125mhz),
	);
`endif
`ifdef SYSCLK25
	assign clk = clk25mhz;
`elsif SYSCLK50
	assign clk = clk50mhz;
`endif
`endif

`ifdef OSC100
   // 100->50
	SB_PLL40_PAD #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0000),
		.DIVF(7'b0000111),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b101),
	) pll_clk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.LOCK(pll_locked),
		.PACKAGEPIN(CLK_100),
		.PLLOUTCORE(clk50mhz),
	);
	// 50->125
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0000),
		.DIVF(7'b0010011),
		.DIVQ(3'b011),
		.FILTER_RANGE(3'b100),
	) pll_bclk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk50mhz),
		.PLLOUTCORE(clk125mhz),
	);
`ifdef SYSCLK25
	assign clk = clk25mhz;
`elsif SYSCLK50
	assign clk = clk50mhz;
`endif
`endif
`endif

`ifdef FPGA_ECP5
	pll0 #() ecp5_pll0 (
		.clkin(CLK_48),
		.clkout0(clk100mhz),
		.clkout2(clk75mhz),
		.clkout3(clk50mhz),
	);
	pll1 #() ecp5_pll1 (
		.clkin(clk100mhz),
		.clkout0(clk125mhz),
		.clkout1(clk25mhz),
		.locked(pll_locked),
	);
`ifdef SYSCLK25
	assign clk = clk25mhz;
`elsif SYSCLK50
	assign clk = clk50mhz;
`elsif SYSCLK75
	assign clk = clk75mhz;
`endif
`endif

	// RESET GENERATOR
	// ---------------

/*
`ifdef LOWE
	wire resetn;
	CC_USR_RSTN usr_rstn_i (
		.USR_RSTN(resetn)
	);
`else
*/
	reg [11:0] resetn_counter = 0;
	wire resetn = &resetn_counter;

	always @(posedge clk) begin
		if (!pll_locked)
			resetn_counter <= 0;
		else if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end
/*
`endif
*/

	// RTC
	reg [31:0] clock_secs = 0;

`ifdef EN_RTC
	reg [12:0] clock_fms = 0;

	always @(posedge clk10khz) begin

		if (!resetn) begin
			clock_fms = 0;
			clock_secs = 0;
		end else begin
			clock_fms <= clock_fms + 1;
			if (clock_fms == 4999) begin
				clock_fms <= 0;
				clock_secs <= clock_secs + 1;
			end
		end

	end
`endif

`ifdef EN_PS2
	reg [7:0] ps2_wdata;
	wire [7:0] ps2_rdata;
	reg ps2_wstrb;
	reg ps2_rstrb;

	wire ps2_dr;
	wire ps2_busy;
	wire ps2_overflow;

	ps2 #() ps2_i (
		.ps2_rdata(ps2_rdata),
		.ps2_rstrb(ps2_rstrb),
		.ps2_wdata(ps2_wdata),
		.ps2_wstrb(ps2_wstrb),
		.ps2_dr(ps2_dr),
		.ps2_busy(ps2_busy),
		.ps2_overflow(ps2_overflow),
		.ps2_dat(PS2_DAT),
		.ps2_clk(PS2_CLK),
		.clk(clk),
		.resetn(resetn),
	);
`endif

`ifdef EN_MUSLI_KBD
	reg [7:0] ps2_wdata;
	wire [7:0] ps2_rdata;
	reg ps2_wstrb;
	reg ps2_rstrb;

	wire ps2_dr;
	wire ps2_busy = 0;
	wire ps2_overflow = 0;

	spislave #() spikbd_i (
		.clk(clk),
		.resetn(resetn),
		.rdata(ps2_rdata),
		.rstrb(ps2_rstrb),
		.dr(ps2_dr),
		.sclk(MUSLI_SCK),
		.mosi(MUSLI_MOSI),
	);
`endif

`ifdef EN_RPINT
	wire [31:0] rpint_rdata;
	wire [1:0] rpint_reg;

	assign rpint_reg = mem_addr[2];

	rpint #() rpint_i (
		.clk(clk),
		.resetn(resetn),
		.rreg(rpint_reg),
		.rdata(rpint_rdata),
		.ss(RP_HOLD),
		.sclk(RP_INT),
		.mosi(RP_TX),
	);
`endif

	// BLOCK RAM

`ifdef EN_LOWBRAM
	localparam BRAM_WORDS = 1280;	// 32-bit words
`else
	localparam BRAM_WORDS = 1536;
`endif
	reg [31:0] bram [0:BRAM_WORDS-1];   
	wire [11:0] bsram_word = mem_addr[14:2];
	wire [11:0] bram_word = mem_addr[14:2];
`ifdef FPGA_GATEMATE
	initial $readmemh("firmware/firmware.hex", bram);
`else
	initial $readmemh("firmware/firmware_seed.hex", bram);
`endif

   // STAND-ALONE SPI SDCARD
 
`ifdef EN_SDCARD
	reg sd_ss;
	reg sd_sck;
	reg sd_mosi;
	wire sd_miso = SD_MISO;
	assign SD_SS = sd_ss;
	assign SD_SCK = sd_sck;
	assign SD_MOSI = sd_mosi;
`endif

	// CSPI BUS

`ifdef EN_SPI

`ifdef FPGA_ECP5
	wire SPI_SCK;
	USRMCLK usrmclk0 (.USRMCLKI(SPI_SCK), .USRMCLKTS(1'b0));
`endif

	wire spi_is_flash = ((mem_addr & 32'hf000_0000) == 32'h8000_0000);
	wire spi_is_ram = ((mem_addr & 32'hf000_0000) == 32'h4000_0000);
	wire spi_is_rpmem = ((mem_addr & 32'hf000_0000) == 32'he000_0000);
	wire spi_is_sd = ((mem_addr & 32'hffff_f000) == 32'hf000_2000);

	// SDCARD ON CSPI BUS

`ifdef EN_CSPI_SDCARD
	reg sd_ss;
	reg sd_sck;
	reg sd_mosi;
	wire sd_miso = SPI_MISO;
`ifdef EN_CSPI_SDCARD_SCK
	assign SD_SCK = sd_sck;
`endif
	assign SPI_SS_SD = spi_is_sd ? sd_ss : 1'b1;
`else
	assign spi_is_sd = 1'b0;
`endif

	assign SPI_MOSI = spi_is_flash ? cspi_flash_mosi :
		spi_is_ram ? qqspi_mosi :
		spi_is_rpmem ? cspi_rpmem_mosi :
		spi_is_sd ? sd_mosi : 1'bz;

	assign SPI_SCK = spi_is_flash ? cspi_flash_sck :
		spi_is_ram ? qqspi_sck :
		spi_is_rpmem ? cspi_rpmem_sck :
		spi_is_sd ? sd_sck : 1'bz;

	// CSPI FLASH (usually an MMOD)

`ifdef EN_CSPI_FLASH

	reg cspi_flash_ss;
	reg cspi_flash_sck;
	reg cspi_flash_mosi;
	wire cspi_flash_miso = SPI_MISO;

	assign SPI_SS_FLASH = spi_is_flash ? cspi_flash_ss : 1'b1;

	reg [31:0] spi_addr;
   wire [31:0] spi_rdata;
   wire spi_ready;
   reg spi_valid;
   reg [2:0] spi_state;

   spiflashro #() spiflashro_cspi_i
	(
      .clk(clk),
      .resetn(resetn),
      .addr(spi_addr),
      .rdata(spi_rdata),
      .ready(spi_ready),
      .valid(spi_valid),
      .ss(cspi_flash_ss),
      .sck(cspi_flash_sck),
      .mosi(cspi_flash_mosi),
      .miso(cspi_flash_miso)
   );

`elsif
	assign spi_is_flash = 1'b0;
`endif

`ifdef EN_CSPI_RPMEM

	reg cspi_rpmem_ss;
	reg cspi_rpmem_sck;
	reg cspi_rpmem_mosi;
	wire cspi_rpmem_miso = SPI_MISO;

	assign SPI_SS = spi_is_rpmem ? cspi_rpmem_ss : 1'b1;

	reg [31:0] rpmem_addr;
   wire [31:0] rpmem_rdata;
   reg [31:0] rpmem_wdata;
   wire rpmem_ready;
   reg rpmem_valid;
	reg rpmem_write;
   reg [2:0] rpmem_state;

   rpmem #() rpmem_i 
	(
      .clk(clk),
      .resetn(resetn),
      .addr(rpmem_addr),
      .rdata(rpmem_rdata),
      .wdata(rpmem_wdata),
      .ready(rpmem_ready),
      .valid(rpmem_valid),
		.write(rpmem_write),
      .ss(cspi_rpmem_ss),
      .sclk(cspi_rpmem_sck),
      .mosi(cspi_rpmem_mosi),
      .miso(cspi_rpmem_miso),
		.hold(RP_HOLD)
   );

`elsif
	assign spi_is_rpmem = 1'b0;
`endif

`endif // EN_SPI

`ifdef EN_CART

	reg [31:0] cart_addr;
   wire [31:0] cart_rdata;
   wire cart_ready;
   reg cart_valid;
   reg [2:0] cart_state;

   spiflashro #() spiflashro_cart_i
	(
      .clk(clk),
      .resetn(resetn),
      .addr(cart_addr),
      .rdata(cart_rdata),
      .ready(cart_ready),
      .valid(cart_valid),
      .ss(CART_SS),
      .sck(CART_SCK),
      .mosi(CART_MOSI),
      .miso(CART_MISO)
   );

`endif

// TODO: BSRAM16 not fully implemented yet
`ifdef EN_BSRAM16

   reg [1:0] sram_state;
   reg [13:0] sram_addr;
   reg [3:0] sram_wstrb;
   reg [15:0] sram_dout;
   wire [15:0] sram_din;

	bsram #() bsram_i (
		.clk(clk),
		.resetn(resetn),
		.addr(sram_addr),
		.rdata(sram_din),
		.wdata(sram_dout),
		.wstrb(sram_wstrb)
	);

`endif

`ifdef EN_BSRAM32

   reg [1:0] sram_state;
   reg [14:0] sram_addr;
   reg [3:0] sram_wstrb;
   reg [31:0] sram_dout;
   wire [31:0] sram_din;

	bsram #() bsram_i (
		.clk(clk),
		.resetn(resetn),
		.addr(sram_addr),
		.rdata(sram_din),
		.wdata(sram_dout),
		.wstrb(sram_wstrb)
	);

`endif

`ifdef EN_SRAM16

   reg [2:0] sram_state;
   reg [17:0] sram_addr;
   reg sram_wrlb, sram_wrub;
   reg [15:0] sram_dout;
   wire [15:0] sram_din;

`ifdef FPGA_ICE40

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) sram_io [15:0] (
		.PACKAGE_PIN({ SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12,
			SRAM0_D11, SRAM0_D10, SRAM0_D9, SRAM0_D8,
			SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
			SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0 }),
		.OUTPUT_ENABLE(sram_wrlb || sram_wrub),
		.D_OUT_0(sram_dout),
		.D_IN_0(sram_din)
	);

`else

	assign sram_din = { SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12,
			SRAM0_D11, SRAM0_D10, SRAM0_D9, SRAM0_D8,
			SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
			SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0 };

	assign { SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12,
			SRAM0_D11, SRAM0_D10, SRAM0_D9, SRAM0_D8,
			SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
			SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0 } =
				(sram_wrlb || sram_wrub) ? sram_dout : 16'hzzzz;

`endif

	assign { SRAM_A17, SRAM_A16, SRAM_A15, SRAM_A14, SRAM_A13, SRAM_A12,
		SRAM_A11, SRAM_A10, SRAM_A9, SRAM_A8, SRAM_A7, SRAM_A6, SRAM_A5,
		SRAM_A4, SRAM_A3, SRAM_A2, SRAM_A1, SRAM_A0 } = sram_addr;

`ifndef VANILLE
	assign SRAM0_CE = 0;
`endif
	assign SRAM0_WE = !(sram_wrlb || sram_wrub);
	assign SRAM0_OE = (sram_wrlb || sram_wrub);
	assign SRAM0_LB = (sram_wrlb || sram_wrub) ? !sram_wrlb : 0;
	assign SRAM0_UB = (sram_wrlb || sram_wrub) ? !sram_wrub : 0;

`endif

`ifdef EN_SRAM32

   reg [2:0] sram_state;
	reg [3:0] sram_wstrb;
   wire sram0_wrlb, sram0_wrub;
   wire sram1_wrlb, sram1_wrub;
   reg [17:0] sram_addr;
   reg [31:0] sram_dout;
   wire [31:0] sram_din;

	assign { sram1_wrub, sram1_wrlb, sram0_wrub, sram0_wrlb } = sram_wstrb;
	wire sram_write = |sram_wstrb;

`ifdef FPGA_ICE40
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) sram_io [31:0] (
		.PACKAGE_PIN({ SRAM1_D15, SRAM1_D14, SRAM1_D13, SRAM1_D12, SRAM1_D11,
			SRAM1_D10, SRAM1_D9, SRAM1_D8, SRAM1_D7, SRAM1_D6, SRAM1_D5, SRAM1_D4,
			SRAM1_D3, SRAM1_D2, SRAM1_D1, SRAM1_D0,
			SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12, SRAM0_D11,
			SRAM0_D10, SRAM0_D9, SRAM0_D8, SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
			SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0 }),
		.OUTPUT_ENABLE(sram_write),
		.D_OUT_0(sram_dout),
		.D_IN_0(sram_din)
	);
`else

	assign sram_din = {
		SRAM1_D15, SRAM1_D14, SRAM1_D13, SRAM1_D12,
		SRAM1_D11, SRAM1_D10, SRAM1_D9, SRAM1_D8,
		SRAM1_D7, SRAM1_D6, SRAM1_D5, SRAM1_D4,
		SRAM1_D3, SRAM1_D2, SRAM1_D1, SRAM1_D0,
		SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12,
		SRAM0_D11, SRAM0_D10, SRAM0_D9, SRAM0_D8,
		SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
		SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0
	};

	assign {
		SRAM1_D15, SRAM1_D14, SRAM1_D13, SRAM1_D12,
		SRAM1_D11, SRAM1_D10, SRAM1_D9, SRAM1_D8,
		SRAM1_D7, SRAM1_D6, SRAM1_D5, SRAM1_D4,
		SRAM1_D3, SRAM1_D2, SRAM1_D1, SRAM1_D0,
		SRAM0_D15, SRAM0_D14, SRAM0_D13, SRAM0_D12,
		SRAM0_D11, SRAM0_D10, SRAM0_D9, SRAM0_D8,
		SRAM0_D7, SRAM0_D6, SRAM0_D5, SRAM0_D4,
		SRAM0_D3, SRAM0_D2, SRAM0_D1, SRAM0_D0
	} = sram_write ? sram_dout : 32'hzzzzzzzz;

`endif

	assign { SRAM_A17, SRAM_A16, SRAM_A15, SRAM_A14, SRAM_A13, SRAM_A12,
		SRAM_A11, SRAM_A10, SRAM_A9, SRAM_A8, SRAM_A7, SRAM_A6, SRAM_A5,
		SRAM_A4, SRAM_A3, SRAM_A2, SRAM_A1, SRAM_A0 } = sram_addr;

`ifdef EN_SRAM_FAST

	assign SRAM0_CE = 0;
	assign SRAM0_WE = !((sram0_wrlb || sram0_wrub) && !clk);
	assign SRAM0_OE = sram_write;
	assign SRAM0_LB = (sram0_wrlb || sram0_wrub) ? !sram0_wrlb : 0;
	assign SRAM0_UB = (sram0_wrlb || sram0_wrub) ? !sram0_wrub : 0;

	assign SRAM1_CE = 0;
	assign SRAM1_WE = !((sram1_wrlb || sram1_wrub) && !clk);
	assign SRAM1_OE = sram_write;
	assign SRAM1_LB = (sram1_wrlb || sram1_wrub) ? !sram1_wrlb : 0;
	assign SRAM1_UB = (sram1_wrlb || sram1_wrub) ? !sram1_wrub : 0;

`else

	assign SRAM0_CE = 0;
	assign SRAM0_WE = !(sram0_wrlb || sram0_wrub);
	assign SRAM0_OE = sram_write;
	assign SRAM0_LB = (sram0_wrlb || sram0_wrub) ? !sram0_wrlb : 0;
	assign SRAM0_UB = (sram0_wrlb || sram0_wrub) ? !sram0_wrub : 0;

	assign SRAM1_CE = 0;
	assign SRAM1_WE = !(sram1_wrlb || sram1_wrub);
	assign SRAM1_OE = sram_write;
	assign SRAM1_LB = (sram1_wrlb || sram1_wrub) ? !sram1_wrlb : 0;
	assign SRAM1_UB = (sram1_wrlb || sram1_wrub) ? !sram1_wrub : 0;
`endif

`endif

`ifdef EN_SPRAM

   reg [2:0] spram_state;
	wire addr_is_spram = ((mem_addr & 32'hf000_0000) == 32'h2000_0000);

	reg [31:0] spram_rdata;

	spram #() spram_i
	(
		.clk(clk),
		.wen((mem_valid && !mem_ready && addr_is_spram) ? mem_wstrb : 4'b0),
		.addr(mem_addr[23:2]),
		.wdata(mem_wdata),
		.rdata(spram_rdata),
	);

`endif

`ifdef EN_HRAM

	reg [31:0] hram_addr;
	reg [31:0] hram_wdata;
	reg [3:0] hram_wstrb;
	wire [31:0] hram_rdata;
	wire hram_ready;
	reg hram_valid;
	reg [2:0] hram_state;
	reg [3:0] hram_int_state;

	hram #() hram_i
	(
		.addr(hram_addr),
		.wdata(hram_wdata),
		.rdata(hram_rdata),
		.ready(hram_ready),
		.valid(hram_valid),
		.wstrb(hram_wstrb),
		.clk(clk),
		.state(hram_int_state),
		.resetn(resetn),
		.adq({HRAM_DQ15, HRAM_DQ14, HRAM_DQ13, HRAM_DQ12,
			HRAM_DQ11, HRAM_DQ10, HRAM_DQ9, HRAM_DQ8,
			HRAM_ADQ7, HRAM_ADQ6, HRAM_ADQ5, HRAM_ADQ4,
			HRAM_ADQ3, HRAM_ADQ2, HRAM_ADQ1, HRAM_ADQ0}),
		.dqs({HRAM_DQS1, HRAM_DQS0}),
		.ck(HRAM_CK),
		.ce(HRAM_CE)
	);

`endif

`ifdef EN_QQSPI

	reg [31:0] qqspi_addr;
	reg [31:0] qqspi_wdata;
	reg qqspi_wstrb;
	wire [31:0] qqspi_rdata;
	wire qqspi_ready;
	reg qqspi_valid;
	reg [2:0] qqspi_state;

`ifdef BONBON

	wire qqspi_ss;
	wire qqspi_mosi;
	wire qqspi_sck;
	wire [1:0] qqspi_cs;

	assign SPI_SS_RAM0 = ~(!qqspi_cs[0] && !qqspi_cs[1] && !qqspi_ss && spi_is_ram);
	assign SPI_SS_RAM1 = ~(!qqspi_cs[0] && qqspi_cs[1] && !qqspi_ss && spi_is_ram);
	assign SPI_SS_RAM2 = ~(qqspi_cs[0] && !qqspi_cs[1] && !qqspi_ss && spi_is_ram);
	assign SPI_SS_RAM3 = ~(qqspi_cs[0] && qqspi_cs[1] && !qqspi_ss && spi_is_ram);

	qqspi #() qqspi_i
	(
		.clk(clk),
		.resetn(resetn),
		.addr(qqspi_addr),
		.wdata(qqspi_wdata),
		.rdata(qqspi_rdata),
		.ready(qqspi_ready),
		.valid(qqspi_valid),
		.write(qqspi_wstrb),
		.ss(qqspi_ss),
		.sck(qqspi_sck),
		.mosi(qqspi_mosi),
		.miso(SPI_MISO),
		.sio2(SPI_IO2),
		.sio3(SPI_IO3),
		.cs(qqspi_cs)
	);

`elsif BROT

	wire qqspi_ss;
	wire qqspi_mosi;
	wire qqspi_sck;
	wire [1:0] qqspi_cs;

	assign SPI_SS_RAM = qqspi_ss;

	qqspi #() qqspi_i
	(
		.clk(clk),
		.resetn(resetn),
		.addr(qqspi_addr),
		.wdata(qqspi_wdata),
		.rdata(qqspi_rdata),
		.ready(qqspi_ready),
		.valid(qqspi_valid),
		.write(qqspi_wstrb),
		.ss(qqspi_ss),
		.sck(qqspi_sck),
		.mosi(qqspi_mosi),
		.miso(SPI_MISO),
		.sio2(SPI_IO2),
		.sio3(SPI_IO3),
		.cs(qqspi_cs)
	);

`else

	qqspi #() qqspi_i
	(
		.clk(clk),
		.resetn(resetn),
		.addr(qqspi_addr),
		.wdata(qqspi_wdata),
		.rdata(qqspi_rdata),
		.ready(qqspi_ready),
		.valid(qqspi_valid),
		.write(qqspi_wstrb),
		.ss(QQSPI_SS),
		.sck(QQSPI_SCK),
		.mosi(QQSPI_MOSI),
		.miso(QQSPI_MISO),
		.sio2(QQSPI_SIO2),
		.sio3(QQSPI_SIO3),
		.cs({QQSPI_CS1, QQSPI_CS0})
	);

`endif
`endif

`ifdef EN_SDRAM

   reg [2:0] sdram_state;

`ifdef EN_SDRAM_64MB
	reg [25:0] sdram_addr;
`else
	reg [24:0] sdram_addr;
`endif
	reg [31:0] sdram_din;
	wire [31:0] sdram_dout;
	reg [3:0] sdram_wmask;
	wire sdram_ready;
	reg sdram_valid;

	sdram #(
		.SDRAM_CLK_FREQ(SYSCLK / 1_000_000)
	) sdram_i (
		.clk(clk),
		.resetn(resetn),
		.addr(sdram_addr),
		.din(sdram_din),
		.dout(sdram_dout),
		.wmask(sdram_wmask),
		.ready(sdram_ready),
		.sdram_clk(sdram_clock),
		.sdram_cke(sdram_cke),
		.sdram_csn(sdram_cs_n),
		.sdram_rasn(sdram_ras_n),
		.sdram_casn(sdram_cas_n),
		.sdram_wen(sdram_we_n),
		.sdram_addr(sdram_a),
		.sdram_ba(sdram_ba),
		.sdram_dq(sdram_dq),
		.sdram_dqm(sdram_dm),
		.valid(sdram_valid)
	);

`endif


// --

	wire gpu_lock;

`ifdef EN_GPU
	wire gpu_refill;
	wire [9:0] gpu_x;
	wire [8:0] gpu_hx;
	wire [9:0] gpu_y;
	wire [8:0] gpu_hy;
	reg [7:0] gpu_refill_words;
	wire gpu_pixel;
`endif

`ifdef EN_GPU_FB
`ifdef EN_GPU_BLIT
	reg gpu_blit_en;
	reg gpu_blit_done;
`ifdef EN_GPU_BLIT16
	reg [15:0] gpu_blit_data;
`elsif EN_GPU_BLIT32
	reg [31:0] gpu_blit_data;
`endif
	reg [7:0] gpu_blit_width;
	reg [7:0] gpu_blit_rows;
	reg [7:0] gpu_blit_stride;
	reg [7:0] gpu_blit_ctr;
	reg [31:0] gpu_blit_src;
	reg [31:0] gpu_blit_dst;
	reg [3:0] gpu_blit_state;
`endif

`ifdef EN_GPU_FB_PIXEL_DOUBLING
	reg [319:0] gpu_hline_r;
	reg [319:0] gpu_hline_g;
	reg [319:0] gpu_hline_b;
`else
	reg [639:0] gpu_hline_r;
	reg [639:0] gpu_hline_g;
	reg [639:0] gpu_hline_b;
`endif

	assign gpu_lock = (gpu_refill_words && sram_state == 0);

`else
	assign gpu_lock = 0;
`endif

`ifdef EN_VIDEO
	gpu_video #() gpu_video_i
	(
		.clk(clk),
		.vclk(clk25mhz),
		.resetn(resetn),
		.pixel(gpu_pixel),
`ifdef EN_GPU_FB
		.hline_r(gpu_hline_r),
		.hline_g(gpu_hline_g),
		.hline_b(gpu_hline_b),
`endif
		.x(gpu_x),
		.y(gpu_y),
		.hx(gpu_hx),
		.hy(gpu_hy),
		.refill(gpu_refill),
`ifdef EN_VIDEO_VGA
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B),
		.hsync(VGA_HS),
		.vsync(VGA_VS),
`endif
`ifdef EN_VIDEO_DDMI
`ifdef VCLK25
		.bclk(clk125mhz),
`else
		.bclk(clk126mhz),
`endif
		.dvi_p({ DDMI_CK_P, DDMI_D2_P, DDMI_D1_P, DDMI_D0_P }),
`ifndef FPGA_ECP5
		.dvi_n({ DDMI_CK_N, DDMI_D2_N, DDMI_D1_N, DDMI_D0_N }),
`endif
`endif
`ifdef EN_VIDEO_COMPOSITE
		.dac({ COMP_D3, COMP_D2, COMP_D1, COMP_D0 })
`endif
	);
`else
	wire gpu_lock = 0;
`endif

`ifdef EN_GPU_TEXT
	reg [8:0] vram_addr;
	wire [31:0] vram_rdata;
	reg [31:0] vram_wdata;
	reg [3:0] vram_wstrb;
	reg [2:0] vram_state;
	
	gpu_text #() gpu_text_i (
		.clk(clk),
		.resetn(resetn),
		.x(gpu_x),
		.y(gpu_y),
		.pixel(gpu_pixel),
		.addr(vram_addr),
		.wdata(vram_wdata),
		.rdata(vram_rdata),
		.wstrb(vram_wstrb)
	);
`else
	wire gpu_pixel = 0;
`endif

`ifdef EN_AUDIO

	reg [7:0] noise;

	always @(posedge clk10khz) begin
		noise <= noise + 1'b1;
	end

	audio #() audio_i ( 
		.clk_pwm(clk10khz),
		.data_left(8'h00),
		.data_right(noise),
		.out_left(AUDIO_L),
		.out_right(AUDIO_R),
	);

`endif

// --

	reg [7:0] dly_ctr;

	always @(posedge clk) begin

		mem_ready <= 0;

`ifdef EN_BSRAM16
		sram_wstrb <= 0;
`endif
`ifdef EN_BSRAM32
		sram_wstrb <= 0;
`endif
`ifdef EN_SRAM16
		sram_wrlb <= 0;
		sram_wrub <= 0;
`endif
`ifdef EN_SRAM32
		sram_wstrb <= 4'b0000;
`endif

`ifdef EN_PS2
		ps2_rstrb <= 0;
		ps2_wstrb <= 0;
`endif

`ifdef EN_MUSLI_KBD
		ps2_rstrb <= 0;
`endif

		uart0_transmit <= 0;

`ifdef EN_GPU_FB

		if (gpu_refill) begin
`ifdef EN_SRAM16
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			gpu_refill_words <= 80;
`else
			gpu_refill_words <= 160;
`endif
`endif
`ifdef EN_SRAM32
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			gpu_refill_words <= 40;
`else
			gpu_refill_words <= 80;
`endif
`endif
`ifdef EN_BSRAM16
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			gpu_refill_words <= 80;
`else
			gpu_refill_words <= 160;
`endif
`endif
`ifdef EN_BSRAM32
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			gpu_refill_words <= 40;
`else
			gpu_refill_words <= 80;
`endif
`endif
		end

		if (gpu_lock) begin

`ifdef EN_SRAM16
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			sram_addr <= (gpu_hy << 6) + (gpu_hy << 4) + gpu_refill_words;
`else
			sram_addr <= (gpu_y << 7) + (gpu_y << 5) + gpu_refill_words;
`endif
			gpu_hline_r <= { gpu_hline_r,
				sram_din[10], sram_din[14], sram_din[2], sram_din[6] };

			gpu_hline_g <= { gpu_hline_g,
				sram_din[9], sram_din[13], sram_din[1], sram_din[5] };

			gpu_hline_b <= { gpu_hline_b,
				sram_din[8], sram_din[12], sram_din[0], sram_din[4] };

			gpu_refill_words <= gpu_refill_words - 1;
`endif

`ifdef EN_SRAM32
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			sram_addr <= (gpu_hy << 5) + (gpu_hy << 3) + gpu_refill_words;
`else
			sram_addr <= (gpu_y << 6) + (gpu_y << 4) + gpu_refill_words;
`endif
			gpu_hline_r <= { gpu_hline_r,
				sram_din[26], sram_din[30], sram_din[18], sram_din[22],
				sram_din[10], sram_din[14], sram_din[2], sram_din[6] };

			gpu_hline_g <= { gpu_hline_g,
				sram_din[25], sram_din[29], sram_din[17], sram_din[21],
				sram_din[9], sram_din[13], sram_din[1], sram_din[5] };

			gpu_hline_b <= { gpu_hline_b,
				sram_din[24], sram_din[28], sram_din[16], sram_din[20],
				sram_din[8], sram_din[12], sram_din[0], sram_din[4] };

			gpu_refill_words <= gpu_refill_words - 1;
`endif

`ifdef EN_BSRAM16
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			sram_addr <= (gpu_hy << 6) + (gpu_hy << 4) + gpu_refill_words;
`else
			sram_addr <= (gpu_y << 7) + (gpu_y << 5) + gpu_refill_words;
`endif
			gpu_hline_r <= { gpu_hline_r,
				sram_din[10], sram_din[14], sram_din[2], sram_din[6] };

			gpu_hline_g <= { gpu_hline_g,
				sram_din[9], sram_din[13], sram_din[1], sram_din[5] };

			gpu_hline_b <= { gpu_hline_b,
				sram_din[8], sram_din[12], sram_din[0], sram_din[4] };

			gpu_refill_words <= gpu_refill_words - 1;
`endif

`ifdef EN_BSRAM32
`ifdef EN_GPU_FB_PIXEL_DOUBLING
			sram_addr <= (gpu_hy << 5) + (gpu_hy << 3) + gpu_refill_words;
`else
			sram_addr <= (gpu_y << 6) + (gpu_y << 4) + gpu_refill_words;
`endif
			gpu_hline_r <= { gpu_hline_r,
				sram_din[26], sram_din[30], sram_din[18], sram_din[22],
				sram_din[10], sram_din[14], sram_din[2], sram_din[6] };

			gpu_hline_g <= { gpu_hline_g,
				sram_din[25], sram_din[29], sram_din[17], sram_din[21],
				sram_din[9], sram_din[13], sram_din[1], sram_din[5] };

			gpu_hline_b <= { gpu_hline_b,
				sram_din[24], sram_din[28], sram_din[16], sram_din[20],
				sram_din[8], sram_din[12], sram_din[0], sram_din[4] };

			gpu_refill_words <= gpu_refill_words - 1;
`endif

`ifdef EN_GPU_BLIT

		end else if (gpu_blit_en) begin

			if (gpu_blit_state == 0) begin

				sram_addr <= gpu_blit_src;
`ifdef EN_GPU_BLIT16
				sram_wrlb <= 1'b0;
				sram_wrub <= 1'b0;
`elsif EN_GPU_BLIT32
				sram_wstrb <= 4'b0000;
`endif
				gpu_blit_state <= 1;
				gpu_blit_done <= 0;

			end else if (gpu_blit_state == 1) begin

				gpu_blit_data <= sram_din;
				gpu_blit_state <= 2;

			end else if (gpu_blit_state == 2) begin
	
				sram_addr <= gpu_blit_dst;
				sram_dout <= gpu_blit_data;
`ifdef EN_GPU_BLIT16
				sram_wrlb <= 1'b1;
				sram_wrub <= 1'b1;
`elsif EN_GPU_BLIT32
				sram_wstrb <= 4'b1111;
`endif

				gpu_blit_ctr <= gpu_blit_ctr + 2;	// 2 bytes per pixel

				if (gpu_blit_ctr == gpu_blit_width) begin

					gpu_blit_src <= gpu_blit_src +
						gpu_blit_stride - (gpu_blit_width >> 1);
					gpu_blit_dst <= gpu_blit_dst +
						gpu_blit_stride - (gpu_blit_width >> 1);

					gpu_blit_ctr <= 0;
					gpu_blit_rows <= gpu_blit_rows - 1;

					if (gpu_blit_rows == 1) begin
						gpu_blit_done <= 1;
						gpu_blit_ctr <= 0;
						gpu_blit_en <= 0;
					end

				end else begin
					gpu_blit_src <= gpu_blit_src + 1;	// words
					gpu_blit_dst <= gpu_blit_dst + 1;	// words
				end

				gpu_blit_state <= 0;

			end

`endif

		end

`endif

		if (uart0_received) begin
			uart0_dr <= 1;
`ifdef UART0_HW_FLOW
			UART0_CTS <= 1;
`endif
		end

`ifdef UART0_HW_FLOW
		if (!uart0_transmit && !uart0_is_transmitting && !UART0_RTS) begin
			uart0_txbusy <= 0;
		end
`else
		if (!uart0_transmit && !uart0_is_transmitting) begin
			uart0_txbusy <= 0;
		end
`endif

		if (!resetn) begin

			dly_ctr <= 0;

			uart0_dr <= 0;
			uart0_txbusy <= 0;
`ifdef UART0_HW_FLOW
			UART0_CTS <= 0;
`endif

`ifdef EN_GPU
			gpu_refill_words <= 0;
`endif
`ifdef EN_CSPI_FLASH
			spi_valid <= 0;
			spi_state <= 0;
`endif
`ifdef EN_CSPI_RPMEM
			rpmem_valid <= 0;
			rpmem_state <= 0;
`endif
`ifdef EN_CART
			cart_valid <= 0;
			cart_state <= 0;
`endif
`ifdef EN_SDCARD
			sd_ss <= 1;
			sd_sck <= 0;
			sd_mosi <= 0;
`endif
`ifdef EN_SRAM16
			sram_state <= 0;
`endif
`ifdef EN_SRAM32
			sram_state <= 0;
`endif
`ifdef EN_BSRAM16
			sram_state <= 0;
`endif
`ifdef EN_BSRAM32
			sram_state <= 0;
`endif
`ifdef EN_SDRAM
			sdram_state <= 0;
			sdram_valid <= 0;
`endif
`ifdef EN_SPRAM
			spram_state <= 0;
`endif
`ifdef EN_HRAM
			hram_valid <= 0;
			hram_state <= 0;
`endif
`ifdef EN_QQSPI
			qqspi_valid <= 0;
			qqspi_state <= 0;
`endif
`ifdef EN_GPU_TEXT
			vram_state <= 0;
`endif

`ifdef EN_GPU_BLIT
		gpu_blit_en <= 0;
		gpu_blit_state <= 0;
		gpu_blit_ctr <= 0;
`endif

		end else if (mem_valid && !mem_ready) begin

			(* parallel_case *)
			case (1)

				// BLOCK RAM
				(mem_addr < 8192): begin
			
					if (mem_wstrb[0]) bram[bram_word][7:0] <= mem_wdata[7:0];
					if (mem_wstrb[1]) bram[bram_word][15:8] <= mem_wdata[15:8];
					if (mem_wstrb[2]) bram[bram_word][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) bram[bram_word][31:24] <= mem_wdata[31:24];

					mem_rdata <= bram[bram_word];
					mem_ready <= 1;

				end

`ifdef EN_BSRAM32
				// BLOCK RAM AS 32-bit SRAM
				(((mem_addr & 32'hf000_0000) == 32'h2000_0000) && !gpu_lock): begin

					if (mem_wstrb) begin

						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_dout <= mem_wdata;
							sram_wstrb <= mem_wstrb;
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_ready <= 1;
							sram_state <= 0;
						end

					end else begin

						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_rdata <= sram_din;
							mem_ready <= 1;
							sram_state <= 0;
						end

					end

				end
`endif

`ifdef EN_GPU_TEXT
				((mem_addr & 32'hf000_0000) == 32'h1000_0000): begin

					if (vram_state == 0) begin
						vram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
						vram_wdata <= mem_wdata;
						vram_wstrb <= mem_wstrb;
						vram_state <= 1;
					end else if (vram_state == 1) begin
						vram_state <= 2;
					end else if (vram_state == 2) begin
						mem_rdata <= vram_rdata;
						vram_wstrb <= 0;
						vram_state <= 0;
						mem_ready <= 1;
					end

				end
`else
				((mem_addr & 32'hf000_0000) == 32'h1000_0000): begin
					mem_ready <= 1;
				end
`endif

`ifdef EN_SRAM16
				(((mem_addr & 32'hf000_0000) == 32'h2000_0000) && !gpu_lock): begin

					if (mem_wstrb) begin
						(* parallel_case, full_case *)
						case (sram_state)
							0: begin
								sram_addr <= {(mem_addr & 32'h0fff_ffff) >> 2, 1'b0};
								sram_dout <= mem_wdata[15:0];
								sram_wrlb <= mem_wstrb[0];
								sram_wrub <= mem_wstrb[1];
								sram_state <= 1;
							end
							1: begin
								sram_addr <= {(mem_addr & 32'h0fff_ffff) >> 2, 1'b1};
								sram_dout <= mem_wdata[31:16];
								sram_wrlb <= mem_wstrb[2];
								sram_wrub <= mem_wstrb[3];
								sram_state <= 0;
								mem_ready <= 1;
							end
						endcase
					end else begin
						(* parallel_case, full_case *)
						case (sram_state)
							0: begin
								sram_addr <= {(mem_addr & 32'h0fff_ffff) >> 2, 1'b0};
								sram_state <= 1;
							end
							1: begin
								mem_rdata[15:0] <= sram_din;
								sram_addr <= {(mem_addr & 32'h0fff_ffff) >> 2, 1'b1};
								sram_state <= 2;
							end
							2: begin
								mem_rdata[31:16] <= sram_din;
								sram_state <= 0;
								mem_ready <= 1;
							end
						endcase
					end

				end
`endif

`ifdef EN_SRAM32
				(((mem_addr & 32'hf000_0000) == 32'h2000_0000) && !gpu_lock): begin

					if (mem_wstrb) begin

`ifdef EN_SRAM_FAST
						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_dout <= mem_wdata;
							sram_wstrb <= mem_wstrb;
							mem_ready <= 1;
						end
`else
						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_dout <= mem_wdata;
							sram_wstrb <= mem_wstrb;
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_ready <= 1;
							sram_state <= 0;
						end
`endif

					end else begin

						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_rdata <= sram_din;
							mem_ready <= 1;
							sram_state <= 0;
						end

					end

				end
`endif

`ifdef EN_SPRAM
				(((mem_addr & 32'hf000_0000) == 32'h2000_0000) && !gpu_lock): begin
					case (spram_state)
						0: begin
							spram_state <= 1;
						end
						1: begin
							spram_state <= 0;
							mem_ready <= 1;
							mem_rdata <= spram_rdata;
						end
					endcase
				end
`endif

`ifdef EN_HRAM
				((mem_addr & 32'hf000_0000) == 32'h4000_0000): begin

					if (mem_wstrb) begin

						if (hram_state == 0 && !hram_ready) begin
 
							hram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							hram_wdata <= mem_wdata;
							hram_wstrb <= mem_wstrb;
							hram_valid <= 1;
							hram_state <= 1;

						end else if (hram_state == 1 && hram_ready) begin

							hram_valid <= 0;
							hram_state <= 2;

						end else if (hram_state == 2 && !hram_ready) begin

							hram_state <= 0;
							mem_ready <= 1;

						end

					end else begin

						if (hram_state == 0 && !hram_ready) begin
							hram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							hram_wstrb <= 4'b0000;
							hram_valid <= 1;
							hram_state <= 1;
						end else if (hram_state == 1 && hram_ready) begin
							mem_rdata <= hram_rdata;
							hram_valid <= 0;
							hram_state <= 2;
						end else if (hram_state == 2 && !hram_ready) begin
							hram_state <= 0;
							mem_ready <= 1;
						end

					end

				end
`endif

`ifdef EN_QQSPI
				((mem_addr & 32'hf000_0000) == 32'h4000_0000): begin

					if (mem_wstrb) begin

						if (qqspi_state == 0 && !qqspi_ready) begin
							qqspi_addr <= mem_addr & 32'h0fff_ffff;
							qqspi_wstrb <= 0;
							qqspi_valid <= 1;
							qqspi_state <= 1;
						end else if (qqspi_state == 1 && qqspi_ready) begin
							qqspi_wdata <= qqspi_rdata;
							qqspi_valid <= 0;
							qqspi_state <= 2;
						end else if (qqspi_state == 2 && !qqspi_ready) begin
							if (mem_wstrb[0]) qqspi_wdata[7:0] <= mem_wdata[7:0];
							if (mem_wstrb[1]) qqspi_wdata[15:8] <= mem_wdata[15:8];
							if (mem_wstrb[2]) qqspi_wdata[23:16] <= mem_wdata[23:16];
							if (mem_wstrb[3]) qqspi_wdata[31:24] <= mem_wdata[31:24];
							qqspi_wstrb <= 1;
							qqspi_valid <= 1;
							qqspi_state <= 3;
						end else if (qqspi_state == 3 && qqspi_ready) begin
							qqspi_valid <= 0;
							qqspi_state <= 4;
						end else if (qqspi_state == 4 && !qqspi_ready) begin
							qqspi_state <= 0;
							mem_ready <= 1;
						end

					end else begin

						if (qqspi_state == 0 && !qqspi_ready) begin
							qqspi_addr <= mem_addr & 32'h0fff_ffff;
							qqspi_wstrb <= 0;
							qqspi_valid <= 1;
							qqspi_state <= 1;
						end else if (qqspi_state == 1 && qqspi_ready) begin
							mem_rdata <= qqspi_rdata;
							qqspi_valid <= 0;
							qqspi_state <= 2;
						end else if (qqspi_state == 2 && !qqspi_ready) begin
							qqspi_state <= 0;
							mem_ready <= 1;
						end

					end

				end
`endif

`ifdef EN_SDRAM
				((mem_addr & 32'hf000_0000) == 32'h4000_0000): begin

					if (mem_wstrb) begin

						if (sdram_state == 0 && !sdram_ready) begin
							sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							sdram_din <= mem_wdata;
							sdram_wmask <= mem_wstrb;
							sdram_state <= 1;
							sdram_valid <= 1;
						end else if (sdram_state == 1 && sdram_ready) begin
							sdram_wmask <= 0;
							sdram_valid <= 0;
							sdram_state <= 2;
						end else if (sdram_state == 2 && !sdram_ready) begin
							mem_ready <= 1;
							sdram_state <= 0;
						end

					end else begin

						if (sdram_state == 0 && !sdram_ready) begin
							sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							sdram_valid <= 1;
							sdram_state <= 1;
						end else if (sdram_state == 1 && sdram_ready) begin
							mem_rdata <= sdram_dout;
							sdram_valid <= 0;
							sdram_state <= 2;
						end else if (sdram_state == 2 && !sdram_ready) begin
							mem_ready <= 1;
							sdram_state <= 0;
						end

					end

				end
`endif

`ifdef EN_CSPI_RPMEM
				((mem_addr & 32'hf000_0000) == 32'he000_0000): begin

					if (mem_wstrb) begin

						if (rpmem_state == 0 && !rpmem_ready) begin
							rpmem_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							rpmem_wdata <= mem_wdata;
							rpmem_write <= 1;
							rpmem_valid <= 1;
							rpmem_state <= 1;
						end else if (rpmem_state == 1 && rpmem_ready) begin
							rpmem_valid <= 0;
							rpmem_state <= 2;
						end else if (rpmem_state == 2 && !rpmem_ready) begin
							rpmem_state <= 0;
							mem_ready <= 1;
						end

					end else begin

						if (rpmem_state == 0 && !rpmem_ready) begin
							rpmem_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							rpmem_write <= 0;
							rpmem_valid <= 1;
							rpmem_state <= 1;
						end else if (rpmem_state == 1 && rpmem_ready) begin
							mem_rdata <= rpmem_rdata;
							rpmem_valid <= 0;
							rpmem_state <= 2;
						end else if (rpmem_state == 2 && !rpmem_ready) begin
							rpmem_state <= 0;
							mem_ready <= 1;
						end

					end

				end
`endif

`ifdef EN_CSPI_FLASH
				((mem_addr & 32'hf000_0000) == 32'h8000_0000): begin

					if (!mem_wstrb) begin

						if (spi_state == 0 && !spi_ready) begin
							spi_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							spi_valid <= 1;
							spi_state <= 1;
						end else if (spi_state == 1 && spi_ready) begin
							mem_rdata <= spi_rdata;
							spi_valid <= 0;
							spi_state <= 2;
						end else if (spi_state == 2 && !spi_ready) begin
							spi_state <= 0;
							mem_ready <= 1;
						end

					end else begin
						mem_ready <= 1;
					end

				end
`endif

`ifdef EN_CART
				((mem_addr & 32'hf000_0000) == 32'ha000_0000): begin

					if (!mem_wstrb) begin

						if (cart_state == 0 && !cart_ready) begin
							cart_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
							cart_valid <= 1;
							cart_state <= 1;
						end else if (cart_state == 1 && cart_ready) begin
							mem_rdata <= cart_rdata;
							cart_valid <= 0;
							cart_state <= 2;
						end else if (cart_state == 2 && !cart_ready) begin
							cart_state <= 0;
							mem_ready <= 1;
						end

					end else begin
						mem_ready <= 1;
					end

				end
`endif

				((mem_addr & 32'hf000_0000) == 32'hf000_0000): begin

					(* parallel_case *)
					case (mem_addr[15:0])

						16'h0000: begin
							if (mem_wstrb && !uart0_txbusy) begin
								uart0_tx_byte <= mem_wdata[7:0];
								uart0_txbusy <= 1;
								uart0_transmit <= 1;
								mem_ready <= 1;
							end else if (!mem_wstrb) begin
								mem_rdata[7:0] <= uart0_rx_byte;
								uart0_dr <= 0;
`ifdef UART0_HW_FLOW
								UART0_CTS <= 0;
`endif
								mem_ready <= 1;
							end
						end

						16'h0004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= { 6'b0, uart0_txbusy, uart0_dr };
							end
							mem_ready <= 1;
						end

						16'h1000: begin
							if (mem_wstrb)
								LED_A <= ~mem_wdata[0];
							else
								mem_rdata[0] <= ~LED_A;
							mem_ready <= 1;
						end

						16'h1100: begin
							if (!mem_wstrb) mem_rdata <= clock_secs;
							mem_ready <= 1;
						end

`ifdef EN_SDCARD

						16'h2000: begin
							if (mem_wstrb)
								{sd_ss, sd_sck, sd_mosi} <= mem_wdata[3:1];
							else
								mem_rdata[7:0] <= {
									4'b0, sd_ss, sd_sck, sd_mosi, sd_miso
								};
							mem_ready <= 1;
						end

`elsif EN_CSPI_SDCARD

						16'h2000: begin
							if (mem_wstrb)
								{sd_ss, sd_sck, sd_mosi} <= mem_wdata[3:1];
							else
								mem_rdata[7:0] <= {
									4'b0, sd_ss, sd_sck, sd_mosi, sd_miso
								};
							mem_ready <= 1;
						end

`endif

`ifdef EN_PS2
						16'h3000: begin
							if (mem_wstrb) begin
								ps2_wdata <= mem_wdata[7:0];
								ps2_wstrb <= 1;
							end else begin
								mem_rdata[7:0] <= ps2_rdata;
								ps2_rstrb <= 1;
							end
							mem_ready <= 1;
						end

						16'h3004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= {
									5'b0, ps2_overflow, ps2_busy, ps2_dr
								};
							end
							mem_ready <= 1;
						end

`elsif EN_MUSLI_KBD

						16'h3000: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= ps2_rdata;
								ps2_rstrb <= 1;
							end
							mem_ready <= 1;
						end

						16'h3004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= {
									5'b0, ps2_overflow, ps2_busy, ps2_dr
								};
							end
							mem_ready <= 1;
						end

`else

						16'h3000: begin
							mem_ready <= 1;
						end

						16'h3004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= 0;
							end
							mem_ready <= 1;
						end

`endif

`ifdef EN_RPINT
						16'h5000: begin
							if (!mem_wstrb) begin
								mem_rdata <= rpint_rdata;
							end
							mem_ready <= 1;
						end
						16'h5004: begin
							if (!mem_wstrb) begin
								mem_rdata <= rpint_rdata;
							end
							mem_ready <= 1;
						end
`endif

						16'h6000: begin
							dly_ctr <= dly_ctr + 1;
							if (dly_ctr == (SYSCLK / 1_000_000)) begin
								dly_ctr <= 0;
								mem_ready <= 1;
							end
						end

`ifdef EN_GPU_BLIT
						16'h8000: begin
							if (!mem_wstrb) begin
								mem_rdata <= gpu_blit_src;
							end else begin
								gpu_blit_src <= mem_wdata;
							end
							mem_ready <= 1;
						end
						16'h8004: begin
							if (!mem_wstrb) begin
								mem_rdata <= gpu_blit_dst;
							end else begin
								gpu_blit_dst <= mem_wdata;
							end
							mem_ready <= 1;
						end
						16'h8008: begin
							if (!mem_wstrb) begin
								mem_rdata = {
									gpu_blit_en,
									7'b0,
									gpu_blit_stride,
									gpu_blit_rows,
									gpu_blit_width
								};
							end else begin
								gpu_blit_width <= mem_wdata[7:0];
								gpu_blit_rows <= mem_wdata[15:8];
								gpu_blit_stride <= mem_wdata[23:16];
								gpu_blit_en <= mem_wdata[31];
							end
							mem_ready <= 1;
						end

`endif

						default: begin
							mem_ready <= 1;
						end

					endcase
				end

			endcase

		end

	end

	// CPU
	// ---

/*
	assign pmodb1 = cpu_trap;
	assign pmodb2 = resetn;
	assign pmodb3 = |mem_wstrb;
	assign pmodb4 = mem_ready;
	assign pmodb7 = mem_addr[7];
	assign pmodb8 = mem_addr[8];
	assign pmodb9 = mem_addr[9];
	assign pmodb10 = mem_addr[10];
*/

`ifdef CCEVAL
	assign led2 = ~cpu_trap;
	assign led3 = ~resetn;
	assign led4 = ~(|mem_wstrb);
	assign led5 = ~mem_ready;
	assign led6 = ~mem_addr[7];
	assign led7 = ~mem_addr[8];
	assign led8 = ~mem_addr[9];
`endif

`ifdef LOWE
	assign pmoda1 = ctr[29];
	assign pmoda2 = ctr[28];
	assign pmoda3 = ctr[27];
	assign pmoda4 = ctr[26];
	assign pmoda7 = ctr[25];
	assign pmoda8 = ctr[24];
	assign pmoda9 = ctr[23];
	assign pmoda10 = ctr[22];

/*
	assign pmoda1 = cpu_trap;
	assign pmoda2 = resetn;
	assign pmoda3 = (|mem_wstrb);
	assign pmoda4 = mem_ready;
	assign pmoda7 = mem_addr[7];
	assign pmoda8 = mem_addr[8];
	assign pmoda9 = mem_addr[9];
	assign pmoda10 = 0;
*/
`endif

	wire cpu_trap;
	wire [31:0] cpu_irq;

	wire mem_valid;
	wire mem_instr;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;

	reg mem_ready;
	reg [31:0] mem_rdata;

	picorv32 #(
		.STACKADDR(BRAM_WORDS * 4),		// end of BRAM
		.PROGADDR_RESET(32'h0000_0000),
		.PROGADDR_IRQ(32'h0000_0010),
		.BARREL_SHIFTER(1),
		.COMPRESSED_ISA(0),
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_IRQ(0)
	) cpu (
		.clk(clk),
		.resetn(resetn),
		.trap(cpu_trap),
		.mem_valid(mem_valid),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),
		.mem_addr(mem_addr),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata),
		.irq(cpu_irq)
	);

	// UART0
	// ----

`ifdef EN_UART0
	reg uart0_transmit;
	reg [7:0] uart0_tx_byte;
	wire uart0_received;
	wire [7:0] uart0_rx_byte;
	wire uart0_is_receiving;
	wire uart0_is_transmitting;
	wire uart0_recv_error;

	reg uart0_dr;
	reg uart0_txbusy;

	wire uart0_rx;

	uart #(
		.baud_rate(UART0_BAUDRATE),
		.sys_clk_freq(SYSCLK)
	)
	uart0 (
		.clk(clk),
		.rst(~resetn),
		.rx(UART0_TX),
		.tx(UART0_RX),
		.transmit(uart0_transmit),
		.tx_byte(uart0_tx_byte),
		.received(uart0_received),
		.rx_byte(uart0_rx_byte),
		.is_receiving(uart0_is_receiving),
		.is_transmitting(uart0_is_transmitting),
		.recv_error(uart0_recv_error)
	);
`endif

endmodule
