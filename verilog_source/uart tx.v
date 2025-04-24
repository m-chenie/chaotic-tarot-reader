module UART_TX(
    input clk,          // 12 MHz clock
    input tx_start,     // Trigger transmission (pulse)
    input [7:0] tx_data,// Data to transmit
    output reg tx,      // Serial output
    output reg tx_done  // Transmission complete
);

// Parameters
parameter CLK_FREQ = 12_000_000;   // 12 MHz
parameter BAUD_RATE = 9600;
parameter BIT_PERIOD = CLK_FREQ / BAUD_RATE;  // 1250 cycles/bit

// States
reg [1:0] state;
localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

// Transmission registers
reg [10:0] counter;     // 11-bit counter (counts up to 1250)
reg [2:0] bit_index;    // Tracks which bit is being sent
reg [7:0] data_buffer;  // Holds data during transmission

// Initialize
initial begin
    state = IDLE;
    tx = 1'b1;          // UART idle state is high
    tx_done = 0;
    counter = 0;
    bit_index = 0;
    data_buffer = 0;
end

// State Machine
always @(posedge clk) begin
    case (state)
        IDLE: begin
            tx <= 1'b1;         // Maintain idle state
            tx_done <= 0;
            if (tx_start) begin
                state <= START;
                data_buffer <= tx_data; // Latch input data
                counter <= 0;
            end
        end

        START: begin
            tx <= 1'b0;         // Start bit (low)
            if (counter == BIT_PERIOD - 1) begin
                state <= DATA;
                counter <= 0;
                bit_index <= 0;
            end else
                counter <= counter + 1;
        end

        DATA: begin
            tx <= data_buffer[0]; // Send LSB first
            if (counter == BIT_PERIOD - 1) begin
                data_buffer <= data_buffer >> 1; // Shift right
                counter <= 0;
                if (bit_index == 7)
                    state <= STOP;
                else
                    bit_index <= bit_index + 1;
            end else
                counter <= counter + 1;
        end

        STOP: begin
            tx <= 1'b1;         // Stop bit (high)
            if (counter == BIT_PERIOD - 1) begin
                state <= IDLE;
                tx_done <= 1;  // Pulse done signal
                counter <= 0;
            end else
                counter <= counter + 1;
        end
    endcase
end

endmodule