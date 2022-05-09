/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

module gpu_vga #(

	parameter [9:0] h_disp = 640,
	parameter [9:0] h_front_porch = 16,
	parameter [9:0] h_pulse_width = 96,
	parameter [9:0] h_back_porch = 48,
	parameter [9:0] h_line = 800,

	parameter [9:0] v_disp = 480,
	parameter [9:0] v_front_porch = 10,
	parameter [9:0] v_pulse_width = 2,
	parameter [9:0] v_back_porch = 29,
	parameter [9:0] v_frame = 521

) (

	input pixel,
	input [639:0] hline_r,
	input [639:0] hline_g,
	input [639:0] hline_b,
	output reg refill,

	input clk,
	input vclk,
	input resetn,

	output red,
	output green,
	output blue,
	output hsync,
	output vsync,

	output [9:0] hc,
	output [9:0] vc,
	output reg [9:0] x,
	output reg [9:0] y,
	output is_visible

);

	reg [9:0] hc;
	reg [9:0] vc;

	reg refill_vclk;
	reg refill_vclk_last;

	parameter [9:0] h_disp_start = h_front_porch + h_pulse_width + h_back_porch;
	parameter [9:0] h_disp_stop = h_disp_start + h_disp;

	parameter [9:0] v_disp_start = v_front_porch + v_pulse_width + v_back_porch;
	parameter [9:0] v_disp_stop = v_disp_start + v_disp;

	assign is_visible = (hc >= h_disp_start && vc >= v_disp_start &&
		hc < h_disp_stop && vc < v_disp_stop);

	assign hsync = (hc < h_front_porch) ||
		(hc >= h_front_porch + h_pulse_width);
	assign vsync = (vc < v_front_porch) ||
		(vc >= v_front_porch + v_pulse_width);

`ifdef EN_GPU_GFX
	assign red = (is_visible && (hline_r[x] || pixel)) ? 1'b1 : 1'b0;
	assign green = (is_visible && (hline_g[x] || pixel)) ? 1'b1 : 1'b0;
	assign blue = (is_visible && (hline_b[x] || pixel)) ? 1'b1 : 1'b0;
`else
	assign red = (is_visible && pixel) ? 1'b1 : 1'b0;
	assign green = (is_visible && pixel) ? 1'b1 : 1'b0;
	assign blue = (is_visible && pixel) ? 1'b1 : 1'b0;
`endif

	always @(posedge clk) begin
		refill <= 0;
		if (refill_vclk && refill_vclk != refill_vclk_last) begin
			refill <= 1;
		end
		refill_vclk_last <= refill_vclk;
	end

	always @(posedge vclk) begin

		refill_vclk <= 0;

		if (!resetn) begin
			hc <= 0;
			vc <= 0;
		end else if (hc == h_disp_stop - 1) begin
			hc <= 0;
			if (vc == v_disp_stop - 1) begin
				vc <= 0;
			end else begin
				vc <= vc + 1;
				if (vc > v_disp_start) y <= vc - v_disp_start + 1; else y <= 0;
			end
			refill_vclk <= 1;
		end else begin
			hc <= hc + 1;
			if (hc > h_disp_start) x <= hc - h_disp_start + 1; else x <= 0;
		end

	end

endmodule
