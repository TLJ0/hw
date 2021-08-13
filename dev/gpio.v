// SPDX-License-Identifier: GPL-2.0-only
// (c) Loic Jonathan Tambe

module gpio (

	 rst_i

	,clk_i

	,pi1_op_i
	,pi1_addr_i
	,pi1_data_i
	,pi1_data_o
	,pi1_sel_i
	,pi1_rdy_o
	,pi1_mapsz_o

	,gp_i
	,gp_o
);

`include "lib/clog2.v"
parameter GPIO_COUNT = 1;

parameter ARCHBITSZ = 32;

localparam CLOG2ARCHBITSZBY8 = clog2(ARCHBITSZ/8);
localparam ADDRBITSZ = (ARCHBITSZ-CLOG2ARCHBITSZBY8);

input wire rst_i;

input wire clk_i;

input  wire [2 -1 : 0]             pi1_op_i;
input  wire [ADDRBITSZ -1 : 0]     pi1_addr_i;
input  wire [ARCHBITSZ -1 : 0]     pi1_data_i;
output reg  [ARCHBITSZ -1 : 0]     pi1_data_o = 0;
input  wire [(ARCHBITSZ/8) -1 : 0] pi1_sel_i;
output wire                        pi1_rdy_o;
output wire [ADDRBITSZ -1 : 0]     pi1_mapsz_o;


input  wire [GPIO_COUNT -1 : 0] gp_i;
output reg [GPIO_COUNT -1 : 0] gp_o;

assign pi1_rdy_o = 1;

assign pi1_mapsz_o = 1;

localparam PINOOP = 2'b00;
localparam PIWROP = 2'b01;
localparam PIRDOP = 2'b10;
localparam PIRWOP = 2'b11;

localparam CLOCKCYCLESPERBITLIMIT = (1<<(ARCHBITSZ-2));
localparam CLOG2CLOCKCYCLESPERBITLIMIT = (ARCHBITSZ-2);

always @ (posedge clk_i) begin

	if (rst_i) begin
		gp_o <= 0;
	end else if (pi1_op_i == PIWROP)
		gp_o <= pi1_data_i;

	if (pi1_op_i == PIRDOP) begin
		pi1_data_o <= gp_i;
	end
end

endmodule
