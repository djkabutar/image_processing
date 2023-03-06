`timescale 1ns / 1ps

module data_generator #(
    parameter SIZE = 128
) (
    input clk,
    input we,
    
    output reg [SIZE-1:0] data_out
);

always @(posedge clk) begin
    if (we)
        data_out <= data_out + 1;
end

endmodule