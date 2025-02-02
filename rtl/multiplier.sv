module multiplier #(
) (
  input clk_i,
  input rst_i,

  input valid_i,
  input [7:0] data_i,
  output ready_o,

  input [15:0] len_i,
  input start_i,
  output done_o,
  output [31:0] result_o
);

typedef enum logic [2:0] {StIdle, StWaitForByte0, StWaitForByte1, StWaitForByte2, StWaitForByte3, StWaitForMul, StDone} state_e;
state_e state_d, state_q;
logic [31:0] cur_operand_d, cur_operand_q;
logic [15:0] len_cnt_d, len_cnt_q;
logic bsg_valid_l, done_l;
logic [31:0] bsg_opA_l;

always_ff @( posedge clk_i ) begin : ff_mul
  if (rst_i) begin
    state_q <= StIdle;
    cur_operand_q <= '0;
    len_cnt_q <= '0;
  end else begin
    state_q <= state_d;
    cur_operand_q <= cur_operand_d;
    len_cnt_q <= len_cnt_d;
  end
end

always_comb begin
    state_d = state_q;
    cur_operand_d = cur_operand_q;
    len_cnt_d = len_cnt_q;

    case (state_q)

      StIdle: begin
        // outputs

        // state transitions
        if (start_i) begin
          state_d = StWaitForByte0;
          cur_operand_d = '0;
          cur_operand_d[31:24] = data_i;
          len_cnt_d = len_i;
          bsg_opA_l = 32'd1;
          done_l = 1'b0;
        end
      end

      StWaitForByte0: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte1;
          cur_operand_d[23:16] = data_i;
        end
      end

      StWaitForByte1: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte2;
          cur_operand_d[15:8] = data_i;
        end
      end

      StWaitForByte2: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte3;
          cur_operand_d[7:0] = data_i;
        end
      end

      StWaitForByte3: begin
        // outputs

        // state transitions
        if (bsg_ready_o) begin
          bsg_valid_l = 1'b1;
          state_d = StWaitForMul;
        end
      end

      StWaitForMul: begin
        // outputs
        bsg_valid_l = 1'b0;

        // state transitions
        if (bsg_valid_o) begin
          state_d = StDone;
          bsg_opA_l = bsg_result_o;
          len_cnt_d = len_cnt_d - 1;
        end
      end

      StDone: begin
        // outputs

        // state transitions
        if (len_cnt_q === '0) begin
          state_d = StIdle;
          cur_operand_d = '0;
          done_l = 1'b1;
        end else if (valid_i) begin
          state_d = StWaitForByte0;
          cur_operand_d = '0;
          cur_operand_d[31:24] = data_i;
        end
      end

    endcase
end



// outputs: sm to bsg multiplier
wire bsg_valid_i, bsg_ready_o, bsg_valid_o, bsg_ready_i;
wire [31:0] bsg_opA_i, bsg_opB_i, bsg_result_o;


bsg_imul_iterative #(.width_p(32)) bsg_imul_inst (
  .clk_i(clk_i)
  ,.reset_i(rst_i)

  ,.v_i(bsg_valid_i)            // valid_i
  ,.ready_and_o(bsg_ready_o)    // ready_o
  ,.opA_i(bsg_opA_i)            // input [width_p-1: 0]
  ,.signed_opA_i(1'b0)
  ,.opB_i(bsg_opB_i)            // input [width_p-1: 0]
  ,.signed_opB_i(1'b0)
  ,.gets_high_part_i(1'b0)      // needs the high part result or low part result


  ,.v_o(bsg_valid_o)            // valid_o
  ,.yumi_i(bsg_ready_i)         // ready_i (?)
  ,.result_o(bsg_result_o)         // output [width_p-1: 0]
);

// opA is current accumulating result, opB is new number to be multiplied
assign bsg_opB_i = cur_operand_q;
assign bsg_opA_i = bsg_opA_l;
assign bsg_valid_i = bsg_valid_l;
assign bsg_ready_i = 1'b1;

// outputs: sm to alu
assign done_o = done_l;
assign result_o = bsg_result_o;
assign ready_o = 1'b1;

endmodule
