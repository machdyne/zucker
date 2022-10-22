/*
 * Zucker SOC
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * sigma-delta modulator
 *
 */

module audio (

	input clk_pwm,

	input [7:0] data_left,
	input [7:0] data_right,

	output out_left,
	output out_right,

);

	reg [8:0] pwm_left_acc;
	reg [8:0] pwm_right_acc;

	assign out_left = pwm_left_acc[8];
	assign out_right = pwm_right_acc[8];

	always @(posedge clk_pwm)
		pwm_left_acc <= pwm_left_acc[7:0] + data_left;

	always @(posedge clk_pwm)
		pwm_right_acc <= pwm_right_acc[7:0] + data_right;

endmodule
