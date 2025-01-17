
module icebreaker (
    input  wire CLK,
    input  wire BTN_N,
    output wire LEDG_N,

    input wire RX,
    output wire TX
);

wire clk_12 = CLK; // 12Mhz
wire clk_o; // 33.1776Mhz --> 33.000 MHz

// icepll -i [input] -o [output]
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'b1010111),
    .DIVQ(3'b101),
    .FILTER_RANGE(3'b001)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTGLOBAL(clk_o)
);

wire [0:0] rst_i;
SB_DFFER sync_inst (.C(clk_o), .R(1'b0), .E(1'b1), .D(~BTN_N), .Q(rst_i));

uart_alu #(
    .datawidth_p(8)
) uart_alu_inst (
    .clk_i(clk_o),
    .rst_i(rst_i),
    .rx_i(RX),
    .tx_o(TX)
);

assign LEDG_N = BTN_N;

endmodule
