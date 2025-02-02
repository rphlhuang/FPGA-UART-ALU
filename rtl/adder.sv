module adder #(
  parameter int datawidth_p = 8
) (
  input clk_i,
  input rst_i,

  input valid_i,
  input [datawidth_p-1:0] data_i,
  output ready_o,

  input [15:0] len_i,
  input start_i,
  output done_o,
  output [31:0] result_o
);

typedef enum logic [2:0] {StIdle, StAdd0, StAdd1, StAdd2, StAdd3, StDone} state_e;
state_e state_d, state_q;

logic [0:0] done_d, done_q;
logic [31:0] result_d, result_q;
logic [15:0] len_cnt_d, len_cnt_q;
logic [31:0] cur_operand_d, cur_operand_q;

always_ff @( posedge clk_i ) begin : ff_adder
  if (rst_i) begin
    state_q <= StIdle;
    done_q <= 1'b0;
    result_q <= '0;
    len_cnt_q <= '0;
    cur_operand_q <= '0;
  end else begin
    state_q <= state_d;
    done_q <= done_d;
    result_q <= result_d;
    len_cnt_q <= len_cnt_d;
    cur_operand_q <= cur_operand_d;
  end
end

always_comb begin : comb_adder
  // defaults
  state_d = state_q;
  done_d = done_q;
  result_d = result_q;
  cur_operand_d = cur_operand_q;
  len_cnt_d = len_cnt_q;

  case (state_q)

    StIdle: begin
      // outputs
      done_d = 1'b0;
      // state transition
      if (start_i) begin
        state_d = StAdd0;
        result_d = '0;
        cur_operand_d[31:24] = data_i;
        len_cnt_d = len_i;
      end
    end

    StAdd0: begin
      // outputs
      done_d = 1'b0;
      // state transition
      if (valid_i) begin
        state_d = StAdd1;
        cur_operand_d[23:16] = data_i;
      end
    end

    StAdd1: begin
      // outputs
      done_d = 1'b0;
      // state transition
      if (valid_i) begin
        state_d = StAdd2;
        cur_operand_d[15:8] = data_i;
      end
    end

    StAdd2: begin
      // outputs
      done_d = 1'b0;
      // state transition
      if (valid_i) begin
        len_cnt_d = len_cnt_q - 1;
        cur_operand_d[7:0] = data_i;
        state_d = StAdd3;
      end
    end

    StAdd3: begin
      // outputs
      done_d = 1'b0;
      // state transition
      // if (valid_i) begin
        if (len_cnt_d === '0) begin
          result_d = result_q + cur_operand_d;
          cur_operand_d = '0;
          done_d = 1'b1;
          state_d = StIdle;
        end else if (valid_i) begin
          result_d = result_q + cur_operand_d;
          state_d = StAdd0;
          cur_operand_d = '0;
          cur_operand_d[31:24] = data_i;
        end
      // end
    end

    StDone: begin
      // outputs
      done_d = 1'b1;
      // state transition
      if (start_i) begin
        state_d = StAdd0;
        len_cnt_d = len_i;
      end
    end

  endcase
end

assign done_o = done_q;
assign result_o = result_q;
assign ready_o = 1'b1;

endmodule
