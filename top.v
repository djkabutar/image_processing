`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/18/2023 11:51:31 AM
// Design Name:
// Module Name: top
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


module top(
    input axi_clk,
    input mipi_rx_cal_clk,
    input rstn,
    input rx_pixel_clk,

    output led0,
    output led1,
    output led2,
    output led3,

    // AXI - 0 Pins
    output [7:0] aid_0,
    output [31:0] aaddr_0,
    output [7:0] alen_0,
    output [2:0] asize_0,
    output [1:0] aburst_0,
    output [1:0] alock_0,
    output avalid_0,
    input aready_0,
    output atype_0,

    output [7:0] wid_0,
    output [255:0] wdata_0,
    output [31:0] wstrb_0,
    output wlast_0,
    output wvalid_0,
    input wready_0,

    input [7:0] rid_0,
    input [255:0] rdata_0,
    input rlast_0,
    input rvalid_0,
    output rready_0,
    input [1:0] rresp_0,

    input [7:0] bid_0,
    input bvalid_0,
    output bready_0,

    // AXI - 1 Pins
    output [7:0] aid_1,
    output [31:0] aaddr_1,
    output [7:0] alen_1,
    output [2:0] asize_1,
    output [1:0] aburst_1,
    output [1:0] alock_1,
    output avalid_1,
    input aready_1,
    output atype_1,

    output [7:0] wid_1,
    output [255:0] wdata_1,
    output [31:0] wstrb_1,
    output wlast_1,
    output wvalid_1,
    input wready_1,

    input [7:0] rid_1,
    input [255:0] rdata_1,
    input rlast_1,
    input rvalid_1,
    output rready_1,
    input [1:0] rresp_1,

    input [7:0] bid_1,
    input bvalid_1,
    output bready_1,

    /* Signals used by the MIPI RX Interface Designer instance */

	output        mipi_rx_DPHY_RSTN,
	output        mipi_rx_RSTN,
	output        mipi_rx_CLEAR,
	output [1:0]  mipi_rx_LANES,
	output [3:0]  mipi_rx_VC_ENA,
	input         mipi_rx_VALID,
	input [3:0]   mipi_rx_HSYNC,
	input [3:0]   mipi_rx_VSYNC,
	input [63:0]  mipi_rx_DATA,
	input [5:0]   mipi_rx_TYPE,
	input [1:0]   mipi_rx_VC,
	input [3:0]   mipi_rx_CNT,
	input [17:0]  mipi_rx_ERROR,
	input         mipi_rx_ULPS_CLK,
	input [3:0]   mipi_rx_ULPS
);

parameter DATA_WIDTH = 64;
parameter ADDR_WIDTH = 16;
parameter RAM_DEPTH = (1 << ADDR_WIDTH);

parameter WR_ASIZE = 8;
parameter WR_SIZE = 1 << WR_ASIZE;
parameter WR_ALEN = 8'hFF;

parameter RD_ASIZE = 7;
parameter RD_SIZE = 1 << RD_ASIZE;
parameter RD_ALEN = 8'hFF;

//reg [63:0] data_in = 0;
wire [(WR_SIZE*8)-1:0] w_wr_data_out;
wire [(RD_SIZE*8)-1:0] w_rd_data_out;
wire uart_clk;

wire [3:0] wr_state;
wire [3:0] rd_state;

wire [DATA_WIDTH-1:0] data_in;
wire [DATA_WIDTH-1:0] data_out;
wire we;
wire re;
wire [ADDR_WIDTH:0] occupants;
wire empty;
wire full;
wire w_tx_done;
//assign w_re = re;
assign w_wr_data_out = data_out;
assign uart_clk = mipi_rx_cal_clk;
//assign uart_clk = rx_pixel_clk;
assign we = 1'b1;

reg [1:0] clk_cnt = 2'b11;
reg [(WR_SIZE*8)-1:0] r_wr_data;
reg read_clk = 0;

assign mipi_rx_RSTN = rstn;
assign mipi_rx_DPHY_RSTN = rstn;
assign mipi_rx_CLEAR = ~rstn;
assign mipi_rx_LANES = 2'b01;
assign my_mipi_rx_VC_ENA = 4'b0001;

//wire [RAM_DEPTH-1:0] occupants;
//wire empty;
//wire full;

axi_master_wr_mm #(
    .ASIZE(WR_ASIZE),
    .ALEN(WR_ALEN)
) axi_0 (
    .axi_clk(axi_clk),
    .rstn(rstn),
    .start(1'b1),
    .fifo_re(re),
    .data(r_wr_data),

    .aid(aid_0),
    .aaddr(aaddr_0),
    .alen(alen_0),
    .asize(asize_0),
    .aburst(aburst_0),
    .alock(alock_0),
    .avalid(avalid_0),
    .aready(aready_0),
    .atype(atype_0),

    .wid(wid_0),
    .wdata(wdata_0),
    .wstrb(wstrb_0),
    .wlast(wlast_0),
    .wvalid(wvalid_0),
    .wready(wready_0),

    .state(wr_state),

    .rid(rid_0),
    .rdata(rdata_0),
    .rlast(rlast_0),
    .rvalid(rvalid_0),
    .rready(rready_0),
    .rresp(rresp_0),

    .bid(bid_0),
    .bvalid(bvalid_0),
    .bready(bready_0)
);

axi_master_rd_mm #(
    .ASIZE(RD_ASIZE),
    .ALEN(RD_ALEN)
) axi_1 (
    .axi_clk(axi_clk),
    .rstn(rstn),
    .start(1'b1),

    .aid(aid_1),
    .aaddr(aaddr_1),
    .alen(alen_1),
    .asize(asize_1),
    .aburst(aburst_1),
    .alock(alock_1),
    .avalid(avalid_1),
    .aready(aready_1),
    .atype(atype_1),

    /*.wid(wid_1),
    .wdata(wdata_1),
    .wstrb(wstrb_1),
    .wlast(wlast_1),
    .wvalid(wvalid_1),
    .wready(wready_1),*/

    .state(rd_state),
    .data(w_rd_data_out),

    .rid(rid_1),
    .rdata(rdata_1),
    .rlast(rlast_1),
    .rvalid(rvalid_1),
    .rready(rready_1),
    .rresp(rresp_1)
);

async_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fifo (
    .wr_clk(rx_pixel_clk),
    .rd_clk(axi_clk),
    .rst_n(rstn),
    .data_in(data_in),
    .we(we),
    .re(re),
    .data_out(data_out),
    .occupants(occupants),
    .empty(empty),
    .full(full)
);

always @(posedge uart_clk) begin
    r_wr_data <= (r_wr_data << 128) | data_out;
end

serialize s1 (
	.axi_clk(axi_clk),
    .clk(uart_clk),
    .rstn(rstn),
    .TxD(led0),
    .send(rvalid_0),
    .word(rdata_0)
	/* .word(w_rd_data_out) */
);

uart_tx #(.CLKS_PER_BIT(50)) t2 (
    .i_Rst_L(rstn),
    .i_Clock(uart_clk),
    .i_TX_DV(1'b1),
    .i_TX_Byte(wr_state),
    .o_TX_Active(),
    .o_TX_Serial(led3),
    .o_TX_Done(w_tx_done)
);

assign led1 = aready_0;
assign led2 = rvalid_0;

data_generator #(.SIZE(WR_SIZE)) dg1 (
    .clk(rx_pixel_clk),
    //.clk(uart_clk),
    .we(we),
    //.we(w_tx_done),
    .data_out(data_in)
);

endmodule
