/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * SPI slave controller
 *
 */

module spislave #()
(
	input clk,
	input resetn,

	output [7:0] rdata,
	input rstrb,
	output dr,

	input sclk,
	input mosi,

);

	reg [7:0] fifo [7:0];
	reg [2:0] fifo_wptr;
	reg [2:0] fifo_rptr;

	reg [7:0] xfer_buffer;
	reg [3:0] xfer_bits;
	reg xfer_done;
	reg xfer_done_r1;
	reg xfer_done_r2;
	reg xfer_done_r3;

	assign dr = (fifo_wptr != fifo_rptr);
	assign rdata = fifo[fifo_rptr];

	always @(posedge clk) begin

		xfer_done_r1 <= xfer_done;
		xfer_done_r2 <= xfer_done_r1;
		xfer_done_r3 <= xfer_done_r2;

		if (!resetn) begin
			fifo_rptr <= 0;
			fifo_wptr <= 0;
			xfer_done_r1 <= 0;
			xfer_done_r2 <= 0;
			xfer_done_r3 <= 0;
		end else if (rstrb && dr) begin
			fifo_rptr <= fifo_rptr + 1;
		end else if (xfer_done_r3 == 1'b0 && xfer_done_r2 == 1'b1) begin
			if ((fifo_wptr + 1) != fifo_rptr) begin
				fifo[fifo_wptr] <= xfer_buffer;
				fifo_wptr <= fifo_wptr + 1;
			end
		end

	end

	always @(posedge sclk) begin
		if (xfer_bits == 7) begin
			xfer_buffer <= { xfer_buffer, mosi };
			xfer_bits <= 0;
			xfer_done <= 1;
		end else begin
			xfer_buffer <= { xfer_buffer, mosi };
			xfer_bits <= xfer_bits + 1;
			xfer_done <= 0;
		end
	end

endmodule
