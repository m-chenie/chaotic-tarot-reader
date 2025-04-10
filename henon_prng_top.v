`timescale 1ns/1ps

module henon_prng_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [15:0] seed_16,        // 16-bit seed, we'll convert to Q1.31
    input wire [7:0] uart_pixel_in,   // 8-bit grayscale pixel
    input wire uart_pixel_valid,      // High when pixel is valid
    output reg [31:0] random_out_x,   // Final 32-bit x output in Q1.31
    output reg [31:0] random_out_y,   // Final 32-bit y output in Q1.31
    output reg done
);
    //--------------------------------------------------------------------
    // Q1.31 Constants
    //--------------------------------------------------------------------
    // 1.4 in decimal => ~0xB3333333 in Q1.31
    // 0.3 in decimal => ~0x26666666 in Q1.31
    localparam signed [31:0] A_Q31 = 32'hB3333333;  // ~1.4
    localparam signed [31:0] B_Q31 = 32'h26666666;  // ~0.3

    // We'll treat the 16-bit seed as an integer. For Q1.31, shift << 15
    // if you want the seed to represent that integer as a fraction.
    // E.g., seed=0x1234 => 4660 => Q1.31 => 4660 << 15
    //--------------------------------------------------------------------
    // We'll do a small example: TOT_PIXELS
    parameter TOTAL_PIXELS = 8;

    //--------------------------------------------------------------------
    // Internal regs
    //--------------------------------------------------------------------
    reg [2:0] state;
    reg [31:0] x, y;          // current x,y in Q1.31
    reg [31:0] latched_pixel; // the pixel stored as Q1.31
    reg [15:0] pixel_count;
    reg iter_start;           // single-cycle pulse to henon_map_q31
    wire iter_done;

    // We'll do a rising-edge detect on iter_done
    reg iter_done_d;
    wire iter_done_rising = iter_done & ~iter_done_d;

    // Convert incoming 16-bit seed to Q1.31 by shifting << 15
    wire [31:0] seed_q31 = {seed_16, 15'b0};

    // Here is the crucial change: SHIFT BY 15 instead of 23
    // => 255 => 0xFF << 15 => 0x7F8000 => ~0.0039 in Q1.31
    wire [31:0] pixel_q31 = {24'b0, uart_pixel_in}; //<< 15; 

    //--------------------------------------------------------------------
    // Henon iteration module (one iteration per start pulse)
    //--------------------------------------------------------------------
    wire signed [31:0] x_next, y_next;
    henon_map_q31 iter_unit (
        .clk(clk),
        .rst(rst),
        .start(iter_start),
        .x_in(x),
        .y_in(latched_pixel),
        .a(A_Q31),
        .b(B_Q31),
        .perturb(32'sd0),   // no external perturb
        .x_out(x_next),
        .y_out(y_next),
        .done(iter_done)
    );

    //--------------------------------------------------------------------
    // FSM states
    //--------------------------------------------------------------------
    localparam IDLE  = 3'd0,
               LATCH = 3'd1,
               START = 3'd2,
               WAIT  = 3'd3,
               DONE  = 3'd4;

    //--------------------------------------------------------------------
    // Main FSM
    //--------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x <= 0;
            y <= 0;
            pixel_count <= 0;
            latched_pixel <= 0;
            done <= 0;
            iter_start <= 0;
            iter_done_d <= 0;
            random_out_x <= 0;
            random_out_y <= 0;
        end else begin
            iter_done_d <= iter_done; // rising-edge track

            case (state)
                IDLE: begin
                    iter_start <= 0;
                    done <= 0;
                    if (start) begin
                        // load seed into x
                        x <= seed_q31;
                        y <= 0;          // or some desired initial y
                        pixel_count <= 0;
                        state <= LATCH;
                    end
                end

                LATCH: begin
                    iter_start <= 0;
                    if (uart_pixel_valid && pixel_count < TOTAL_PIXELS) begin
                        // capture pixel as Q1.31
                        latched_pixel <= pixel_q31;
                        state <= START;
                    end
                end

                START: begin
                    // single-cycle pulse
                    iter_start <= 1;
                    state <= WAIT;
                end

                WAIT: begin
                    iter_start <= 0;
                    // wait for iteration done
                    if (iter_done_rising) begin
                        // update x,y
                        x <= x_next;
                        y <= y_next;
                        pixel_count <= pixel_count + 1;

                        if (pixel_count + 1 == TOTAL_PIXELS) begin
                            // final result
                            random_out_x <= x_next;
                            random_out_y <= y_next;
                            done <= 1;
                            state <= DONE;
                        end else begin
                            state <= LATCH;
                        end
                    end
                end

                DONE: begin
                    // wait for start to go low
                    iter_start <= 0;
                    if (!start) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
