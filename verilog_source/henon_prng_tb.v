`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 06:27:20 PM
// Design Name: 
// Module Name: henon_prng_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module henon_prng_tb;

    // 1) Combine or separate these properly:
    reg clk = 0;
    reg rst;
    reg start;
    reg [31:0] seed;

    reg [31:0] fingerprint_mean;

    wire [31:0] random_out_x;
    wire [31:0] random_out_y;
    wire done;

    henon_prng_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .seed_q31(seed),
        .fingerprint_mean(fingerprint_mean),
        .random_out_x(random_out_x),
        .random_out_y(random_out_y),
        .done(done)
    );

    // 2) Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting Henon PRNG testbench...");

        // Initialize fingerprint_mean here
        fingerprint_mean = 32'h12345678;

        // Reset sequence
        rst = 1;
        start = 0;
        seed = 32'h00123456;
        #20;
        rst = 0;
        #10;

        // Start PRNG
        start = 1;
        #10;
        start = 0;

        // Wait for result
        wait (done);
        $display("Random Output X: %h", random_out_x);
        $display("Random Output Y: %h", random_out_y);
        #20;
        $stop;
    end

endmodule
