/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * read-only SPI flash module
 *
 */

module spiflashro #()
(
	input [31:0] addr,
	output reg [31:0] rdata,
	output reg ready,
	input valid,
	input clk,
	input resetn,
   output reg ss,
   output sck,
	output mosi,
	inout miso,
	output reg [3:0] state
);

	reg [3:0] state;

	localparam [3:0]
		STATE_IDLE			= 4'd0,
		STATE_INIT			= 4'd1,
		STATE_EPD0			= 4'd2,
		STATE_EPD1			= 4'd3,
		STATE_EPD2			= 4'd4,
		STATE_EPD3			= 4'd5,
		STATE_START			= 4'd6,
		STATE_CMD			= 4'd7,
		STATE_ADDR			= 4'd8,
		STATE_WAIT			= 4'd9,
		STATE_XFER			= 4'd10,
		STATE_END			= 4'd11;

	reg [31:0] buffer;
	reg [5:0] xfer_bits;

	reg mosi_do;
	reg sck_do;

	assign mosi = valid ? mosi_do : 1'bz;
	assign sck = valid ? sck_do : 1'bz;

	always @(posedge clk) begin

		if (!resetn) begin

			ss <= 1;
			sck_do <= 0;

			xfer_bits <= 0;
			ready <= 0;

			state <= STATE_IDLE;

		end else if (valid && !ready && state == STATE_IDLE) begin

			state <= STATE_INIT;
			xfer_bits <= 0;

		end else if (!valid && ready) begin

			ready <= 0;

		end else if (xfer_bits) begin

			mosi_do <= buffer[31];

			if (sck_do) begin
				sck_do <= 0;
			end else begin
				sck_do <= 1;
				buffer <= { buffer, miso };
				xfer_bits <= xfer_bits - 1;
			end

		end else case (state)

			STATE_IDLE: begin
				ss <= 1;
			end

			STATE_INIT: begin
				sck_do <= 0;
				state <= STATE_EPD0;
			end

			STATE_EPD0: begin
				ss <= 0;
				state <= STATE_EPD1;
			end

			STATE_EPD1: begin
				xfer_bits <= 8;
				buffer[31:24] <= 8'hab;
				state <= STATE_EPD2;
			end

			STATE_EPD2: begin
				ss <= 1;
				state <= STATE_EPD3;
			end

			STATE_EPD3: begin
				state <= STATE_START;
			end

			STATE_START: begin
				ss <= 0;
				state <= STATE_CMD;
			end

			STATE_CMD: begin
				buffer[31:24] <= 8'h03;
				xfer_bits <= 8;
				state <= STATE_ADDR;
			end

			STATE_ADDR: begin
				buffer[31:8] <= addr[23:0];
				xfer_bits <= 24;
				state <= STATE_XFER;
			end

			STATE_XFER: begin
				xfer_bits <= 32;
				state <= STATE_END;
			end

			STATE_END: begin
				rdata <= {
					buffer[7:0], buffer[15:8], buffer[23:16], buffer[31:24]
				};
				ready <= 1;
				state <= STATE_IDLE;
			end

		endcase

	end

endmodule
