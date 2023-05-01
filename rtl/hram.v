/*
 * HRAM
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * Verilog module for APSxxxXXN DDR Octal SPI PSRAM.
 *
 * TODO: support X16 mode
 *
 */

module hram (
	input [31:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata,
	output reg ready,
	input valid,
	input [3:0] wstrb,
	input clk,
	input resetn,
	inout [15:0] adq,
	inout [1:0] dqs,
	output reg ck,
	output reg ce,
	output reg [3:0] state
);

	reg [15:0] adq_oe;
	reg [15:0] adq_do;
	wire [15:0] adq_di;

	reg [1:0] dqs_oe;
	reg [1:0] dqs_do;
	wire [1:0] dqs_di;

	reg [2:0] dqs_c;

	wire write = (wstrb != 0);

`ifdef TESTBENCH

   assign adq = adq_oe ? adq_do : 1'bz;
   assign adq_di = adq;

   assign dqs = dqs_oe ? dqs_do : 1'bz;
   assign dqs_di = dqs;

`else

	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b0)
	) hram_adq_io [15:0] (
		.PACKAGE_PIN(adq),
		.OUTPUT_ENABLE(adq_oe),
		.D_OUT_0(adq_do),
		.D_IN_0(adq_di)
	);

	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b0)
	) hram_dqs_io [1:0] (
		.PACKAGE_PIN(dqs),
		.OUTPUT_ENABLE(dqs_oe),
		.D_OUT_0(dqs_do),
		.D_IN_0(dqs_di)
	);

`endif

	localparam [3:0]
		STATE_IDLE			= 4'd0,
		STATE_RESET			= 4'd1,
		STATE_INIT			= 4'd2,
		STATE_START			= 4'd3,
		STATE_CMD			= 4'd4,
		STATE_ADDR			= 4'd5,
		STATE_WAIT			= 4'd6,
		STATE_XFER			= 4'd7,
		STATE_END			= 4'd8;

	reg [31:0] buffer;
	reg [5:0] xfer_edges;
	reg [1:0] xfer_ctr;
	reg xfer_rdy;

	always @(posedge clk) begin

		if (!resetn) begin

			ce <= 1;
			ck <= 0;

			adq_oe = 16'hffff;
			adq_do = 16'h0000;
			dqs_oe = 2'b00;

			xfer_edges <= 0;
			ready <= 0;

			state <= STATE_RESET;

		end else if (valid && !ready && state == STATE_IDLE) begin

			state <= STATE_INIT;
			xfer_edges <= 0;

		end else if (!valid && ready) begin

			ready <= 0;

		end else if (xfer_edges) begin

			if (state == STATE_END) begin
				if (wstrb[3] && xfer_edges == 4) dqs_do <= 2'b00;
				else if (wstrb[2] && xfer_edges == 3) dqs_do <= 2'b00;
				else if (wstrb[1] && xfer_edges == 2) dqs_do <= 2'b00;
				else if (wstrb[0] && xfer_edges == 1) dqs_do <= 2'b00;
				else dqs_do <= 2'b11;
			end

			if (xfer_ctr == 0) begin
				adq_do[7:0] <= buffer[31:24];
				buffer <= {buffer, 8'h00};
			end

			if (xfer_ctr == 1) begin

				if (ck) begin
					ck <= 0;
				end else begin
					ck <= 1;
				end

				xfer_edges <= xfer_edges - 1;
				xfer_ctr <= 0;

			end else begin
				xfer_ctr <= xfer_ctr + 1;
			end

		end else case (state)

			STATE_IDLE: begin
				ce <= 1;
			end

			STATE_RESET: begin
				ck <= 0;
				buffer <= 32'hffffffff;
				xfer_edges <= 8;
				xfer_ctr <= 0;
				ce <= 0;
				state <= STATE_IDLE;
			end

			STATE_INIT: begin
				ck <= 0;
				adq_oe = 16'hffff;
				dqs_oe = 2'b00;
				state <= STATE_START;
			end

			STATE_START: begin
				ce <= 0;
				state <= STATE_CMD;
			end

			STATE_CMD: begin
				if (write)
					buffer <= 32'h80000000;
				else
					buffer <= 32'h00000000;
				xfer_edges <= 2;
				xfer_ctr <= 0;
				state <= STATE_ADDR;
			end

			STATE_ADDR: begin
				buffer <= { 6'b0, addr[25:0] };
				xfer_edges <= 4;
				xfer_ctr <= 0;
				state <= STATE_WAIT;
				dqs_c <= 0;
				xfer_rdy <= 0;
			end

			STATE_WAIT: begin
				if (write) begin
					adq_oe <= 16'hffff;
					dqs_oe = 2'b11;
					xfer_edges <= 8;
					state <= STATE_XFER;
				end else begin
					adq_oe <= 16'h0000;
					xfer_edges <= 0;

					if (dqs_di[0] || xfer_rdy) begin

						xfer_rdy <= 1;

						if (xfer_ctr == 0) begin
							buffer <= {buffer, adq_di[7:0]};
							if (dqs_c == 3) state <= STATE_END;
							dqs_c <= dqs_c + 1;	
						end

					end
				
					if (xfer_ctr == 1) begin
						if (ck) ck <= 0; else ck <= 1;
						xfer_ctr <= 0;
					end else begin
						xfer_ctr <= xfer_ctr + 1;
					end

				end
			end

			STATE_XFER: begin
				if (write) begin
					buffer <= wdata;
				end
				xfer_edges <= 4;
				state <= STATE_END;
			end

			STATE_END: begin
				rdata <= buffer;
				ready <= 1;
				state <= STATE_IDLE;
			end

		endcase

	end

endmodule
