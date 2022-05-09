/*
 * Zucker GPU
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

module gpu_vram #()
(
	input clk,
	input [3:0] wstrb,
	input [8:0] addr_a,
	input [10:0] addr_b,
	input [31:0] wdata,
	output reg [31:0] rdata_a,
	output reg [31:0] rdata_b,
);

	reg [31:0] vram [0:499];	// 80 x 25 characters

	always @(posedge clk) begin
		if (wstrb[0]) vram[addr_a][7:0] <= wdata[7:0];
		if (wstrb[1]) vram[addr_a][15:8] <= wdata[15:8];
		if (wstrb[2]) vram[addr_a][23:16] <= wdata[23:16];
		if (wstrb[3]) vram[addr_a][31:24] <= wdata[31:24];
		rdata_a <= vram[addr_a];
	end

	always @(posedge clk) begin
		rdata_b <= vram[addr_b >> 2];
	end

endmodule
