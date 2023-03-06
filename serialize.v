`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/22/2023 06:16:06 PM
// Design Name:
// Module Name: serialize
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module serialize (
	input axi_clk,
    input clk,
    input rstn,
    output TxD,
    input send,
    input [255:0] word
);

parameter DATA_WIDTH = 256;
parameter ADDR_WIDTH = 8;
// parameter DATA_WIDTH = 64;
localparam COUNTER = 4'd63;
// localparam COUNTER = 4'hf;

wire [7:0] out_byte;
reg state = 0;
reg TxD_start = 0;
reg [255:0] prev_word = 1;
reg [5:0] cnt;
reg [3:0] nibble_in = 0;
wire TxD_busy;
reg re;
wire [DATA_WIDTH-1:0] data_out;
wire [ADDR_WIDTH-1:0] occupants;
wire empty;
wire full;

async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo (
    .wr_clk(axi_clk),
    .rd_clk(clk),
    .rst_n(rstn),
    .data_in(word),
    .we(send),
    .re(re),
    .data_out(data_out),
    .occupants(occupants),
    .empty(empty),
    .full(full)
);

always @(posedge clk) begin
    case (state)
        0: begin
            TxD_start <= 1'b0;
            state <= 0;
            cnt <= COUNTER;
			if (~empty) begin
				state <= 1;
				re <= 1;
			end
        end

        1: begin
			re <= 0;
            TxD_start <= 1;
            /* prev_word <= word; */
            if (~TxD_busy) begin
                cnt <= cnt - 1;
                if (cnt == 0) begin
                    state <= 0;
                end
                else
                    /* nibble_in <= word[(cnt * 4) - 1 -: 4]; */
                   	nibble_in <= data_out[(cnt * 4) - 1 -: 4];
            end
        end

        default: begin
            state <= 0;
        end
    endcase
end

binascii b2a(.binary(nibble_in), .ASCII_HEX(out_byte));

uart_tx serializer(.i_Rst_L(rstn), .i_Clock(clk), .i_TX_DV(TxD_start),
    .i_TX_Byte(out_byte), .o_TX_Serial(TxD),
    .o_TX_Active(TxD_busy), .o_TX_Done());
endmodule

