`timescale 1ns/1ps

module henon_prng_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [15:0] seed_q16,        // 16-bit seed, we'll convert to Q1.31
    input wire [31:0] fingerprint_mean, // 32-bit mean in Q1.31
    output reg [31:0] random_out_x,   // Final 32-bit x output in Q1.31
    output reg [31:0] random_out_y,   // Final 32-bit y output in Q1.31
    output reg done
);

    // 1.4 in decimal => ~0xB3333333 in Q1.31
    // 0.3 in decimal => ~0x26666666 in Q1.31
    localparam signed [31:0] A_Q31 = 32'hB3333333;  // ~1.4
    localparam signed [31:0] B_Q31 = 32'h26666666;  // ~0.3

    //--------------------------------------------------------------------
    // Internal regs
    //--------------------------------------------------------------------
    reg [1:0] state;
    reg [31:0] x, y;          // current x,y in Q1.31
    reg iter_start;           // single-cycle pulse to henon_map_q31
    reg [7:0] iter_count;
    wire iter_done;
    wire signed [31:0] x_next, y_next;

    // We'll do a rising-edge detect on iter_done
    reg iter_done_d;
    wire iter_done_rising = iter_done & ~iter_done_d;

    // convert 16-bit seed to Q1.31 by concatenating 15'b0 to the right
    wire [31:0] seed_q31 = {seed_q16, 15'b0};

    parameter TOTAL_ITER = 8;
    //--------------------------------------------------------------------
    // Henon iteration module (one iteration per start pulse)
    //--------------------------------------------------------------------
    henon_map_q31 iter_unit (
        .clk(clk),
        .rst(rst),
        .start(iter_start),
        .x_in(x),
        .y_in(fingerprint_mean), // use fingerprint_mean as initial y
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
    localparam IDLE = 2'd0,
               RUN  = 2'd1,
               WAIT = 2'd2,
               DONE_ST = 2'd3;



    //--------------------------------------------------------------------
    // Main FSM
    //--------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            iter_start <= 0;
            iter_count <= 0;
            x <= 0;
            y <= 0;
            random_out_x <= 0;
            random_out_y <= 0;
            iter_done_d <= 0;
        end else begin
            iter_done_d <= iter_done; // rising-edge track

            case (state)
                IDLE: begin
                    iter_start <= 0;
                    done <= 0;
                    if (start) begin
                        // load seed into x
                        x <= seed_q31;
                        y <= fingerprint_mean;    
                        iter_count <= 0;
                        state <= RUN;
                    end
                end

                RUN: begin
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
                        iter_count <= iter_count + 1;

                        if (iter_count + 1 == TOTAL_ITER) begin
                            // final output
                            random_out_x <= x_next;
                            random_out_y <= y_next;
                            done <= 1;
                            state <= DONE_ST;
                        end else begin
                            // do another iteration
                            state <= RUN;
                        end
                    end
                end

                DONE_ST: begin
                    
                    if (!start) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
