`timescale 1ns/1ps
module uart_runner;

  // Clock generator
  localparam cycle_time_p = 49.321; // 20.2752 Mhz --> 49.321 ns
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
  logic [0:0] tx_valid_i, tx_ready_o;
  logic [0:0] tx_o, rx_i;

  // baud rate consts
  /* verilator lint_off WIDTHTRUNC */
  localparam BAUD_RATE = 115200;
  localparam CLK_FREQ_HZ = 20275200; // 20.2752 --> 20275200
  assign prescale_w = (CLK_FREQ_HZ) / (BAUD_RATE * 8);
  /* verilator lint_on WIDTHTRUNC */

  // stimulus generator: tx instance
  uart_tx #(.DATA_WIDTH(8)) model_tx_inst (
    .clk(clk_i),
    .rst(rst_i),

    // AXI Stream Interface (parallel to serial, what we want to send to PC)
    .s_axis_tdata(tx_stim_i), // input, [DATA_WIDTH-1:0]
    .s_axis_tvalid(tx_valid_i), // input
    .s_axis_tready(tx_ready_o), // output

    // UART Interface (what the FPGA is sending, serially)
    .txd(rx_i), // input

    // Status
    .busy(), // output

    .prescale(prescale_w) // input, [15:0]
  );

  // output decoder: rx instance
  wire [7:0] rx_data_o;
  wire rx_valid_o;
  uart_rx #(.DATA_WIDTH(8)) rx_inst (
    .clk(clk_i),
    .rst(rst_i),

    // AXI Stream Interface (serial to parallel, what we work with on FPGA)
    .m_axis_tdata(rx_data_o), // output, [DATA_WIDTH-1:0]
    .m_axis_tvalid(rx_valid_o), // output
    .m_axis_tready(1'b1), // input

    // UART Interface (what the FPGA is recieving, serially)
    .rxd(tx_o), // input

    // Status
    .busy(), // output
    .overrun_error(), // output
    .frame_error(), // output

    .prescale(prescale_w) // input, [15:0]
  );

  // DUT
  uart_alu #(.datawidth_p(8)) dut (.rx_i(rx_i), .tx_o(tx_o), .clk_i(clk_i), .rst_i(rst_i));

  // asks
  task automatic reset;
    @(negedge clk_i);
    tx_valid_i = 1'b0;
    tx_stim_i = '0;
    rst_i = 1;
    @(negedge clk_i);
    rst_i = 0;
  endtask

  task automatic wait_cycles(input int cycles);
    repeat(cycles) begin
      @(negedge clk_i);
    end
  endtask

  task automatic send_byte(input logic [7:0] data);
    wait (tx_ready_o == 1'b1);
    @(negedge clk_i);
    tx_valid_i = 1'b1;
    tx_stim_i = data;
    wait_cycles(1);
    tx_valid_i = 1'b0;
  endtask

  task automatic send_packet(
    input logic [7:0] opcode,
    input logic [31:0] data [],
    input logic [15:0] length
  );
    // header
    send_byte(opcode);
    send_byte(8'h00);
    send_byte(length[7:0]);
    send_byte(length[15:8]);

    // data
    for (int i = 0; i < data.size(); i++) begin
      send_byte(data[i][31:24]);
      send_byte(data[i][23:16]);
      send_byte(data[i][15:8]);
      send_byte(data[i][7:0]);
    end
  endtask

  task automatic wait_for_response(output logic [31:0] response);
    logic [7:0] b0, b1, b2, b3;
    $display("Waiting for rx_o...");
    // big-endian: read MSB first
    @(posedge rx_valid_o);
    b3 = rx_data_o;
    @(posedge rx_valid_o);
    b2 = rx_data_o;
    @(posedge rx_valid_o);
    b1 = rx_data_o;
    @(posedge rx_valid_o);
    b0 = rx_data_o;
    response = {b3, b2, b1, b0};
  endtask


endmodule
