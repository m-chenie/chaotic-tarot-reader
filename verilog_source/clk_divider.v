module clock_div(
    input rstn,
    input clksrc,
    output clkout
);

parameter FREQ_INPUT  = 12_000_000;
parameter FREQ_OUTPUT = 2_000_000;
parameter CNTER_MAX = FREQ_INPUT/(FREQ_OUTPUT*2);
parameter CNTER_WIDTH = $clog2(CNTER_MAX);

reg clkout_r;
reg [CNTER_WIDTH-1:0] cnter;
assign clkout = clkout_r;

always @(posedge rstn,posedge clksrc) begin
    if(rstn)begin
        cnter <= {CNTER_WIDTH{1'b0}};
        clkout_r <= 1'b0;
    end
    else begin
        if(cnter == CNTER_MAX - 1'b1)begin
            clkout_r <= ~clkout_r;
            cnter <= {CNTER_WIDTH{1'b0}};
        end
        else begin
            cnter <= cnter + 1'b1;
        end
    end
end

endmodule
