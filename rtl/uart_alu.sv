module uart_alu #(parameter int datawidth_p = 32) (
    input clk_i,
    input rst_i,
    input rx_i,
    output tx_o
);

wire [15:0] prescale_w;
// wire [datawidth_p-1:0] data_w;
// wire [0:0] valid_w, ready_w;

/* verilator lint_off WIDTHTRUNC */
localparam BAUD_RATE = 115200;
localparam CLK_FREQ_HZ = 33178000;
assign prescale_w = (CLK_FREQ_HZ) / (BAUD_RATE * 8);
/* verilator lint_on WIDTHTRUNC */


// State Machine
wire [datawidth_p-1:0] rx_data_w, tx_data_w;
wire rx_ready_sm_w, rx_ready_adder_w, rx_ready_mul_w, rx_valid_w, tx_ready_w, tx_valid_w;
wire adder_done_w, mul_done_w, start_add_w, start_mul_w, start_div_w;
wire [15:0] len_w;
wire [31:0] adder_result_w, mul_result_w;
uart_sm #(.datawidth_p(datawidth_p)) uart_sm_inst (
  .clk_i(clk_i),
  .rst_i(rst_i),

  .rx_data_i(rx_data_w),
  .rx_ready_o(rx_ready_sm_w),
  .rx_valid_i(rx_valid_w),

  .tx_data_o(tx_data_w),
  .tx_ready_i(tx_ready_w),
  .tx_valid_o(tx_valid_w),

  .done_i(adder_done_w),
  .start_add_o(start_add_w),
  .start_mul_o(start_mul_w),
  .start_div_o(start_div_w),
  .adder_result_i(adder_result_w),
  .mul_result_i(),
  .len_o(len_w)
);


// Sequential Add32, Mul32, Div32
adder #(.datawidth_p(8)) adder_inst (
  .clk_i(clk_i),
  .rst_i(rst_i),

  .valid_i(rx_valid_w),
  .data_i(rx_data_w),
  .ready_o(rx_ready_adder_w),

  .len_i(len_w),
  .start_i(start_add_w),
  .done_o(adder_done_w),
  .result_o(adder_result_w)
);


// UART handlers
uart_rx #(.DATA_WIDTH(datawidth_p)) rx_inst (
  .clk(clk_i),
  .rst(rst_i),

  // AXI Stream Interface (serial to parallel, what we work with on FPGA)
  .m_axis_tdata(rx_data_w), // output, [DATA_WIDTH-1:0]
  .m_axis_tvalid(rx_valid_w), // output
  .m_axis_tready(rx_ready_adder_w | rx_ready_sm_w), // input

  // UART Interface (what the FPGA is recieving, serially)
  .rxd(rx_i), // input

  // Status
  .busy(), // output
  .overrun_error(), // output
  .frame_error(), // output

  .prescale(prescale_w) // input, [15:0]
);


uart_tx #(.DATA_WIDTH(datawidth_p)) tx_inst (
  .clk(clk_i),
  .rst(rst_i),

  // AXI Stream Interface (parallel to serial, what we want to send to PC)
  .s_axis_tdata(tx_data_w), // input, [DATA_WIDTH-1:0]
  .s_axis_tvalid(tx_valid_w), // input
  .s_axis_tready(tx_ready_w), // output

  // UART Interface (what the FPGA is sending, serially
  .txd(tx_o), // input

  // Status
  .busy(), // output

  .prescale(prescale_w) // input, [15:0]
);

endmodule
