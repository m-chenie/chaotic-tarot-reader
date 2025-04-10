`timescale 1ns/1ps

module henon_map_q31 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [31:0] x_in,
    input wire signed [31:0] y_in,
    input wire signed [31:0] a,
    input wire signed [31:0] b,
    input wire signed [31:0] perturb,
    output reg signed [31:0] x_out,
    output reg signed [31:0] y_out,
    output reg done
);

    reg [1:0] state;
    reg signed [63:0] x_sq, ax2, y_accum;
    reg start_d, start_rising;

    localparam IDLE = 2'd0,
               STEP1 = 2'd1,
               STEP2 = 2'd2,
               DONE = 2'd3;

    // Q1.31 representation of 1.0
    localparam signed [31:0] ONE_Q31 = 32'h8000_0000;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_out <= 0;
            y_out <= 0;
            done <= 0;
            start_d <= 0;
            start_rising <= 0;
            state <= IDLE;
        end else begin
            start_rising <= start & ~start_d; 
            start_d <= start; // latch old 'start'

            case (state)
                IDLE: begin
                    done <= 0;
                    if (start_rising) begin
                        x_sq <= (x_in * x_in);  // 64-bit product
                        state <= STEP1;
                    end
                end

                STEP1: begin
                    // (a * x_sq) >> 31 to bring Q2.62 => Q1.31
                    ax2 <= (a * x_sq) >>> 31;
                    state <= STEP2;
                end

                STEP2: begin
                    // x_{n+1} = 1.0 - a * x^2 + y + perturb
                    x_out <= ONE_Q31 - ax2[31:0] + y_in + perturb;
                    // y_{n+1} = (b * x) >> 31
                    y_accum = b * x_in;
                    y_out <= y_accum >>> 31;
                    state <= DONE;
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
