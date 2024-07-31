/*
 * QQSPI
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * Verilog module for interfacing the LD-QQSPI-PSRAM32 Pmod(tm) compatible
 * module with ICE40 FPGAs.
 *
 */

module qqspi #(
	parameter [0:0] QUAD_MODE = 1
)(

	input [31:0] addr,
	output reg [31:0] rdata,
	input [31:0] wdata,
	output reg ready,
	input valid,
	input write,
	input clk,
	input resetn,

	output reg ss,
	output sck,
	inout mosi,
	inout miso,
	inout sio2,
	inout sio3,
	output reg [1:0] cs,
	output reg [2:0] state

);

	reg [3:0] sio_oe;
	reg [3:0] sio_do;
	wire [3:0] sio_di;

	reg sck_do;

	assign mosi = sio_oe[0] ? sio_do[0] : 1'bz;
	assign miso = sio_oe[1] ? sio_do[1] : 1'bz;
	assign sio2 = sio_oe[2] ? sio_do[2] : 1'bz;
	assign sio3 = sio_oe[3] ? sio_do[3] : 1'bz;

	assign sio_di = {sio3, sio2, miso, mosi};
	assign sck = valid ? sck_do : 1'bz;

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
	reg xfer_quad;

	always @(posedge clk) begin

		if (!resetn) begin

			cs <= 2'b00;
			ss <= 1;
			sck_do <= 0;
			sio_oe = 4'b1111;
			sio_do = 4'b0000;

			xfer_quad <= 0;
			xfer_bits <= 0;
			ready <= 0;

			state <= STATE_IDLE;

		end else if (valid && !ready && state == STATE_IDLE) begin

			state <= STATE_INIT;
			xfer_bits <= 0;

		end else if (!valid && ready) begin

			ready <= 0;

		end else if (xfer_bits) begin

			if (xfer_quad) begin
				sio_do[3:0] <= buffer[31:28];
			end else begin
				sio_do[0] <= buffer[31];
			end

			if (sck_do) begin
				sck_do <= 0;
			end else begin
				sck_do <= 1;
				if (xfer_quad) begin
					buffer <= {buffer, sio_di[3:0]};
					xfer_bits <= xfer_bits - 4;
				end else begin
					buffer <= {buffer, sio_di[1]};
					xfer_bits <= xfer_bits - 1;
				end
			end

		end else case (state)

			STATE_IDLE: begin
				sio_oe = 4'b0000;
				ss <= 1;
			end

			STATE_INIT: begin
				sio_oe <= 4'b0001;
				cs[1:0] <= addr[24:23];
				state <= STATE_START;
			end

			STATE_START: begin
				ss <= 0;
				state <= STATE_CMD;
			end

			STATE_CMD: begin
				if (QUAD_MODE)
					if (write) buffer[31:24] <= 8'h38; else buffer[31:24] <= 8'heb;
				else
					if (write) buffer[31:24] <= 8'h02; else buffer[31:24] <= 8'h03;
				xfer_bits <= 8;
				xfer_quad <= 0;
				state <= STATE_ADDR;
			end

			STATE_ADDR: begin
				buffer[31:8] <= { 1'b0, addr[22:0] };
				sio_oe <= 4'b1111;
				xfer_bits <= 24;
				if (QUAD_MODE)
					xfer_quad <= 1;
				if (QUAD_MODE && !write)
					state <= STATE_WAIT;
				else
					state <= STATE_XFER;
			end

			STATE_WAIT: begin
				sio_oe <= 4'b0000;
				xfer_bits <= 6;
				xfer_quad <= 0;
				state <= STATE_XFER;
			end

			STATE_XFER: begin
				if (QUAD_MODE)
					xfer_quad <= 1;
				if (write) begin
					sio_oe <= 4'b1111;
					buffer <= wdata;
				end else begin
					sio_oe <= 4'b0000;
				end
				xfer_bits <= 32;
				state <= STATE_END;
			end

			STATE_END: begin
				if (write)
					ss <= 1;
				else
					rdata <= buffer;
				ready <= 1;
				state <= STATE_IDLE;
			end

		endcase

	end

endmodule
