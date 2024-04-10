/*
 * Zucker SOC
 * Copyright (c) 2023 Lone Dynamics Corporation. All rights reserved.
 *
 * SDRAM controller (tested with W9825G6KH-6)
 *
 */

module sdram
(
	input clk,
	input resetn,

	input [31:0] addr,
	output reg [15:0] rdata,
	input [15:0] wdata,
	input wstrb,
	input rstrb,
	output reg ready,

	output sdclk, cke, cs_n, ras_n, cas_n, we_n,
	output reg [12:0] a,
	output reg [1:0] ba,
	inout [15:0] dq,
	output reg [1:0] dm,
	output [2:0] state
);

localparam MODE = 13'b0_0000_0010_0000;

localparam CMD_MODE_REG_SET = 4'b0000;
localparam CMD_AUTO_REFRESH = 4'b0001;
localparam CMD_PRECHARGE = 4'b0010;
localparam CMD_ACTIVE = 4'b0011;
localparam CMD_WRITE = 4'b0100;
localparam CMD_READ = 4'b0101;
localparam CMD_NOP = 4'b0111;

reg [2:0] state;
reg [3:0] cmd;
assign { cs_n, ras_n, cas_n, we_n } = cmd;

reg dq_oe;

assign dq = dq_oe ? wdata : 16'hzzzz;
assign sdclk = clk;
assign cke = 1'b1;

reg [7:0] lctr;

always @(negedge clk) begin

	ready <= 0;

	if (!resetn) begin

		state <= 4;
		lctr <= 0;

	end else begin

		rdata <= dq;

		case(state)

			0: begin

				if (rstrb || wstrb) begin
					cmd <= CMD_ACTIVE;
					ba <= addr[24:23];
					a <= addr[23:8];
					dm <= 2'b11;
					state <= 1;
				end else begin
					cmd <= CMD_NOP;
					ba <= 0;
					a <= 0;
					dm <= 2'b11;
					state <= 0;
				end

			end

			1: begin

				if (rstrb) begin
					cmd <= CMD_READ;
					dq_oe <= 1'b0;
				end else begin
					cmd <= CMD_WRITE;
					dq_oe <= 1'b1;
				end

				a[9:0] <= { 2'b00, addr[7:0] };
				a[10] <= 1'b0;
				dm <= 2'b00;
				state <= 2;

			end

			2: begin

				cmd <= CMD_PRECHARGE;
				ba <= 0;
				a <= 14'b1_0000_0000_0000;
				dm <= 2'b11;
				lctr <= 0;
				state <= 3;

			end

			3: begin

				if (lctr == 3) begin
					ready <= 1;
					state <= 0;
				end

			end

			4: begin

				if (lctr == 50) begin
					cmd <= CMD_PRECHARGE;
					ba <= 2'b00;
					a <= 13'b0_0100_0000_0000;	// precharge all
				end else if (lctr == 51) begin
					cmd <= CMD_NOP;
				end else if (lctr == 100) begin
					cmd <= CMD_AUTO_REFRESH;
				end else if (lctr == 101) begin
					cmd <= CMD_NOP;
				end else if (lctr == 150) begin
					cmd <= CMD_AUTO_REFRESH;
				end else if (lctr == 151) begin
					cmd <= CMD_NOP;
				end else if (lctr == 200) begin
					state <= 0;
				end else begin
					cmd <= CMD_NOP;
					ba <= 0;
					a <= 0;
					dm <= 2'b11;
				end
			end

		endcase

		lctr <= lctr + 1;

	end

end

endmodule
