/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * System Controller
 *
 */

`define EN_RTC
`define EN_SDCARD
`define EN_PS2
`define EN_CLK10KHZ
`define EN_SPI_FLASH
`define EN_SRAM
`define EN_HRAM
//`define EN_QQSPI
`define EN_GPU
//`define EN_GPU_GFX
`define EN_GPU_TEXT

localparam SYSCLK = 50000000;
localparam UART_BAUDRATE = 115200;

module sysctl #()
(

`ifdef OSC100
	input CLK_100,
`endif
`ifdef OSC48
	input CLK_48,
`endif

	output reg LED_A,

	output reg UART_RTS,
	inout UART_RX,
	inout UART_TX,
	input UART_CTS,

	output SPI_SCK,
	input SPI_MISO,
	output SPI_MOSI,

`ifdef EN_SPI_FLASH
	output SPI_SS_FLASH,
`endif

`ifdef EN_SDCARD
	output SPI_SS_SD,
`endif

`ifdef EN_PS2
	inout PS2_DAT,
	inout PS2_CLK,
`endif

`ifdef EN_GPU
	output VGA_R,
	output VGA_G,
	output VGA_B,
	output VGA_HS,
	output VGA_VS,
`endif

`ifdef EN_SRAM
	output SRAM_A0, SRAM_A1, SRAM_A2, SRAM_A3,
		SRAM_A4, SRAM_A5, SRAM_A6, SRAM_A7,
		SRAM_A8, SRAM_A9, SRAM_A10, SRAM_A11,
		SRAM_A12, SRAM_A13, SRAM_A14, SRAM_A15,
		SRAM_A16, SRAM_A17,

	inout SRAM_D0, SRAM_D1, SRAM_D2, SRAM_D3,
		SRAM_D4, SRAM_D5, SRAM_D6, SRAM_D7,
		SRAM_D8, SRAM_D9, SRAM_D10, SRAM_D11,
		SRAM_D12, SRAM_D13, SRAM_D14, SRAM_D15,

	output SRAM_CE, SRAM_WE, SRAM_OE, SRAM_LB, SRAM_UB,
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
	output QQSPI_SS,
	output QQSPI_SCK,
	inout QQSPI_MISO,
	inout QQSPI_MOSI,
	inout QQSPI_SIO2,
	inout QQSPI_SIO3,
	output QQSPI_CS1,
	output QQSPI_CS0,
`endif

);

	// CLOCKS
	// ------

	wire clk;
	wire clk90;
	wire vclk;

	wire clk64mhz;
	wire clk50mhz;
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

`ifdef OSC48
	// 48MHz -> 64MHz
	sysclk sysclk_i(.clk(CLK_48), .clkout(clk64mhz), .clkout90(clk90),
		.pll_locked(pll_locked));

	// 64MHz -> 50MHz
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0001),
		.DIVF(7'b0011000),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b011),
	) pll_vclk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk64mhz),
		.PLLOUTCORE(clk50mhz),
	);

	assign clk = clk50mhz;

	// 50MHz -> 25MHz
	clkdiv clkdiv_i(
		.clk(clk50mhz),
		.clkout(vclk)
	);
`endif

`ifdef OSC100
   // 100MHz -> 50MHz
	SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
		.PLLOUT_SELECT("GENCLK"),
		.DIVR(4'b0000),
		.DIVF(7'b0000111),
		.DIVQ(3'b100),
		.FILTER_RANGE(3'b101),
	) pll_vclk (
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.LOCK(pll_locked),
		.REFERENCECLK(CLK_100),
		.PLLOUTCORE(clk50mhz),
	);

	wire clk = clk50mhz;

	// 50MHz -> 25MHz
	clkdiv clkdiv_i(
		.clk(clk50mhz),
		.clkout(vclk)
	);
`endif

	// RESET GENERATOR
	// ---------------

	reg [11:0] resetn_counter = 0;
	wire resetn = &resetn_counter;

	always @(posedge clk) begin
		if (!pll_locked)
			resetn_counter <= 0;
		else if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end

	// RTC
	reg [31:0] clock_secs = 0;

`ifdef EN_RTC
	reg [12:0] clock_fms = 0;

	always @(posedge clk10khz) begin

		clock_fms <= clock_fms + 1;

		if (clock_fms == 4999) begin
			clock_fms <= 0;
			clock_secs <= clock_secs + 1;
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

	// BLOCK RAM

	localparam BRAM_WORDS = 1536;	// 32-bit words
	reg [31:0] bram [0:BRAM_WORDS-1];   
	wire [10:0] bram_word = mem_addr[14:2];
	initial $readmemh("firmware/firmware_seed.hex", bram);

	// SPI

	wire spi_is_flash = ((mem_addr & 32'hf000_0000) == 32'h8000_0000);

	wire spi_ss_flash;
	wire spi_ss_sd;

	wire spi_sd_sck;
	wire spi_sd_mosi;
	wire spi_flash_sck;
	wire spi_flash_mosi;

	assign SPI_SS_FLASH = spi_is_flash ? spi_ss_flash : 1;
	assign SPI_SS_SD = spi_is_flash ? 1 : spi_ss_sd;

	assign SPI_SCK = spi_is_flash ? spi_flash_sck : spi_sd_sck;
	assign SPI_MOSI = spi_is_flash ? spi_flash_mosi : spi_sd_mosi;

`ifdef EN_SPI_FLASH

	reg [31:0] spi_addr;
   wire [31:0] spi_rdata;
   wire spi_ready;
   reg spi_valid;
   reg [2:0] spi_state;

   spiflashro #() spiflashro_i
	(
      .addr(spi_addr),
      .rdata(spi_rdata),
      .ready(spi_ready),
      .valid(spi_valid),
      .clk(clk),
      .resetn(resetn),
      .ss(spi_ss_flash),
      .sck(spi_flash_sck),
      .mosi(spi_flash_mosi),
      .miso(SPI_MISO)
   );

`endif

`ifdef EN_SRAM

   reg [2:0] sram_state;
   reg sram_wrlb, sram_wrub;
   reg [17:0] sram_addr;
   reg [15:0] sram_dout;
   wire [15:0] sram_din;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) sram_io [15:0] (
		.PACKAGE_PIN({ SRAM_D15, SRAM_D14, SRAM_D13, SRAM_D12, SRAM_D11,
			SRAM_D10, SRAM_D9, SRAM_D8, SRAM_D7, SRAM_D6, SRAM_D5, SRAM_D4,
			SRAM_D3, SRAM_D2, SRAM_D1, SRAM_D0 }),
		.OUTPUT_ENABLE(sram_wrlb || sram_wrub),
		.D_OUT_0(sram_dout),
		.D_IN_0(sram_din)
	);

	assign { SRAM_A17, SRAM_A16, SRAM_A15, SRAM_A14, SRAM_A13, SRAM_A12,
		SRAM_A11, SRAM_A10, SRAM_A9, SRAM_A8, SRAM_A7, SRAM_A6, SRAM_A5,
		SRAM_A4, SRAM_A3, SRAM_A2, SRAM_A1, SRAM_A0 } = sram_addr;

	assign SRAM_CE = 0;
	assign SRAM_WE = !(sram_wrlb || sram_wrub);
	assign SRAM_OE = (sram_wrlb || sram_wrub);
	assign SRAM_LB = (sram_wrlb || sram_wrub) ? !sram_wrlb : 0;
	assign SRAM_UB = (sram_wrlb || sram_wrub) ? !sram_wrub : 0;

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

	qqspi #() qqspi_i
	(
		.addr(qqspi_addr),
		.wdata(qqspi_wdata),
		.rdata(qqspi_rdata),
		.ready(qqspi_ready),
		.valid(qqspi_valid),
		.write(qqspi_wstrb),
		.clk(clk),
		.resetn(resetn),
		.sclk(QQSPI_SCK),
		.ss(QQSPI_SS),
		.mosi(QQSPI_MOSI),
		.miso(QQSPI_MISO),
		.sio2(QQSPI_SIO2),
		.sio3(QQSPI_SIO3),
		.cs({QQSPI_CS1, QQSPI_CS0})
	);
`endif

`ifdef EN_GPU
	wire gpu_refill;
	wire [9:0] gpu_x;
	wire [9:0] gpu_y;
	reg [7:0] gpu_refill_words;
	wire gpu_pixel;
`ifdef EN_GPU_GFX
	reg [639:0] gpu_hline_r;
	reg [639:0] gpu_hline_g;
	reg [639:0] gpu_hline_b;
	wire gpu_lock = (gpu_refill_words && sram_state == 0);
`else
	wire gpu_lock = 0;
`endif

	gpu_vga #(
	)
	gpu_vga_i (
		.clk(clk),
		.vclk(vclk),
		.resetn(resetn),
		.pixel(gpu_pixel),
`ifdef EN_GPU_GFX
		.hline_r(gpu_hline_r),
		.hline_g(gpu_hline_g),
		.hline_b(gpu_hline_b),
`endif
		.x(gpu_x),
		.y(gpu_y),
		.refill(gpu_refill),
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B),
		.hsync(VGA_HS),
		.vsync(VGA_VS)
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
	
	gpu_text #(
	)
	gpu_text_i (
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
	assign gpu_pixel = 0;
`endif

// --

	always @(posedge clk) begin

		mem_ready <= 0;

`ifdef EN_SRAM
		sram_wrlb <= 0;
		sram_wrub <= 0;
`endif

`ifdef EN_PS2
		ps2_rstrb <= 0;
		ps2_wstrb <= 0;
`endif

		transmit <= 0;

`ifdef EN_GPU_GFX
		if (gpu_refill) begin
			gpu_refill_words <= 160;
		end

		if (gpu_lock) begin

			sram_addr <= (gpu_y << 7) + (gpu_y << 5) + gpu_refill_words;

			gpu_hline_r <= { gpu_hline_r,
				sram_din[10], sram_din[14], sram_din[2], sram_din[6] };

			gpu_hline_g <= { gpu_hline_g,
				sram_din[9], sram_din[13], sram_din[1], sram_din[5] };

			gpu_hline_b <= { gpu_hline_b,
				sram_din[8], sram_din[12], sram_din[0], sram_din[4] };

			gpu_refill_words <= gpu_refill_words - 1;

		end
`endif

		if (received) begin
			uart_dr <= 1;
			UART_RTS <= 1;
		end

		if (!transmit && !is_transmitting && !UART_CTS) begin
			uart_txbusy <= 0;
		end

		if (!resetn) begin

			uart_dr <= 0;
			uart_txbusy <= 0;
			UART_RTS <= 0;

`ifdef EN_GPU
			gpu_refill_words <= 0;
`endif
`ifdef EN_SPI_FLASH
			spi_valid <= 0;
			spi_state <= 0;
`endif
`ifdef EN_SRAM
			sram_state <= 0;
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

		end else if (mem_valid && !mem_ready) begin

			(* parallel_case *)
			case (1)

				// BLOCK RAM
				(mem_addr < 8192): begin
			
					if (mem_wstrb[0]) bram[bram_word][7:0] <= mem_wdata[7:0];
					if (mem_wstrb[1]) bram[bram_word][15:8] <= mem_wdata[15:8];
					if (mem_wstrb[2]) bram[bram_word][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) bram[bram_word][31:24] <= mem_wdata[31:24];

					mem_rdata <= bram[mem_addr >> 2];
					mem_ready <= 1;

				end

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
`endif

`ifdef EN_SRAM
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

`ifdef EN_HRAM
				((mem_addr & 32'hf000_0000) == 32'h4000_0000): begin

					if (mem_wstrb) begin

						// XXX TODO FIX: shouldn't have to read then write here,
						// but code execution isn't working otherwise,
						// must be doing something really dumb somewhere

						if (hram_state == 0 && !hram_ready) begin
 
							hram_addr <= (mem_addr & 32'h0fff_ffff);
							hram_wstrb <= 0;
							hram_valid <= 1;
							hram_state <= 1;

						end else if (hram_state == 1 && hram_ready) begin

							hram_wdata <= hram_rdata;
							hram_valid <= 0;
							hram_state <= 2;

						end else if (hram_state == 2 && !hram_ready) begin

							if (mem_wstrb[0]) hram_wdata[7:0] <= mem_wdata[7:0];
							if (mem_wstrb[1]) hram_wdata[15:8] <= mem_wdata[15:8];
							if (mem_wstrb[2]) hram_wdata[23:16] <= mem_wdata[23:16];
							if (mem_wstrb[3]) hram_wdata[31:24] <= mem_wdata[31:24];

							hram_wstrb <= 4'b1111;
							hram_valid <= 1;
							hram_state <= 3;

						end else if (hram_state == 3 && hram_ready) begin

							hram_valid <= 0;
							hram_state <= 4;

						end else if (hram_state == 4 && !hram_ready) begin

							hram_state <= 0;
							mem_ready <= 1;

						end
/*
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
*/
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

`ifdef EN_SPI_FLASH
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

				((mem_addr & 32'hf000_0000) == 32'hf000_0000): begin

					(* parallel_case *)
					case (mem_addr[15:0])

						16'h0000: begin
							if (mem_wstrb && !uart_txbusy) begin
								tx_byte <= mem_wdata[7:0];
								uart_txbusy <= 1;
								transmit <= 1;
								mem_ready <= 1;
							end else if (!mem_wstrb) begin
								mem_rdata[7:0] <= rx_byte;
								uart_dr <= 0;
								UART_RTS <= 0;
								mem_ready <= 1;
							end
						end

						16'h0004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= { 6'b0, uart_txbusy, uart_dr };
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
								{spi_ss_sd, spi_sd_sck, spi_sd_mosi} <= mem_wdata[3:1];
							else
								mem_rdata[7:0] <= {
									4'b0, spi_ss_sd, spi_sd_sck, spi_sd_mosi, SPI_MISO
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

	// UART
	// ----

	reg transmit;
	reg [7:0] tx_byte;
	wire received;
	wire [7:0] rx_byte;
	wire is_receiving;
	wire is_transmitting;
	wire recv_error;

	reg uart_dr;
	reg uart_txbusy;

	uart #(
		.baud_rate(UART_BAUDRATE),
		.sys_clk_freq(SYSCLK)
	)
	uart0 (
		.clk(clk),
		.rst(~resetn),
		.rx(UART_TX),
		.tx(UART_RX),
		.transmit(transmit),
		.tx_byte(tx_byte),
		.received(received),
		.rx_byte(rx_byte),
		.is_receiving(is_receiving),
		.is_transmitting(is_transmitting),
		.recv_error(recv_error)
	);

endmodule
