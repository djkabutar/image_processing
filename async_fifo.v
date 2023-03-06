`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2023 11:24:07 AM
// Design Name: 
// Module Name: async_fifo
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


module async_fifo (
             wr_clk,
             rd_clk,
             rst_n ,
             data_in,
             we,
             re,
             data_out,
             occupants,
             empty,
             full
);    
 

   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 8;
   parameter RAM_DEPTH = (1 << ADDR_WIDTH);

   input wr_clk;
   input rd_clk;
   input rst_n;
   input we;
   input re;
   input [DATA_WIDTH-1:0] data_in;
   output [ADDR_WIDTH:0] occupants;
   output                 full;
   output                 empty;
   output [DATA_WIDTH-1:0] data_out;
   
   //wire [DATA_WIDTH-1:0]   data_ram;
   reg [ADDR_WIDTH:0]      wr_pointer = 0;
   reg [ADDR_WIDTH:0]      rd_pointer = 0;
   
   reg [ADDR_WIDTH:0] w_occupants = 0;
   reg [ADDR_WIDTH:0] r_occupants = 0; 
   
   reg rd_recvd = 0;
   
   always @ (posedge wr_clk) begin
      if (~rst_n) begin
         wr_pointer <= 0;
         w_occupants <= 0;
      end
      else begin
//         if (we) wr_pointer <= wr_pointer + 1;
         if (we & ~re & (occupants != RAM_DEPTH)) begin
            w_occupants <= occupants + 1;
            wr_pointer <= wr_pointer + 1;
         end
      end
   end 
   
   always @ (posedge rd_clk) begin
      if (~rst_n) begin
         rd_pointer <= 0;
         r_occupants <= 0;
      end
      else begin
//         if (re) rd_pointer <= rd_pointer + 1;
         if (re & ~we & (occupants != 0)) begin
            rd_recvd <= 1;
            rd_pointer <= rd_pointer + 1;
            r_occupants <= occupants - 1;
         end else rd_recvd <= 0;
      end
   end
   
   assign occupants = rd_recvd ? r_occupants : w_occupants;

   // assign data_out = data_ram;
   assign full = (occupants == (RAM_DEPTH-1));
   assign empty = (occupants == 0);
   
memory #(.DATA_WIDTH(DATA_WIDTH),
	 .ADDR_WIDTH(ADDR_WIDTH),
	 .RAM_DEPTH(RAM_DEPTH)) memory_in0 
(
    .wr_clk (wr_clk),
    .rd_clk (rd_clk),
    .wr_rst_n (rst_n),
    .rd_rst_n (rst_n),						    
    .waddr (wr_pointer),
    .wdata (data_in),
    .wr_en (we),
    .rd_en (re),
    .raddr (rd_pointer),
    .rdata (data_out)
);     

endmodule
