module UART_TX(
        input clk,
        output FPGA_TX,
        input [7:0]rx_data,
        output reg tx_done
    );
    
     // processing data
 reg state;
 reg [3:0] counter;
 initial begin
 state = 0;
 rx_done =0;
 rx_data =0;
 end
 always@(posedge clk) begin
 if (state == 0 & FPGA_RX==0) begin
 state = 1;
 rx_done = 0;
 end
 else if(state == 1 & counter == 8) begin
 rx_done = 1;
 state = 0;
 counter = 0;
 end
 else if(state == 1) begin
 counter <= counter + 1;
 rx_data <= {FPGA_RX, rx_data[7:1]};
 end
 end
 
 endmodule