/*
 * RPMEM
 * Copyright (c) 2022 Lone Dynamics Corporation. All rights reserved.
 *
 * Verilog module for communicating with an RP2040 as an SPI slave.
 *
 * The slave interface is provided by the Keks firmware to provide the
 * following resources:
 *
 * SPI commands:
 *
 * 0x02 0x?????? 0x???????? - 32-bit read
 * 0x03 0x?????? 0x???????? - 32-bit write
 *
 */

module rpmem #()
(
	input [31:0] addr,
	output reg [31:0] rdata,
	input [31:0] wdata,
	output reg ready,
	input valid,
	input write,
	input clk,
	input resetn,
   output reg ss,
   output reg sclk,
	output reg mosi,
	input miso,
	input hold,
);

	reg [2:0] state;

	localparam [2:0]
		STATE_IDLE			= 4'd0,
		STATE_INIT			= 4'd1,
		STATE_START			= 4'd2,
		STATE_CMD			= 4'd3,
		STATE_ADDR			= 4'd4,
		STATE_WAIT			= 4'd5,
		STATE_XFER			= 4'd6,
		STATE_END			= 4'd7;

	reg [31:0] buffer;
	reg [5:0] xfer_bits;
	reg [15:0] delay;

	always @(posedge clk) begin

		if (!resetn) begin

			ss <= 1;
			sclk <= 0;

			xfer_bits <= 0;
			ready <= 0;

			state <= STATE_IDLE;

		end else if (valid && !ready && state == STATE_IDLE) begin

			state <= STATE_INIT;
			xfer_bits <= 0;

		end else if (!valid && ready) begin

			ready <= 0;

		end else if (delay) begin

			delay <= delay - 1;

		end else if (xfer_bits) begin

			delay <= 1000;

			mosi = buffer[31];

			if (sclk) begin
				sclk <= 0;
			end else begin
				sclk <= 1;
				xfer_bits <= xfer_bits - 1;
				buffer = {buffer, miso};
			end

		end else case (state)

			STATE_IDLE: begin
				ss <= 1;
			end

			STATE_INIT: begin
				sclk <= 0;
				state <= STATE_START;
			end

			STATE_START: begin
				ss <= 0;
				delay <= 100000;
				state <= STATE_CMD;
			end

			STATE_CMD: begin
				if (write) buffer[31:24] <= 8'h02; else buffer[31:24] <= 8'h03;
				xfer_bits <= 8;
				state <= STATE_ADDR;
			end

			STATE_ADDR: begin
				buffer[31:8] <= addr[23:0];
				xfer_bits <= 24;
				state <= STATE_XFER;
			end

			STATE_XFER: begin
				if (write) begin
					buffer <= wdata;
				end
				if ((!write && !hold) || write) begin
					delay <= 10000;
					xfer_bits <= 32;
					state <= STATE_END;
				end
			end

			STATE_END: begin
				rdata <= buffer;
				ready <= 1;
				state <= STATE_IDLE;
			end

		endcase

	end

endmodule
