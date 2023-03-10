/*
 * Zucker SOC GPU
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 */

module gpu_video #(

	parameter [9:0] h_disp = 640,
	parameter [9:0] h_front_porch = 16,
	parameter [9:0] h_pulse_width = 96,
	parameter [9:0] h_back_porch = 48,
	parameter [9:0] h_line = 800,

	parameter [9:0] v_disp = 480,
	parameter [9:0] v_front_porch = 10,
	parameter [9:0] v_pulse_width = 2,

`ifdef VCLK25
	parameter [9:0] v_back_porch = 29,	// 25mhz
	parameter [9:0] v_frame = 521
`else
	parameter [9:0] v_back_porch = 33,	// 25.2mhz
	parameter [9:0] v_frame = 525
`endif

) (

	input pixel,
`ifdef EN_GPU_FB_PIXEL_DOUBLING
	input [319:0] hline_r,
	input [319:0] hline_g,
	input [319:0] hline_b,
`else
	input [639:0] hline_r,
	input [639:0] hline_g,
	input [639:0] hline_b,
`endif
	output reg refill,

	input clk,
	input vclk,
	input bclk,
	input resetn,

	output red,
	output green,
	output blue,
	output hsync,
	output vsync,

	output [3:0] dvi_p,
	output [3:0] dvi_n,

	output [3:0] dac,

	output [9:0] hc,
	output [9:0] vc,
	output reg [9:0] x,
	output reg [9:0] y,
	output [8:0] hx,
	output [8:0] hy,
	output is_visible,

);

	reg refill_vclk;
	reg refill_vclk_last;

	assign hx = x >> 1;
	assign hy = y >> 1;

`ifdef EN_GPU_FB
`ifdef EN_GPU_FB_PIXEL_DOUBLING
	assign red = (is_visible && (hline_r[hx] || pixel)) ? 1'b1 : 1'b0;
	assign green = (is_visible && (hline_g[hx] || pixel)) ? 1'b1 : 1'b0;
	assign blue = (is_visible && (hline_b[hx] || pixel)) ? 1'b1 : 1'b0;
`else
	assign red = (is_visible && (hline_r[x] || pixel)) ? 1'b1 : 1'b0;
	assign green = (is_visible && (hline_g[x] || pixel)) ? 1'b1 : 1'b0;
	assign blue = (is_visible && (hline_b[x] || pixel)) ? 1'b1 : 1'b0;
`endif
`else
	assign red = (is_visible && pixel) ? 1'b1 : 1'b0;
	assign green = (is_visible && pixel) ? 1'b1 : 1'b0;
	assign blue = (is_visible && pixel) ? 1'b1 : 1'b0;
`endif

`ifdef EN_VIDEO_DDMI

	wire [1:0] out_tmds_red;
	wire [1:0] out_tmds_green;
	wire [1:0] out_tmds_blue;
	wire [1:0] out_tmds_clk;

`ifdef FPGA_ICE40
	SB_LVCMOS SB_LVCMOS_RED (.DP(dvi_p[2]), .DN(dvi_n[2]), .clk_x5(bclk),
		.tmds_signal(out_tmds_red));
	SB_LVCMOS SB_LVCMOS_GREEN (.DP(dvi_p[1]), .DN(dvi_n[1]), .clk_x5(bclk),
		.tmds_signal(out_tmds_green));
	SB_LVCMOS SB_LVCMOS_BLUE (.DP(dvi_p[0]), .DN(dvi_n[0]), .clk_x5(bclk),
		.tmds_signal(out_tmds_blue));
	SB_LVCMOS SB_LVCMOS_CLK (.DP(dvi_p[3]), .DN(dvi_n[3]), .clk_x5(bclk),
		.tmds_signal(out_tmds_clk));
`else

        ODDRX1F ddr0_clock (.D0(out_tmds_clk   [0] ), .D1(out_tmds_clk   [1] ), .Q(dvi_p[3]), .SCLK(bclk), .RST(0));
        ODDRX1F ddr0_red   (.D0(out_tmds_red   [0] ), .D1(out_tmds_red   [1] ), .Q(dvi_p[2]), .SCLK(bclk), .RST(0));
        ODDRX1F ddr0_green (.D0(out_tmds_green [0] ), .D1(out_tmds_green [1] ), .Q(dvi_p[1]), .SCLK(bclk), .RST(0));
        ODDRX1F ddr0_blue  (.D0(out_tmds_blue  [0] ), .D1(out_tmds_blue  [1] ), .Q(dvi_p[0]), .SCLK(bclk), .RST(0));
/*
        assign dvi_p[3] = out_tmds_clk;
        assign dvi_p[2] = out_tmds_red;
        assign dvi_p[1] = out_tmds_green;
        assign dvi_p[0] = out_tmds_blue;
*/
`endif


	gpu_ddmi #(
		.DDR_ENABLED(1)
	) gpu_ddmi_i (
		.pclk(vclk),
		.tmds_clk(bclk),
		.in_vga_red({ red, 7'b0 }),
		.in_vga_green({ green, 7'b0 }),
		.in_vga_blue({ blue, 7'b0 }),
		.in_vga_blank(!is_visible),
		.in_vga_vsync(vsync),
		.in_vga_hsync(hsync),
		.out_tmds_red(out_tmds_red),
		.out_tmds_green(out_tmds_green),
		.out_tmds_blue(out_tmds_blue),
		.out_tmds_clk(out_tmds_clk)
	);

`endif

`ifdef EN_VIDEO_COMPOSITE

	// TODO

`endif

	// video timing

	reg [9:0] hc;
	reg [9:0] vc;

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
