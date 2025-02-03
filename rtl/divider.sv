module divider #(
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

typedef enum logic [3:0] {StIdle, StWaitForByte0, StWaitForByte1, StWaitForByte2, StWaitForByte3, StWaitForByte4, StWaitForByte5, StWaitForByte6, StWaitForByte7, StWaitForDiv, StDone} state_e;
state_e state_d, state_q;
logic [31:0] cur_dividend_d, cur_dividend_q;
logic [31:0] cur_divisor_d, cur_divisor_q;
// logic [15:0] len_cnt_d, len_cnt_q;
logic bsg_valid_i_d, bsg_valid_i_q;

always_ff @( posedge clk_i ) begin : ff_mul
  if (rst_i) begin
    state_q <= StIdle;
    cur_dividend_q <= '0;
    cur_divisor_q <= '0;
    // len_cnt_q <= '0;
    bsg_valid_i_q <= 1'b0;
  end else begin
    state_q <= state_d;
    cur_dividend_q <= cur_dividend_d;
    cur_divisor_q <= cur_divisor_d;
    // len_cnt_q <= len_cnt_d;
    bsg_valid_i_q <= bsg_valid_i_d;
  end
end

always_comb begin
    state_d = state_q;
    cur_dividend_d = cur_dividend_q;
    cur_divisor_d = cur_divisor_q;
    // len_cnt_d = len_cnt_q;
    // bsg_opA_d = bsg_opA_q;
    bsg_valid_i_d = bsg_valid_i_q;

    case (state_q)

      StIdle: begin
        // outputs

        // state transitions
        if (start_i) begin
          state_d = StWaitForByte0;
          cur_dividend_d = '0;
          cur_divisor_d = '0;
          cur_dividend_d[31:24] = data_i;
          // len_cnt_d = len_i;
          // bsg_opA_d = 32'd1;
        end
      end

      StWaitForByte0: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte1;
          cur_dividend_d[23:16] = data_i;
        end
      end

      StWaitForByte1: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte2;
          cur_dividend_d[15:8] = data_i;
        end
      end

      StWaitForByte2: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte3;
          cur_dividend_d[7:0] = data_i;
        end
      end

      StWaitForByte3: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte4;
          cur_divisor_d[31:24] = data_i;
        end
      end

      StWaitForByte4: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte5;
          cur_divisor_d[23:16] = data_i;
        end
      end

      StWaitForByte5: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte6;
          cur_divisor_d[15:8] = data_i;
        end
      end

      StWaitForByte6: begin
        // outputs

        // state transitions
        if (valid_i) begin
          state_d = StWaitForByte7;
          cur_divisor_d[7:0] = data_i;
        end
      end

      StWaitForByte7: begin
        // outputs

        // state transitions
        if (bsg_ready_o) begin
          bsg_valid_i_d = 1'b1;
          state_d = StWaitForDiv;
        end
      end

      StWaitForDiv: begin
        // outputs
        bsg_valid_i_d = 1'b0;

        // state transitions
        if (bsg_valid_o) begin
          state_d = StDone;
          // bsg_opA_d = bsg_result_o;
          // len_cnt_d = len_cnt_d - 1;
        end
      end

      StDone: begin
        // outputs

        // state transitions
        // if (len_cnt_q === '0) begin
          state_d = StIdle;
          cur_dividend_d = '0;
          cur_divisor_d = '0;
        // end else if (valid_i) begin
        //   state_d = StWaitForByte0;
        //   cur_dividend_d = '0;
        //   cur_dividend_d = '0;
        //   cur_dividend_d[31:24] = data_i;
        // end
      end

    endcase
end



// outputs: sm to bsg multiplier
wire bsg_valid_i, bsg_ready_o, bsg_valid_o, bsg_ready_i;
wire [31:0] bsg_opA_i, bsg_opB_i, bsg_result_o;


bsg_idiv_iterative #(.width_p(32)) bsg_idiv_inst (
  .clk_i(clk_i)
  ,.reset_i(rst_i)

  ,.v_i(bsg_valid_i)            // valid_i
  ,.ready_and_o(bsg_ready_o)    // ready_o
  ,.dividend_i(bsg_opA_i)       // input [width_p-1: 0]
  ,.divisor_i(bsg_opB_i)        // input [width_p-1: 0]
  ,.signed_div_i(1'b0)

  ,.v_o(bsg_valid_o)            // valid_o
  ,.yumi_i(bsg_ready_i)         // ready_i (?)
  ,.quotient_o(bsg_result_o)    // output [width_p-1: 0]
  ,.remainder_o()               // output [width_p-1: 0]
);

// opA is current accumulating result, opB is new number to be multiplied
assign bsg_opA_i = cur_dividend_q;
assign bsg_opB_i = cur_divisor_q;
assign bsg_valid_i = bsg_valid_i_q;
assign bsg_ready_i = 1'b1;

// outputs: sm to alu
// assign done_o = (state_q === StDone) && (len_cnt_q === '0);
assign done_o = (state_q === StDone);
assign result_o = bsg_result_o;
assign ready_o = 1'b1;

endmodule
