module ddr_dram_controller (


/**** 		USER Interface		****/

/* Control signals */
input wire 			  usr_rstn,
input wire 			  uart_clk,
	
input wire 			  usr_write, 
input wire 			  usr_read, 
input wire 			  usr_start,

output    		  axi_bus_busy,
output uart_tx,
/* Data Address bus */
input  wire 		  tx_buf_we,
input  wire  [255:0]  usr_data_in,
input  wire  [31:0]   usr_waddr_in,
input  wire  [7:0]    usr_wd_alen,

input  wire  		  rx_buf_re,
output wire           rx_buf_dvalid,
input  wire  [31:0]   usr_raddr_in,
input  wire  [7:0]    usr_rd_alen,
output reg	 [255:0]  usr_data_out,

output reg 			  usr_wr_done = 0,
output wire  [2:0]    state,
output reg            status = 0,

output  axi_bus_ready,
/**** AXI DDR Interface  ****/
input wire AXI_CLK,

/* Shared Read write address channel */
input  wire DDR_AREADY,
output reg  DDR_AVALID = 0,
output reg  DDR_ATYPE = 0,

output reg [31:0]  DDR_AADR,
output reg  [7:0]  DDR_ALEN,
output      [2:0]  DDR_ASIZE,
output      [1:0]  DDR_ABURST,

/* Write response channel */
output  reg  DDR_BREADY = 0,
input   wire  DDR_BVALID,

/* Read Data Channel */
input  wire [255:0] DDR_RDATA ,
input  wire	        DDR_RLAST ,
output reg    		DDR_RREADY = 0,
input         		DDR_RVALID,

/* Write Data Channel */
input  wire  		DDR_WREADY ,
output reg    		DDR_WLAST =0  ,
output reg    		DDR_WVALID=0 ,
output  [47:0] DDR_WDATA ,
output reg [31:0]  DDR_WSTRB

);

parameter IDLE 		 = 4'd0, //000
		  WRITE_ADDR = 4'd1, //001
		  PRE_WRITE  = 4'd2, //010
		  WRITE      = 4'd3, //011
		  POST_WRITE = 4'd4, //100	  
		  READ_ADDR  = 4'd5, //101
		  PRE_READ   = 4'd6, //110
		  READ   	 = 4'd7, //111
		  DONE 		 = 4'd9; //1001

parameter HIGH = 1'b1, LOW = 1'b0;
reg [3:0] current_state = IDLE,
		  next_state    = IDLE;
parameter WDATA = 1'b0, RDATA = 1'b1;
assign state = current_state;
  //Burst length
assign DDR_ASIZE  = 3'd5; //transfer size
assign DDR_ABURST = 2'd1; //Mode
assign axi_bus_busy = (current_state != IDLE)?LOW:HIGH;

reg [7:0] write_cnt = 0, read_cnt = 0;
reg [23:0]delay = 0;
reg tx_buf_re = LOW;
always@(posedge AXI_CLK)begin
	if(~usr_rstn)begin
		current_state <= IDLE;
	end
	else begin
        current_state <= next_state;
    end
end

wire [47:0] tx_buf_dout;
reg init_read = LOW, init_write = LOW;
// fifo i_fifo
// (
//     .clk       (AXI_CLK),
//     .rst_n     (usr_rstn),

//     .we        (tx_buf_we),
//     .re        (tx_buf_re),
    
//     .occupants (nbytes_written),
// 	.data_in   (usr_data_in),
// 	.data_out  (DDR_WDATA),

//     .empty    (tx_buf_empty),
//     .full     (tx_buf_full)
// );  

assign DDR_WDATA = usr_data_in;
assign axi_bus_ready = tx_buf_re;
reg rx_buf_we = LOW;
// fifo o_fifo
// (
//     .clk       (AXI_CLK),
//     .rst_n     (usr_rstn),

//     .we        (rx_buf_we),
//     .re        (rx_buf_re),
    
//    // .occupants (nbytes_written),
// 	.data_in   (DDR_RDATA),
// 	.data_out  (usr_data_out),

//     .empty    (rx_buf_dvalid)
//   //  .full     (tx_buf_full)
// );  

always @(*)begin
	//status      = LOW; 
	usr_wr_done = LOW; 
		case(current_state)

			IDLE : begin
				if(init_write) next_state = WRITE_ADDR;
				else if(init_read) next_state = READ_ADDR;
				else next_state = IDLE;
			end

			WRITE_ADDR : begin
				if(DDR_AREADY)begin
						next_state = PRE_WRITE;
				end
                else next_state = WRITE_ADDR;
			end

			PRE_WRITE : begin
				next_state = WRITE;
			end

			WRITE : begin
				if(write_done)begin 					 
                     next_state = POST_WRITE;
				end
                else next_state = WRITE;
			end

			POST_WRITE : begin
				if(bvalid_done)begin	
						next_state = DONE;
				end
                else next_state = POST_WRITE;
			end

			READ_ADDR : begin
				if(DDR_AREADY)begin
						next_state = PRE_READ;
				end
                else next_state = READ_ADDR;
			end

			PRE_READ : begin	
				next_state = READ;
			end

			READ : begin
					if(read_done) begin 
						next_state = DONE;
					end
                    else next_state = READ;
			end

			DONE : begin
					usr_wr_done = HIGH;
                    next_state = IDLE;
			end
		endcase
end

reg bvalid_done = LOW;
reg read_done   = LOW;
reg write_done = LOW;
reg fifo_we = 1'b0;

reg fifo_src;
wire [63:0]uart_fifo_din;

assign uart_fifo_din = fifo_src ? DDR_RDATA : DDR_WDATA; 
udg debug_module(
    .clk(uart_clk), 
	.rst(1'b1),
    .fifo_we(fifo_we),
	.data_in(uart_fifo_din),
	.tx(uart_tx)
);

always @ (posedge AXI_CLK )begin
	if(usr_rstn)begin
		case(current_state)
			IDLE : begin
				/* Set all signals to low */
				if(usr_write)begin
					init_write <= HIGH;
					DDR_ALEN <= usr_wd_alen;
					write_cnt <= usr_wd_alen + 1;
					DDR_AADR <= usr_waddr_in;		
				end

				if(usr_read)begin
					init_read <= HIGH;
					DDR_ALEN <= usr_rd_alen;
					read_cnt <= usr_rd_alen + 1;
					DDR_AADR <= usr_raddr_in;
				end

				DDR_WSTRB   <= 32'hFFFFFFFF; //32'b0000000011111111;
				bvalid_done <= LOW;
				DDR_AVALID  <= LOW;
				DDR_ATYPE   <= LOW;
				DDR_WVALID  <= LOW;
				DDR_BREADY  <= LOW;
				DDR_RREADY  <= LOW;
				DDR_WLAST   <= LOW;
				read_done   <= LOW;
				status      <= LOW;
				fifo_we 	<= LOW;
			end

			
			WRITE_ADDR : begin 
				init_read   <= LOW;
				init_write  <= LOW;

				DDR_AVALID  <= HIGH; //assert address valid
				DDR_ATYPE   <= HIGH;  //assert transaction type is write
				tx_buf_re   <= HIGH;
			end
			
			PRE_WRITE : begin
				//de-assert Previously asserted signals
				
				DDR_AVALID <= LOW;
				DDR_ATYPE  <= LOW;
				DDR_WVALID <= HIGH;
				write_cnt  <= write_cnt - 1;
				DDR_BREADY <= HIGH;
				fifo_src   <= WDATA;
				tx_buf_re  <= HIGH;
				//fifo_we <= HIGH;
				
			end

			WRITE : begin
				if(DDR_WREADY == HIGH)begin
					//fifo_we <= HIGH;
					//else tx_buf_re <= LOW;
					if(write_cnt == 8'd0)begin
						write_done <= HIGH;
						DDR_WLAST  <= LOW;
						DDR_WVALID <= LOW;
					end
					else if(write_cnt == 8'd1)begin
						tx_buf_re  <= LOW;
						DDR_WLAST  <= HIGH;
						write_cnt  <= write_cnt - 1;
					end
					else write_cnt <= write_cnt - 1;
				end     
			end	

			POST_WRITE : begin
				fifo_we     <= LOW;
                DDR_WLAST   <= LOW;	
                DDR_WVALID  <= LOW;  
                  
				if(DDR_BVALID)begin //Wait for BValid                   
					bvalid_done <= HIGH;
					DDR_BREADY  <= LOW;
				end

				if(DDR_WREADY)begin
					DDR_WLAST <= LOW;
					DDR_WVALID <= LOW;
				end
			end

			READ_ADDR : begin
				tx_buf_re <= LOW;
               // fifo_we <= LOW;
				DDR_AVALID <= HIGH;
				DDR_ATYPE <= LOW;
				
			end

			PRE_READ : begin
				DDR_AVALID <= LOW;
				read_cnt <= read_cnt - 1;
			end

			READ : begin      
				DDR_RREADY <= HIGH;
				fifo_src <= RDATA;
				usr_data_out <= DDR_RDATA;
				if(read_cnt != 0)begin
					
					if(DDR_RVALID)begin	
						fifo_we      <= HIGH;	
						rx_buf_we    <= HIGH;	 						                   
						read_cnt     <= read_cnt - 1;
					end
				end

				if(read_cnt == 0)begin
					if(DDR_RVALID)begin
						read_done    <= HIGH;
					end
				end
				// if(DDR_RVALID)begin
				// 	fifo_we <= HIGH;
				// end
			end	

			DONE : begin
				usr_data_out <= 0;
				rx_buf_we   <= LOW;
				init_read   <= LOW;
				init_write  <= LOW;
				bvalid_done <= LOW;
				DDR_AVALID  <= LOW;
				DDR_ATYPE   <= LOW;
				DDR_WVALID  <= LOW;
				DDR_BREADY  <= LOW;
				DDR_RREADY  <= LOW;
				DDR_WLAST   <= LOW;
				read_done   <= LOW;
                write_done  <= LOW;
				read_cnt    <= 0;
                fifo_we <= LOW;
			end
	endcase
	end
end

endmodule
