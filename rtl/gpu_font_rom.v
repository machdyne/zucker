/*
 * Zucker GPU
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

module gpu_font_rom #()
(
	input clk,
	input [13:0] addr,
	output reg [0:0] pixel
);

	reg [0:0] vram_font [0:12288];	// (8 * 16) * 96 characters
	initial $readmemb("../data/font/font16.mem", vram_font);

	always @(posedge clk) begin
		pixel <= vram_font[addr];
	end

endmodule
