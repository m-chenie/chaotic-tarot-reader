module Top(
    input sysclk,
    input rst_n,
    input pio1,
    output pio2,
    output adc_din,
        output adc_clk,
        output adc_csn,
    input  adc_dout,
    output [1:0] led,
    output pio7,
    output pio8
);

parameter CLK_FREQ = 12_000_000;
   parameter RX_BAUD = 57_600;
    parameter TX_BAUD = 9_600;
    parameter TOTAL_BYTES = 50;
wire [7:0] rx_data;
wire rx_done;
wire [31:0] avg_value;
reg [31:0] Segment_data;
wire avg_done;
wire tx_busy;
reg [7:0] tx_data;
wire CLK1Hz; 
wire clk2Mhz;
reg start;
wire adc_vaild;
assign pio7 = avg_done;
assign pio8 = start;
assign led = tx_state;

localparam  SINGLE_CHAN0  = 2'b10;
localparam  SINGLE_CHAN1  = 2'b11;

reg adc_ready;
wire [11:0] adc_data;

// Clk divder to get the 2Mhz for ADC
clock_div u1( rst_n,sysclk,clk2Mhz);
clock_div u2(rst_n,sysclk,CLK1Hz);

defparam u2.FREQ_OUTPUT = 500;


drv_mcp3202 drv_mcp3202_u0(
    .rstn(rst_n),
    .clk(clk2Mhz),
    .ap_ready(adc_ready),
    .ap_vaild(adc_vaild),
    .mode(SINGLE_CHAN0),
    .data(adc_data),

    .port_din(adc_dout),
    .port_dout(adc_din), //adc_din
    .port_clk(adc_clk),
    .port_cs(adc_csn)
);

// ADC SAMPLING EVENT (FREQ:1HZ)
always @(posedge rst_n, posedge adc_vaild,posedge CLK1Hz) begin
    if(rst_n) begin
        adc_ready <= 1'b0;
        Segment_data <= 32'h0;
    end else begin
        if(adc_vaild) begin
            Segment_data <= adc_data;
            adc_ready <= 1'b0;
        end
        else begin
            adc_ready <= 1'b1;
        end
    end
end
// UART RX Instance (57.6k baud)
UART_RX rx_inst (
    .clk(sysclk),
    .FPGA_RX(pio1),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

// Average Calculator
Processing avg_inst (
    sysclk,
    clk2Mhz,
    rst_n,
    pio1,
    avg_value,
    avg_done
    );

// UART TX Instance (9.6k baud)
UART_TX tx_inst (
    .clk(sysclk),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(pio2),
    .tx_done(tx_busy)
);

//sample for both starts
always @(posedge sysclk) begin
 if (avg_done) begin
 start <= 1'b1;
 end
 else begin
 start <= 0;
 end
 end

//initialize henonmap
//reg [31:0] a;
//reg [31:0] b;
wire Henon_done;
wire [31:0] x_out;
wire [31:0] y_out;

//initial begin
//a = 14;
//b= 3;
//end
//henon_map_q31 q1(clk2Mhz, rst_n, start, avg_value, Segment_data,a,b,x_out,y_out,Henon_done);

henon_prng_top #(
    .TOTAL_ITER(8)
) prng_inst(
    .clk(clk2Mhz),
    .rst(rst_n),
    .start(start),
    .seed_q31(adc_data),
    .fingerprint_mean(avg_value),
    .random_out_x(x_out),
    .random_out_y(y_out),
    .done(Henon_done)
);
    
reg [1:0] henon_count;
// 32-bit Transmission Control
reg [31:0] tx_buffer;
reg [2:0] tx_state;
reg [1:0] byte_count;
reg tx_start;
reg [2:0] tx_state;



localparam TX_IDLE  = 2'b01,
           TX_START = 2'b10,
           TX_WAIT  = 2'b11;



always @(posedge sysclk or posedge rst_n) begin
    if(rst_n) begin
        henon_count <= 0;
        tx_state <= TX_IDLE;
        byte_count <= 0;
        tx_start <= 0;
        tx_data <= 8'h00;
        tx_buffer <= 32'h00000000;
    end 
    else begin
        case(tx_state)
            TX_IDLE: begin
                if(Henon_done & tx_buffer!=x_out) begin
                    tx_buffer <= x_out;
                    tx_state <= TX_START;
                    byte_count <= 0;
                end
            end
            
            TX_START: begin
                case(byte_count)
                    2'b00: tx_data <= tx_buffer[15:8];
                    2'b01: tx_data <= tx_buffer[23:16];
                    2'b10: tx_data <= tx_buffer[31:24];
                endcase
                tx_start <= 1'b1;
                tx_state <= TX_WAIT;
            end
            
            TX_WAIT: begin
                tx_start <= 1'b0;
                if(!tx_busy) begin
                    // Wait for transmission to start
                    tx_state <= TX_WAIT;
                end else begin
                    // Transmission complete
                    if(byte_count == 2'b11) begin
                        tx_state <= TX_IDLE;
                    end else begin
                        byte_count <= byte_count + 1'b1;
                        tx_state <= TX_START;
                    end
                end
            end
        endcase
    end
end



endmodule