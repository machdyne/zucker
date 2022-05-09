module sysclk(input clk, output clkout, output clkout90, output pll_locked);

	// 48MHz -> 64MHz (FEEDBACK: NON_SIMPLE)
   SB_PLL40_2F_PAD #(
      .FEEDBACK_PATH("PHASE_AND_DELAY"),
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
      .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
      .PLLOUT_SELECT_PORTA("SHIFTREG_0deg"),
      .PLLOUT_SELECT_PORTB("SHIFTREG_90deg"),
      .SHIFTREG_DIV_MODE(1'b0),
      .FDA_FEEDBACK(4'b1111),
      .FDA_RELATIVE(4'b1111),
      .DIVR(4'b0010),
      .DIVF(7'b0000011),
      .DIVQ(3'b100),
      .FILTER_RANGE(3'b001)
   ) pll1 (
      .PACKAGEPIN     (clk          ),
      .PLLOUTGLOBALA  (clkout       ),
      .PLLOUTGLOBALB  (clkout90     ),
      .LOCK           (pll_locked   ),
      .BYPASS         (1'b0         ),
      .RESETB         (1'b1         )
   );

endmodule
