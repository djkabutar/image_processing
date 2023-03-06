`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2023 11:23:16 AM
// Design Name: 
// Module Name: memory
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


module memory
    ( 
      wr_clk,  
      wr_rst_n,  
      rd_clk,  
      rd_rst_n,  
      wdata,  
      waddr,  
      raddr,  
      wr_en,
      rd_en,
      rdata 	 
     );

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 2;
parameter RAM_DEPTH = 4;

input wr_rst_n; 
input wr_clk; 
input rd_rst_n; 
input rd_clk; 

input [DATA_WIDTH-1:0] wdata; 
input [ADDR_WIDTH-1:0] waddr; 
input [ADDR_WIDTH-1:0] raddr; 
input wr_en;
input rd_en;

output [DATA_WIDTH-1:0] rdata; 
reg [DATA_WIDTH-1:0] mem [RAM_DEPTH-1:0];

reg [DATA_WIDTH-1:0] rdata; 


always @(posedge rd_clk)
  if(rd_en)
    rdata <= mem [raddr];

always @(posedge wr_clk)
  if(wr_en)  
    mem[waddr] <= wdata;  
         
   
endmodule
