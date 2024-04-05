/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * PS/2 keyboard module
 *
 * TODO: fix or remove host->device transfers
 *
 */

module ps2 (
	output [7:0] ps2_rdata,
	input [7:0] ps2_wdata,
	input ps2_rstrb,
	input ps2_wstrb,

	output reg ps2_busy,
	output ps2_dr,
	output reg ps2_overflow,

	inout ps2_dat,
	inout ps2_clk,

	output ps2_dat_dbg,
	output ps2_clk_dbg,
	output [7:0] ps2_bits_dbg,
	output [3:0] ps2_state_dbg,

	input clk,
	input resetn,
);

	reg [7:0] fifo [7:0];
	reg [2:0] fifo_wptr;
	reg [2:0] fifo_rptr;

	reg [8:0] ps2_buf_send;
	reg [9:0] ps2_buf_recv;
	reg [7:0] ps2_buf_out;
	reg [7:0] ps2_bits;

	reg ps2_dat_oe;
	reg ps2_dat_o;
	wire ps2_dat_i;
	reg ps2_clk_oe;
	reg ps2_clk_o;
	wire ps2_clk_i;

	assign ps2_dat_dbg = ps2_dat_oe ? ps2_dat_o : ps2_dat_i;
	assign ps2_clk_dbg = ps2_clk_oe ? ps2_dat_o : ps2_clk_i;

	assign ps2_dr = (fifo_wptr != fifo_rptr);
	assign ps2_rdata = fifo[fifo_rptr];

`ifdef FPGA_ICE40
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) ps2_dat_io [0] (
		.PACKAGE_PIN(ps2_dat),
		.OUTPUT_ENABLE(ps2_dat_oe),
		.D_OUT_0(ps2_dat_o),
		.D_IN_0(ps2_dat_i)
	);

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) ps2_clk_io [0] (
		.PACKAGE_PIN(ps2_clk),
		.OUTPUT_ENABLE(ps2_clk_oe),
		.D_OUT_0(ps2_clk_o),
		.D_IN_0(ps2_clk_i)
	);
`else

	assign ps2_dat_i = ps2_dat;
	assign ps2_clk_i = ps2_clk;
	assign ps2_dat = ps2_dat_oe ? ps2_dat_o : 1'bz;
	assign ps2_clk = ps2_clk_oe ? ps2_clk_o : 1'bz;

`endif

	assign ps2_bits_dbg = ps2_bits;
	assign ps2_state_dbg = state;

	localparam [3:0]
		ST_IDLE = 4'd0,
		ST_DEV_XFER = 4'd1,
		ST_HOST_DELAY = 4'd2,
		ST_HOST_XFER = 4'd3,
		ST_HOST_DONE = 4'd4;

	reg [3:0] state;
	reg [15:0] ctr;

	reg ps2_clk_s;
	reg ps2_clk_l;

	reg [3:0] ps2_clk_sync;

	wire sample = ps2_clk_sync[3] & ps2_clk_sync[2] &
		~ps2_clk_sync[1] & ~ps2_clk_sync[0];

	always @(posedge clk)
		ps2_clk_sync <= { ps2_clk_sync[2:0], ps2_clk_i };

	always @(posedge clk) begin
		ps2_clk_s <= ps2_clk_i;

		if (!resetn) begin
			ps2_busy <= 0;
			ps2_clk_oe <= 0;
			ps2_dat_oe <= 0;
			ps2_bits <= 0;
			state <= ST_DEV_XFER;
			fifo_wptr <= 0;
			fifo_rptr <= 0;
			ps2_overflow <= 0;
		end else if (ps2_wstrb) begin
			ps2_busy <= 1;
			ctr <= 0;
			ps2_clk_oe <= 1;
			ps2_clk_o <= 0;
			ps2_buf_send <= { ^ps2_wdata[0:7], ps2_wdata[7:0] };
			state <= ST_HOST_DELAY;
		end else if (state == ST_HOST_DELAY && ctr == 16'hffff) begin
			ps2_dat_oe <= 1;
			ps2_dat_o <= 0;
			ps2_clk_oe <= 0;
			ps2_bits <= 0;
			state <= ST_HOST_XFER;
		end else if (state == ST_HOST_DONE) begin
			ps2_bits <= 0;
			ps2_busy <= 0;
	//		if (ps2_clk_i && ps2_dat_i) state <= ST_DEV_XFER;
			state <= ST_DEV_XFER;
		end else if (state == ST_IDLE && ctr > 16'h1) begin
			ps2_bits <= 0;
			state <= ST_DEV_XFER;
		end else if (state == ST_DEV_XFER || state == ST_HOST_XFER) begin

			// timeout
//			if (ctr == 16'hffff) begin
//				ps2_bits <= 0;
//				if (state == ST_HOST_XFER) state <= ST_HOST_DONE;
//			end

			if (ps2_rstrb && ps2_dr) begin
				fifo_rptr <= fifo_rptr + 1;
				ps2_overflow <= 0;
			end

			if (state == ST_HOST_XFER && !ps2_clk_s && ps2_clk_l) begin
				if (ps2_bits == 9) begin
					ps2_dat_oe <= 0;
					state <= ST_HOST_DONE;
				end else begin
					ps2_dat_o <= ps2_buf_send[ps2_bits];
					ps2_bits <= ps2_bits + 1;
				end
			end

			// clock changed to low
			if (state == ST_DEV_XFER && sample) begin

				ctr <= 0;

				if (ps2_bits == 10) begin
					state <= ST_IDLE;
					if (!ps2_buf_recv[0] && ps2_dat_i && ^ps2_buf_recv[9:1]) begin
						if ((fifo_wptr + 1) != fifo_rptr) begin
							fifo[fifo_wptr] <= ps2_buf_recv[8:1];
							fifo_wptr <= fifo_wptr + 1;
						end else begin
							ps2_overflow <= 1;
						end
					end
				end else begin
					ps2_buf_recv[ps2_bits] <= ps2_dat_i;
					ps2_bits <= ps2_bits + 1;
				end

			end

		end

		ctr <= ctr + 1;
		ps2_clk_l <= ps2_clk_s;

	end

endmodule
