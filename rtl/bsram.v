/*
 * BSRAM
 * Copyright (c) 2023 Lone Dynamics Corporation. All rights reserved.
 *
 * Emulate 76800 bytes of external SRAM as 19200 32-bit words in BRAM.
 *
 * This is used for two 320x240x4 framebuffers.
 *
 */

module bsram #()
(
	input clk,
	input resetn,
	input [14:0] addr,
	output [31:0] rdata,
	input [31:0] wdata,
	input [3:0] wstrb
);

	reg [31:0] bsram [0:19199];

	assign rdata = bsram[addr];

	always @(posedge clk) begin
		if (wstrb[0]) bsram[addr][7:0] <= wdata[7:0];
		if (wstrb[1]) bsram[addr][15:8] <= wdata[15:8];
		if (wstrb[2]) bsram[addr][23:16] <= wdata[23:16];
		if (wstrb[3]) bsram[addr][31:24] <= wdata[31:24];
	end

endmodule
