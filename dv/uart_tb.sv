`timescale 1ns/1ps
`define FINISH_WITH_FAIL error_o = 1; pass_o = 0; #10; $finish();
`define FINISH_WITH_PASS pass_o = 1; error_o = 0; #10; $finish();

module uart_tb (
  output logic error_o = 1'bx,
  output logic pass_o = 1'bx);

  // Error flag
  logic [0:0] error;
  assign error = 1'b0;

  // Runner
  uart_runner uart_runner ();

  logic [7:0] test_data [];

  // Testcases
  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    $display("---- BEGIN SIMULATION ----");

    uart_runner.reset();
    uart_runner.wait_cycles(10);

    uart_runner.send_byte(8'h55);
    uart_runner.wait_cycles(5000);

    test_data = '{8'h48, 8'h69}; // "Hi"
    uart_runner.send_packet(8'hEC, test_data, 16'h0006);
    uart_runner.wait_cycles(10000);

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
