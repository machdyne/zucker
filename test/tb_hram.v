`timescale 1ns / 1ns

module test_hram ();

reg clk = 0;

output reg [31:0] hram_addr;
output reg [31:0] hram_wdata;
wire [31:0] hram_rdata;
wire hram_ready;
output reg hram_valid;
reg [3:0] hram_wstrb;
reg resetn;
wire [15:0] adq;
wire [1:0] dqs;
wire ck;
wire ce;
wire [3:0] state;

hram #() hram_i (
	.addr(hram_addr),
	.wdata(hram_wdata),
	.rdata(hram_rdata),
	.ready(hram_ready),
	.valid(hram_valid),
	.wstrb(hram_wstrb),
	.clk(clk),
	.resetn(resetn),
	.adq(adq),
	.dqs(dqs),
	.ck(ck),
	.ce(ce)
);

always
	#1 clk = !clk;

initial
begin
	$dumpfile("test/hram.vcd"); 
	$dumpvars(0, test_hram);
	#10 resetn <= 1;
	#10 resetn <= 0;
	#10 resetn <= 1;

	#10 hram_addr <= 32'h00000000;
	#10 hram_wdata <= 32'h12345678;
	#10 hram_wstrb <= 4'b1010;
	#10 hram_valid <= 1;
	#10 hram_valid <= 0;

	#500

	#10 hram_addr <= 32'h00000002;
	#10 hram_wstrb <= 0;
	#10 hram_valid <= 1;
	#10 hram_valid <= 0;

	#500

	#1000 $finish;

end

initial
	$monitor("[%t] st: %d, addr: %h, wd: %h, rd: %h r: %b, v: %b w: %b rst: %b ck %b ce: %b adq: %h",
		$time, state, hram_addr, hram_wdata, hram_rdata, hram_ready, hram_valid, hram_wstrb, resetn, ck, ce, adq);

endmodule
