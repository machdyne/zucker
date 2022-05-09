module clkdiv(
	input clk,
	output reg clkout = 0
);

	always @(posedge clk) begin
		clkout <= ~clkout;
	end

endmodule
