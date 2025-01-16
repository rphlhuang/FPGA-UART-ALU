
module icebreaker (
    input  wire CLK,
    input  wire BTN_N,
    output wire LEDG_N,

    input wire RX,
    output wire TX
);

wire clk_12 = CLK; // 12Mhz
wire clk_o; // 100Mhz

// icepll -i [input] -o [output]
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'b1000010),
    .DIVQ(3'b011),
    .FILTER_RANGE(3'b001)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTCORE(clk_o)
);

uart_alu #(
    .datawidth_p(8)
) uart_alu_inst (
    .clk_i(clk_o),
    .rst_i(BTN_N),
    .rx_i(RX),
    .tx_o(TX)
);

assign LEDG_N = 1'b0;

endmodule
