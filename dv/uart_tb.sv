`timescale 1ns/1ps
`define FINISH_WITH_FAIL error_o = 1; pass_o = 0; #10; $finish();
`define FINISH_WITH_PASS pass_o = 1; error_o = 0; #10; $finish();
/* verilator lint_off WIDTHTRUNC */
module uart_tb (
  output logic error_o = 1'bx,
  output logic pass_o = 1'bx);

  // Runner
  uart_runner uart_runner ();

  logic [31:0] test_data [];
  logic [31:0] rand_op, result, expected;
  logic [7:0] cur_opcode;
  logic [3:0] cur_length;

  // Testcases
  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    $display("---- BEGIN SIMULATION ----");

    uart_runner.reset();
    error_o = 0;
    test_data = '{};
    uart_runner.wait_cycles(1000);

    // uart_runner.send_byte(8'h55);
    // uart_runner.wait_cycles(100);

    // test_data = '{8'h48, 8'h69}; // "Hi"
    $display("\n----adder_simple_tests[2]----");
    test_data = '{32'd1, 32'd2};
    uart_runner.send_packet(8'h10, test_data, 16'd2);
    uart_runner.wait_for_response(result);
    if (result !== 32'd3) error_o = 1;
    $display("Adding test_data ", test_data, " , Got: ", result, "Expected: 3. error_o? ", error_o);

    test_data = '{32'd3, 32'd4};
    uart_runner.send_packet(8'h10, test_data, 16'd2);
    uart_runner.wait_for_response(result);
    if (result !== 32'd7) error_o = 1;
    $display("Adding test_data ", test_data, " , Got: ", result, "Expected: 7");

    // $display("\n----multiplier_simple_tests[2]----");
    // test_data = '{32'd5, 32'd6};
    // uart_runner.send_packet(8'h11, test_data, 16'd2);
    // uart_runner.wait_for_response(result);


    // test_data = '{32'd2, 32'd3, 32'd9999, 32'd1234, 32'h00ffffff};
    // uart_runner.send_packet(8'h10, test_data, 16'd5);
    // uart_runner.wait_for_response(result);
    // $display(result);

    // adder fuzz tests
    $display("\n----adder_fuzz_tests[100]----");
    cur_opcode = 8'h10;
    for (int i = 0; i <= 100; i++) begin
      cur_length = $random();
      if (cur_length <= 1) cur_length = 2;
      expected = 0;
      test_data = '{};
      for (int j = 0; j < cur_length; j++) begin
        rand_op = $random();
        expected += rand_op;
        test_data = '{test_data, rand_op};
      end
      $display("Adding test data ", test_data, " with length ", cur_length);
      uart_runner.send_packet(cur_opcode, test_data, {12'b0, cur_length});
      uart_runner.wait_for_response(result);
      if (result === expected) begin
        $display("\033[0;32mPASS:\033[0m Result = ", result, ", Expected = ", expected);
        $display();
      end else begin
        error_o = 1;
        $display("\033[0;31mFAIL:\033[0m Result = ", result, ", Expected = ", expected);
        $display();
      end
    end

    // adder fuzz tests
    // $display("\n----multiplier_fuzz_tests[100]----");
    // cur_opcode = 8'h11;
    // for (int i = 0; i <= 100; i++) begin
    //   cur_length = $random();
    //   if (cur_length <= 1) cur_length = 2;
    //   expected = 1;
    //   test_data = '{};
    //   for (int j = 0; j < cur_length; j++) begin
    //     rand_op = $random();
    //     expected *= rand_op;
    //     test_data = '{test_data, rand_op};
    //   end
    //   $display("Multiplying test data ", test_data, " with length ", cur_length);
    //   uart_runner.send_packet(cur_opcode, test_data, {12'b0, cur_length});
    //   uart_runner.wait_for_response(result);
    //   if (result === expected) begin
    //     $display("PASS: Result = ", result, ", Expected = ", expected);
    //     $display();
    //   end else begin
    //     error_o = 1;
    //     $display("FAIL: Result = ", result, ", Expected = ", expected);
    //     $display();
    //   end
    // end


    if (error_o) begin
      `FINISH_WITH_FAIL
    end else begin
      `FINISH_WITH_PASS
    end
  end

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
/* verilator lint_on WIDTHTRUNC */
