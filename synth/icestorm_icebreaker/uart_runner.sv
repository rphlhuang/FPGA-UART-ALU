module uart_runner;

  reg  CLK;
  reg  BTN_N = 0;
  wire LEDG_N;
  reg RX, TX;
  reg clk_i = CLK;

  wire led = !LEDG_N;

  initial begin
    CLK = 0;
    forever begin
      #41.666ns;  // 12MHz
      CLK = !CLK;
    end
  end

  logic pll_out;
  initial begin
    pll_out = 0;
    forever begin
      #5ns;  // 100MHz
      pll_out = !pll_out;
    end
  end
  assign icebreaker.pll.PLLOUTCORE = pll_out;

  icebreaker icebreaker (
    .CLK(CLK),
    .BTN_N(BTN_N),
    .LEDG_N(LEDG_N),
    .RX(RX),
    .TX(TX)
  );

  wire [15:0] prescale_w;
  logic [7:0] tx_stim_i;
  logic [0:0] tx_valid_i;
  localparam BAUD_RATE = 115200;
  assign prescale_w = (BAUD_RATE * 8) / 100000;
  uart_tx #(.DATA_WIDTH(8)) model_tx_inst (
    .clk(pll_out),
    .rst(BTN_N),
    // AXI Stream Interface (parallel to serial, what we want to send to PC)
    .s_axis_tdata(tx_stim_i), // input, [DATA_WIDTH-1:0]
    .s_axis_tvalid(tx_valid_i), // input
    .s_axis_tready(), // output

    // UART Interface (what the FPGA is sending, serially)
    .txd(RX), // input

    // Status
    .busy(), // output
    .prescale(prescale_w) // input, [15:0]
  );

  task automatic reset;
    @(negedge pll_out);
    BTN_N = 1;
    @(negedge pll_out);
    BTN_N = 0;
  endtask

  task automatic send_stimulus;
    @(negedge pll_out);
    tx_valid_i = 1'b1;
    tx_stim_i  = 8'h55;  // 01010101
    repeat (2) begin
      @(negedge pll_out);
    end
    tx_valid_i = 1'b0;
  endtask

endmodule
