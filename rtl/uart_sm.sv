module uart_sm #(parameter int datawidth_p = 8)(
  input clk_i,
  input rst_i,

  input [datawidth_p - 1:0] rx_data_i,
  input rx_valid_i,
  output rx_ready_o,

  output [datawidth_p - 1:0] tx_data_o,
  output tx_valid_o,
  input tx_ready_i
);

// state enum
typedef enum logic [1:0] {StIdle, StTransmit} state_e;
state_e state_d, state_q;

// output ffs
logic [datawidth_p-1:0] tx_data_d, tx_data_q;
logic tx_valid_d, tx_valid_q, rx_ready_d, rx_ready_q;

// state machine
always_ff @( posedge clk_i ) begin : ff_state_machine
  if (rst_i) begin
    state_q <= StIdle;
    rx_ready_q <= 1'b0;
    tx_data_q <= '0;
    tx_valid_q <= 1'b0;
  end else begin
    state_q <= state_d;
    rx_ready_q <= rx_ready_d;
    tx_data_q <= tx_data_d;
    tx_valid_q <= tx_valid_d;
  end
end

always_comb begin : comb_state_machine
  // defaults
  state_d = state_q;
  rx_ready_d = rx_ready_q;
  tx_data_d = tx_data_q;
  tx_valid_d = tx_valid_q;

  case (state_q)
    StIdle: begin
      // outputs
      rx_ready_d = 1'b1;

      // state transition (mealy to prevent next cycle data)
      if (rx_valid_i && rx_ready_q) begin
        state_d = StTransmit;
        rx_ready_d = 1'b0;
        tx_valid_d = 1'b1;
        tx_data_d = rx_data_i;
      end
    end

    StTransmit: begin
      // outputs
      rx_ready_d = 1'b0;

      // state transition (mealy)
      if (tx_ready_i && tx_valid_q) begin
        state_d = StIdle;
        rx_ready_d = 1'b1;
        tx_valid_d = 1'b0;
      end
    end
  endcase
end

assign rx_ready_o = rx_ready_q;
assign tx_data_o = tx_data_q;
assign tx_valid_o = tx_valid_q;

endmodule
