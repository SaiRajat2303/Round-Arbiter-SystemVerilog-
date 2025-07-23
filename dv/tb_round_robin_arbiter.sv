// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module tb_round_robin_arbiter;

  // Parameters
  parameter NUM_REQUESTS = 4;
  parameter NUM_CLK_GRANT = 4;

  // DUT signals
  logic clk;
  logic rst;
  logic [NUM_REQUESTS-1:0] req;
  logic [NUM_CLK_GRANT-1:0] grant;

  // Clock generation
  always #5 clk = ~clk;

  // Instantiate DUT
  round_robin_arbiter #(.NUM_REQUESTS(NUM_REQUESTS), .NUM_CLK_GRANT(NUM_CLK_GRANT)) dut (
    .clk(clk),
    .reset(rst),
    .req(req),
    .grant(grant)
  );

  // Task to apply a request pattern and wait for one grant
                        task apply_request(input logic [NUM_REQUESTS-1:0] request, input int cycles = 3);
    begin
      req = request;
      repeat(cycles) @(posedge clk);
      $display("[%0t] REQ: %b  GRANT: %b", $time, req, grant);
    end
  endtask

  // Reset sequence
  task reset_dut();
    begin
      rst = 1;
      req = 0;
      @(posedge clk);
      rst = 0;
      @(posedge clk);
    end
  endtask

  // Test sequence
  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_round_robin_arbiter);
    $display("Starting Round Robin Arbiter Testbench...");
    clk = 0;
    reset_dut();

    // Single request active
    apply_request(4'b0001, 3);
    apply_request(4'b0010, 3);
    apply_request(4'b0100, 3);
    apply_request(4'b1000, 3);

    // Multiple requests, should rotate
    apply_request(4'b1011, 6); // Grant should rotate among 0, 1, and 3
    apply_request(4'b1111, 8); // Grant should rotate among all

    // Only one bit set
    apply_request(4'b0001, 4); // Grant 0 always
    apply_request(4'b0010, 4); // Grant 1 always

    // No requests active
    apply_request(4'b0000, 2); // Grant should be 0

    // Random patterns
    apply_request(4'b0110, 5); // 1 and 2 toggle
    apply_request(4'b1010, 5); // 1 and 3 toggle

    $display("Test completed.");
    $finish;
  end

endmodule
