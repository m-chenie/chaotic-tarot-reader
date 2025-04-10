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

// Testbench for henon_prng_top with preprocessed UART input

module henon_prng_tb;

    reg clk = 0;
    reg rst;
    reg start;
    reg [15:0] seed;
    reg [7:0] uart_pixel_in;
    reg uart_pixel_valid;
    wire [31:0] random_out_x;
    wire [31:0] random_out_y;
    wire done;

    // Instantiate DUT
    henon_prng_top #(
        .TOTAL_PIXELS(8)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .seed_16(seed),
        .uart_pixel_in(uart_pixel_in),
        .uart_pixel_valid(uart_pixel_valid),
        .random_out_x(random_out_x),
        .random_out_y(random_out_y),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk; 

    // Preprocessed 8-bit grayscale pixels (example:8 values)
    reg [7:0] pixel_data [0:7];
    integer i;

    initial begin
        $display("Starting Henon PRNG testbench...");

        // Sample pixel data (preprocessed 8-bit grayscale)
        pixel_data[0]  = 8'd10;
        pixel_data[1]  = 8'd22;
        pixel_data[2]  = 8'd45;
        pixel_data[3]  = 8'd63;
        pixel_data[4]  = 8'd78;
        pixel_data[5]  = 8'd99;
        pixel_data[6]  = 8'd120;
        pixel_data[7]  = 8'd135;

        // Reset sequence
        rst = 1;
        start = 0;
        uart_pixel_valid = 0;
        seed = 16'h1234;
        #20;
        rst = 0;
        #10;

        // Start PRNG
        start = 1;
        #10;
        start = 0;

        // Send pixel data
        for (i = 0; i < 8; i = i + 1) begin
            uart_pixel_in = pixel_data[i];
            uart_pixel_valid = 1;
            #100;
            uart_pixel_valid = 0;
            #50;
        end

        // Wait for result
        wait (done);
        $display("Random Output X: %h", random_out_x);
        $display("Random Output Y: %h", random_out_y);
        $stop;
    end

endmodule
