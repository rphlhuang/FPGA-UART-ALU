`timescale 1ns/1ps
module uart_runner;

  // Clock generator
  localparam cycle_time_p = 10;
  logic [0:0] clk_i, rst_i;
  initial begin
    clk_i = 1'b0;
  end
  always #(cycle_time_p/2.0) begin
    clk_i <= ~clk_i;
  end


  // rx_i stimuli
  wire [15:0] prescale_w;
  logic [7:0] tx_stim_i;
  logic [0:0] tx_valid_i;
  logic [0:0] tx_o, rx_i;

  localparam BAUD_RATE = 115200;
  assign prescale_w = (BAUD_RATE * 8) / 100000;

  uart_tx #(.DATA_WIDTH(8)) model_tx_inst (
    .clk(clk_i),
    .rst(rst_i),

    // AXI Stream Interface (parallel to serial, what we want to send to PC)
    .s_axis_tdata(tx_stim_i), // input, [DATA_WIDTH-1:0]
    .s_axis_tvalid(tx_valid_i), // input
    .s_axis_tready(), // output

    // UART Interface (what the FPGA is sending, serially)
    .txd(rx_i), // input

    // Status
    .busy(), // output

    .prescale(prescale_w) // input, [15:0]
  );

  // DUT
  uart_alu #(.datawidth_p(8)) dut (.rx_i(rx_i), .tx_o(tx_o), .clk_i(clk_i), .rst_i(rst_i));

  // Tasks
  task automatic reset;
    @(negedge clk_i);
    rst_i = 1;
    @(negedge clk_i);
    rst_i = 0;
  endtask

  task automatic send_stimulus;
    @(negedge clk_i);
    tx_valid_i = 1'b1;
    tx_stim_i = 8'h55; // 01010101
    repeat(2) begin
      @(negedge clk_i);
    end
    tx_valid_i = 1'b0;
  endtask

endmodule
