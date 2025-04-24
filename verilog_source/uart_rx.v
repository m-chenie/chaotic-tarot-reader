module UART_RX(
    input clk,          // 12 MHz system clock
    input FPGA_RX,      // Asynchronous UART input
    output reg [7:0] rx_data,
    output reg rx_done
);

// Parameters for 12 MHz clock and 9600 baud
parameter CLK_FREQ = 12_000_000;   // 12 MHz
parameter BAUD_RATE = 57600;
parameter SAMPLING_COUNT = CLK_FREQ / BAUD_RATE;  // cycles/bit

// States
reg [1:0] state;
localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

// Synchronization and sampling registers
reg [1:0] sync_reg;     // Metastability protection
reg rx_sync;            // Synchronized RX signal
reg [10:0] counter;     // 11-bit counter (needs to count up to 1250)
reg [2:0] bit_index;    // 3-bit counter for 8 data bits

// Initialize
initial begin
    state = IDLE;
    rx_done = 0;
    rx_data = 0;
    sync_reg = 2'b11;   // Default to idle state (high)
    rx_sync = 1;
    counter = 0;
    bit_index = 0;
end

// Synchronize FPGA_RX to clk (avoid metastability)
always @(posedge clk) begin
    sync_reg <= {sync_reg[0], FPGA_RX};  // Shift in RX signal
    rx_sync <= sync_reg[1];              // Stable synchronized value
end

// State Machine
always @(posedge clk) begin
    case (state)
        IDLE: begin
            rx_done <= 0;       // Reset done flag
            if (!rx_sync) begin // Start bit detected (falling edge)
                state <= START;
                counter <= 0;   // Reset counter for start bit
            end
        end
        
        START: begin
            // Wait until middle of start bit (1250/2 = 625 cycles)
            if (counter == (SAMPLING_COUNT/2)-1) begin    // 625-1 (0-based counting)
                if (!rx_sync) begin      // Confirm valid start bit
                    state <= DATA;
                    counter <= 0;
                    bit_index <= 0;
                end else
                    state <= IDLE;       // False start, return to idle
            end else
                counter <= counter + 1;
        end
        
        DATA: begin
            // Sample data bits at middle of each bit period (1250 cycles)
            if (counter == SAMPLING_COUNT -1) begin   // 1250-1 (0-based)
                rx_data[bit_index] <= rx_sync;  // LSB first (bit_index 0 = LSB)
                counter <= 0;
                if (bit_index == 7)      // After 8 bits, move to STOP
                    state <= STOP;
                else
                    bit_index <= bit_index + 1;
            end else
                counter <= counter + 1;
        end
        
        STOP: begin
            // Wait for middle of stop bit (optional: verify it's high)
            if (counter == (SAMPLING_COUNT/2)-1) begin   // Sample middle of stop bit
                rx_done <= 1;           // Pulse done signal
                state <= IDLE;          // Return to idle
                // Optional: Check if rx_sync == 1 here for framing error
            end else
                counter <= counter + 1;
        end
    endcase
end

endmodule