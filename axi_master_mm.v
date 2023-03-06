`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/16/2023 09:28:12 AM
// Design Name:
// Module Name: axi_master_mm
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


module axi_master_wr_mm #(
	parameter ASIZE = 3'h3,
	parameter ALEN = 8'hFF
) (
	input axi_clk,
	input rstn,
	input start,
	output reg fifo_re = 0,
	input [63:0] data,

	output [7:0] aid,
	output reg [31:0] aaddr,
	output reg [7:0] alen,
	output reg [2:0] asize,
	output reg [1:0] aburst,
	output reg [1:0] alock,
	output reg avalid,
	input aready,
	output reg atype,

	output reg [3:0] state = 0,

	output [7:0] wid,
	output reg [((1 << ASIZE)*8)-1:0] wdata,
	output  [(1 << ASIZE)-1:0] wstrb,
	output reg wlast,
	output reg wvalid,
	input wready,

	input [7:0] rid,
	input [255:0] rdata,
	input rlast,
	input rvalid,
	output reg rready,
	input [1:0] rresp,

	input [7:0] bid,
	input bvalid,
	output reg bready
);

localparam
IDLE = 4'd0,
	SEND_ADDRESS = 4'd1,
	SEND_PRE_WRITE = 4'd2,
	SEND_WRITE = 4'd3,
	RECV_RESPONSE = 4'd4,
	SEND_READ_ADDR = 4'd5,
	SEND_PRE_READ = 4'd6,
	SEND_READ = 4'd7;


assign wstrb = 32'hFFFFFFFF;

//reg [3:0] state;
reg [7:0] cnt;
reg [3:0] next_state;
reg write_done = 0;
reg read_done = 0;

always @* begin
	case (state)
		IDLE: begin
			if (start) begin
				next_state = SEND_ADDRESS;
			end
		end
		SEND_ADDRESS: begin
			if (aready) begin
				next_state = SEND_PRE_WRITE;
			end
		end
		SEND_PRE_WRITE: begin
			next_state = SEND_WRITE;
		end
		SEND_WRITE: begin
			if (write_done) begin
				next_state = RECV_RESPONSE;
			end
		end
		RECV_RESPONSE: begin
			if (bvalid) begin
				next_state = SEND_READ_ADDR;
			end
		end
		SEND_READ_ADDR: begin
			if (aready) begin
				next_state = SEND_PRE_READ;
			end
		end
		SEND_PRE_READ: begin
			next_state = SEND_READ;
		end
		SEND_READ: begin
			if (read_done) begin
				next_state = IDLE;
			end
		end
		default: begin
			next_state = IDLE;
		end
	endcase
end

always @(posedge axi_clk) begin
	if (~rstn) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always @(posedge axi_clk) begin
	case (state)
		IDLE: begin
			aaddr <= 32'h00000000;
			alen <= 8'h00;
			asize <= 3'h000;
			aburst <= 2'h00;
			alock <= 2'h00;
			avalid <= 1'b0;
			atype <= 1'b0;
			write_done <= 0;
			read_done <= 0;

			wdata <= 256'h00000000;
			// wstrb <= 32'h00000000;
			wlast <= 1'b0;
			wvalid <= 1'b0;

			// rready <= 1'b0;

			bready <= 1'b0;
		end

		SEND_ADDRESS: begin
			aaddr <= 32'h00000000;
			alen <= ALEN;
			asize <= ASIZE;
			aburst <= 2'h01;
			alock <= 2'h00;
			avalid <= 1'b1;
			atype <= 1'b1;
			cnt <= ALEN;
		end

		SEND_PRE_WRITE: begin
			fifo_re <= 1;
			wdata <= data;
			avalid <= 1'b0;
			atype <= 1'b0;
			wlast <= 1'b0;
			wvalid <= 1'b1;
			bready <= 1'b1;
		end

		SEND_WRITE: begin
			if (wready) begin
				fifo_re <= 1;
				wdata <= data;
				cnt <= cnt - 1;

				if (cnt == 1) begin
					wlast <= 1'b1;
				end

				if (cnt == 0) begin
					write_done <= 1'b1;
					wvalid <= 1'b0;
					wlast <= 1'b0;
				end
			end
			/*else begin
			fifo_re <= 0;
			wvalid <= 1'b1;
			// wdata <= mipi_data;

			if (cnt == 0) begin
				wlast <= 1'b1;
			end
		end*/
   end

   RECV_RESPONSE: begin
	   write_done <= 1'b0;
	   wvalid <= 1'b0;
	   fifo_re <= 0;
   end

   SEND_READ_ADDR: begin
	   aaddr <= 32'h00000000;
	   alen <= ALEN;
	   asize <= ASIZE;
	   bready <= 1'b0;
	   aburst <= 2'h01;
	   alock <= 2'h00;
	   avalid <= 1'b1;
	   atype <= 1'b0;
	   cnt <= ALEN;
   end

   SEND_PRE_READ: begin
	   rready <= 1;
	   avalid <= 0;
   end

   SEND_READ: begin
	   /* if (rvalid & (rresp == 0)) begin */
	   if (rvalid) begin

		   // data <= rdata;
		   cnt <= cnt - 1;

		   if (rlast | (cnt == 0)) begin
			   rready <= 1'b0;
			   read_done <= 1'b1;
		   end
	   end
   end

   endcase
end

endmodule

module axi_master_rd_mm (
	input axi_clk,
	input rstn,
	input start,

	output [7:0] aid,
	output reg [31:0] aaddr,
	output reg [7:0] alen,
	output reg [2:0] asize,
	output reg [1:0] aburst,
	output reg [1:0] alock,
	output reg avalid,
	input aready,
	output reg atype,

	output reg [3:0] state = 0,
	output reg [((1 << ASIZE)*8)-1:0] data = 0,

	//    output [7:0] wid,
	//    output reg [((1 << ASIZE)*8)-1:0] wdata,
	//    output  [(1 << ASIZE)-1:0] wstrb,
	//    output reg wlast,
	//    output reg wvalid,
	//    input wready,

	input [7:0] rid,
	input [((1 << ASIZE)*8)-1:0] rdata,
	input rlast,
	input rvalid,
	output reg rready,
	input [1:0] rresp
);

parameter ASIZE = 3'h3;
parameter ALEN = 8'hFF;

localparam
IDLE = 4'd0,
	SEND_ADDRESS = 4'd1,
	SEND_PRE_READ = 4'd2,
	SEND_READ = 4'd3;

assign wstrb = 8'hFF;

//reg [3:0] state;
reg [7:0] cnt;

always @(posedge axi_clk) begin
	if (~rstn) begin
		aaddr <= 32'h00000000;
		alen <= 8'h00;
		asize <= 3'h000;
		aburst <= 2'h00;
		alock <= 2'h00;
		avalid <= 1'b0;
		atype <= 1'b0;
		// wstrb <= 32'h00000000;
		rready <= 1'b0;

		// rready <= 1'b0;
	end else begin
		case (state)
			IDLE: begin
				aaddr <= 32'h00000000;
				alen <= 8'h00;
				asize <= 3'h000;
				aburst <= 2'h00;
				alock <= 2'h00;
				avalid <= 1'b0;
				atype <= 1'b0;

				//                wdata <= 256'h00000000;
				//                // wstrb <= 32'h00000000;
				//                wlast <= 1'b0;
				//                wvalid <= 1'b0;

				rready <= 1'b0;

				if (start) begin
					state <= SEND_ADDRESS;
				end
			end

			SEND_ADDRESS: begin
				aaddr <= 32'h00000000;
				alen <= ALEN;
				asize <= ASIZE;
				aburst <= 2'h01;
				alock <= 2'h00;
				avalid <= 1'b1;
				atype <= 1'b0;
				if (aready) begin
					cnt <= ALEN;
					state <= SEND_PRE_READ;
					avalid <= 1'b0;
					// atype <= 1'b0;
				end
			end

			SEND_PRE_READ: begin
				rready <= 1;
				state <= SEND_READ;
			end

			SEND_READ: begin
				if (rvalid & (rresp == 0)) begin
					data <= rdata;
					cnt <= cnt - 1;

					if (rlast) begin
						rready <= 1'b0;
						state <= IDLE;
					end
				end
			end

			default: begin
				state <= IDLE;
			end
		endcase
	end
end

endmodule
