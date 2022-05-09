/*
 * Zucker GPU
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

module gpu_text #(
) (

	input clk,
	input resetn,
	input [9:0] x,
	input [9:0] y,
	output pixel,

	input [8:0] addr,
	input [31:0] wdata,
	output [31:0] rdata,
	input [3:0] wstrb,

);

	reg [31:0] chr_word;

	wire [6:0] col = x[9:3];
	wire [4:0] row = y[8:4];

	reg [2:0] font_x;
	reg [3:0] font_y;

	wire [10:0] chr_addr = col + (row << 6) + (row << 4);
	wire [13:0] font_addr = (chr << 7) + font_x + (font_y << 3);

	wire [7:0] chr = chr_ascii - 8'h20;

	wire [7:0] chr_ascii = chr_addr[1:0] == 2'b00 ?
		chr_word[7:0] : chr_addr[1:0] == 2'b01 ?
			chr_word[15:8] : chr_addr[1:0] == 2'b10 ?
				chr_word[23:16] : chr_word[31:24];

	wire p;
	assign pixel = y < 400 && p;

	gpu_vram #() gpu_vram_i (
		.clk(clk),
		.wstrb(wstrb),
		.wdata(wdata),
		.addr_a(addr),
		.addr_b(chr_addr),
		.rdata_a(rdata),
		.rdata_b(chr_word)
	);

	gpu_font_rom #() gpu_font_rom_i (
		.clk(clk),
		.addr(font_addr),
		.pixel(p)
	);

	always @(posedge clk) begin
		font_x <= x[2:0];
		font_y <= y[3:0];
	end

endmodule
