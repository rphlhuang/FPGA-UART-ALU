module uart_sm #(parameter int datawidth_p = 8)(
  input clk_i,
  input rst_i,

  input [datawidth_p - 1:0] rx_data_i,
  input rx_valid_i,
  output rx_ready_o,

  output [datawidth_p - 1:0] tx_data_o,
  output tx_valid_o,
  input tx_ready_i,

  input adder_done_i,
  input mul_done_i,
  input div_done_i,
  input [31:0] adder_result_i,
  input [31:0] mul_result_i,
  input [31:0] div_result_i,
  output start_add_o,
  output start_mul_o,
  output start_div_o,
  output [15:0] len_o
);

// state enum
typedef enum logic [3:0] {StIdle, StOpCode, StReserved, StLenLSB, StLenMSB, StWaitForFinish, StTransmit0, StTransmit1, StTransmit2, StTransmit3} state_e;
state_e state_d, state_q;

// ffs
logic [datawidth_p-1:0] tx_data_d, tx_data_q;
logic [datawidth_p-1:0] cur_opcode_d, cur_opcode_q;
logic [15:0] cur_len_d, cur_len_q;
logic start_d, start_q;

// result mux
logic [31:0] result_l;
always_comb begin
  result_l = 'x;
  if (cur_opcode_q === 8'h10) result_l = adder_result_i;
  else if (cur_opcode_q === 8'h11) result_l = mul_result_i;
  else if (cur_opcode_q === 8'h12) result_l = div_result_i; // change later
end

// done mux
logic done_l;
always_ff @(posedge clk_i) begin
  if (cur_opcode_q === 8'h10) done_l <= adder_done_i;
  else if (cur_opcode_q === 8'h11) done_l <= mul_done_i;
  else if (cur_opcode_q === 8'h12) done_l <= div_done_i; // change later
  else done_l <= 1'b0;
end


// state machine
always_ff @( posedge clk_i ) begin : ff_state_machine
  if (rst_i) begin
    state_q <= StIdle;
    tx_data_q <= '0;
    cur_opcode_q <= '0;
    cur_len_q <= '0;
    start_q <= 1'b0;
  end else begin
    state_q <= state_d;
    tx_data_q <= tx_data_d;
    cur_opcode_q <= cur_opcode_d;
    cur_len_q <= cur_len_d;
    start_q <= start_d;
  end
end

always_comb begin : comb_state_machine
  // defaults
  state_d = state_q;
  tx_data_d = tx_data_q;
  start_d = start_q;
  cur_len_d = cur_len_q;
  cur_opcode_d = cur_opcode_q;

  case (state_q)

    StIdle: begin
      // outputs
      cur_opcode_d = '0;
      cur_len_d = '0;
      start_d = 1'b0;

      if (rx_valid_i) begin
        state_d = StOpCode;
        cur_opcode_d = rx_data_i;
      end
    end

    StOpCode: begin
      if (rx_valid_i) begin
        state_d = StReserved;
      end
    end

    StReserved: begin
      if (rx_valid_i) begin
        state_d = StLenLSB;
        cur_len_d[7:0] = rx_data_i;
      end
    end

    StLenLSB: begin
      if (rx_valid_i) begin
        state_d = StLenMSB;
        cur_len_d[15:8] = rx_data_i;
      end
    end

    StLenMSB: begin
      if (rx_valid_i) begin
        state_d = StWaitForFinish;
        start_d = 1'b1;
      end
    end

    StWaitForFinish: begin
      start_d = 1'b0;
      if (done_l && tx_ready_i) begin
        state_d = StTransmit0;
        tx_data_d = result_l[31:24];
      end
    end

    StTransmit0: begin
      if (tx_ready_i) begin
        state_d = StTransmit1;
        tx_data_d = result_l[23:16];
      end
    end

    StTransmit1: begin
      if (tx_ready_i) begin
        state_d = StTransmit2;
        tx_data_d = result_l[15:8];
      end
    end

    StTransmit2: begin
      if (tx_ready_i) begin
        state_d = StTransmit3;
        tx_data_d = result_l[7:0];
      end
    end

    StTransmit3: begin
      if (tx_ready_i) begin
        state_d = StIdle;
      end
    end

  endcase
end

assign tx_data_o = tx_data_q;
assign rx_ready_o = (state_q === StIdle) || (state_q === StOpCode) || (state_q === StReserved) || (state_q === StLenLSB) || (state_q === StLenMSB);
assign tx_valid_o = (state_q === StTransmit0) || (state_q === StTransmit1) || (state_q === StTransmit2) || (state_q === StTransmit3);
assign start_add_o = start_q && (cur_opcode_q === 8'h10);
assign start_mul_o = start_q && (cur_opcode_q === 8'h11);
assign start_div_o = start_q && (cur_opcode_q === 8'h12);
assign len_o = cur_len_q;

endmodule
