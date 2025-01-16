`timescale 1ns/1ps
`define FINISH_WITH_FAIL error_o = 1; pass_o = 0; #10; $finish();
`define FINISH_WITH_PASS pass_o = 1; error_o = 0; #10; $finish();

module uart_tb (
  output logic error_o = 1'bx,
  output logic pass_o = 1'bx);

  // Error flag
  logic [0:0] error;
  assign error = 1'b0;

  // Clock generator
  localparam cycle_time_p = 10;
  logic [0:0] clk_i, rst_i;
  always #(cycle_time_p/2.0) begin
      clk_i <= ~clk_i;
  end

  // Model
  logic [7:0] tx_stim_i;
  logic [0:0] dut_rx_i, dut_tx_o, tx_valid_i;
  wire [15:0] prescale_w;
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
    .txd(dut_rx_i), // input

    // Status
    .busy(), // output

    .prescale(prescale_w) // input, [15:0]
  );


  // DUT
  uart_alu #(.datawidth_p(8)) dut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rx_i(dut_rx_i),
    .tx_o(dut_tx_o)
  );


  // Testcases
  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    // Initialize clock
    clk_i = 1'b0;
    rst_i = 1'b1;
    #(cycle_time_p * 10);
    rst_i = 1'b0;
    #(cycle_time_p * 10);

    $display("Hello");
    tx_valid_i = 1'b1;
    tx_stim_i = 8'h55; // 01010101
    @(posedge clk_i);
    @(negedge clk_i);

    tx_valid_i = 1'b0;
    #(cycle_time_p * 2000);

    if (error) begin
      `FINISH_WITH_FAIL
    end else begin
      `FINISH_WITH_PASS
    end
  end

   // This block executes after $finish() has been called.
   final begin
      $display("Simulation time is %t", $time);
      if(error_o) begin
      $display("\033[0;31m    ______                    \033[0m");
      $display("\033[0;31m   / ____/_____________  _____\033[0m");
      $display("\033[0;31m  / __/ / ___/ ___/ __ \\/ ___/\033[0m");
      $display("\033[0;31m / /___/ /  / /  / /_/ / /    \033[0m");
      $display("\033[0;31m/_____/_/  /_/   \\____/_/     \033[0m");
      $display("Simulation Failed");
        end else begin
      $display("\033[0;32m    ____  ___   __________\033[0m");
      $display("\033[0;32m   / __ \\/   | / ___/ ___/\033[0m");
      $display("\033[0;32m  / /_/ / /| | \\__ \\\__ \ \033[0m");
      $display("\033[0;32m / ____/ ___ |___/ /__/ / \033[0m");
      $display("\033[0;32m/_/   /_/  |_/____/____/  \033[0m");
      $display();
      $display("Simulation Succeeded!");
      end
   end

endmodule
