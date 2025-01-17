
module uart_alu #(parameter int datawidth_p = 8) (
    input clk_i,
    input rst_i,
    input rx_i,
    output tx_o
);

wire [15:0] prescale_w;
wire [datawidth_p-1:0] data_w;
wire [0:0] valid_w, ready_w;

localparam BAUD_RATE = 115200;
localparam CLK_FREQ_HZ = 33178;
assign prescale_w = (BAUD_RATE * 8) / CLK_FREQ_HZ;

uart_rx #(.DATA_WIDTH(datawidth_p)) rx_inst (
  .clk(clk_i),
  .rst(rst_i),

  // AXI Stream Interface (serial to parallel, what we work with on FPGA)
  .m_axis_tdata(data_w), // output, [DATA_WIDTH-1:0]
  .m_axis_tvalid(valid_w), // output
  .m_axis_tready(ready_w), // input

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
  .s_axis_tdata(data_w), // input, [DATA_WIDTH-1:0]
  .s_axis_tvalid(valid_w), // input
  .s_axis_tready(ready_w), // output

  // UART Interface (what the FPGA is sending, serially
  .txd(tx_o), // input

  // Status
  .busy(), // output

  .prescale(prescale_w) // input, [15:0]
);

endmodule
