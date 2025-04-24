module fingerprint_mean_processing(
input sysclk,
    input clk,
    input rst_n,
    input uart_rx,
    output reg [31:0] avg_out,  
    output reg done_avg
);

// UART RX Interface 
wire [7:0] rx_data;
wire rx_done;
parameter TOTAL_BYTES = 50;
parameter CLK_FREQ = 12_000_000;
parameter BAUD_RATE = 57_600;
parameter MAX_SUM_THRESHOLD = 12750;

// UART RX Instantiation
 UART_RX uart_rx_inst (
    .clk(sysclk),
    .FPGA_RX(uart_rx),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

// Expanded registers for 32-bit output
reg [31:0] sum;         
reg [14:0] byte_count;
reg [1:0] state;

// Modified division parameters
localparam DIVIDE_CYCLES = 63;  // 
reg [5:0] div_counter;          // 6 bits
reg [47:0] dividend;            // 48-bit dividend
reg [15:0] divisor;
reg [31:0] quotient;            // 32-bit quotient

// State definitions
localparam IDLE = 2'b00,
           ACCUMULATE = 2'b01,
           CALC_AVG = 2'b10;

always @(posedge clk or posedge rst_n) begin
    if(rst_n) begin
        sum <= 32'b0;
        byte_count <= 15'b0;
        avg_out <= 32'b0;
        done_avg <= 1'b0;
        state <= IDLE;
        dividend <= 48'b0;
        divisor <= 16'b0;
        quotient <= 32'b0;
        div_counter <= 6'b0;
    end 
    else begin
        case(state)
            IDLE: begin
                if(rx_done) begin
                    sum <= rx_data;       // Initial sum with sign extension
                    byte_count <= 15'b1;
                    done_avg <= 1'b0;
                    div_counter <= 6'b0;
                    state <= ACCUMULATE;
                end
            end
            
            ACCUMULATE: begin
                if(rx_done & rx_data != 8'hFF & rx_data != 8'h00) begin
                    sum <= sum + rx_data;  // 32-bit accumulation
                    byte_count <= byte_count + 1'b1;
                end
                
                if(byte_count == TOTAL_BYTES) begin
                    if (sum <= MAX_SUM_THRESHOLD) begin
                        dividend <= {sum, 16'b0};  // 48-bit dividend for fixed-point
                        divisor <= TOTAL_BYTES;
                        state <= CALC_AVG;
                    end else begin
                        done_avg <= 1'b0;
                        state <= IDLE;
                    end
                end
            end
            
            CALC_AVG: begin
                if(div_counter < DIVIDE_CYCLES) begin
                    // Modified division for 48-bit dividend
                    if(dividend[47:32] >= divisor) begin
                        dividend <= {dividend[47:32] - divisor, dividend[31:0], 1'b1};
                        quotient <= {quotient[30:0], 1'b1};
                    end else begin
                        dividend <= {dividend[46:0], 1'b0};
                        quotient <= {quotient[30:0], 1'b0};
                    end
                    div_counter <= div_counter + 1'b1;
                end else begin
                    avg_out <= quotient;  // Full 32-bit output
                    done_avg <= 1'b1;
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule