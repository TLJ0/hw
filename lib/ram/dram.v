// SPDX-License-Identifier: GPL-2.0-only
// (c) William Fonkou Tambe

`ifndef DRAM_V
`define DRAM_V

module dram (
	          clk1_i
	         ,we1_i
	,addr0_i ,addr1_i
	         ,i1
	,o0      ,o1
);

`include "lib/clog2.v"

parameter SZ = 2;
parameter DW = 32;

parameter SRCFILE = "";

input wire                  clk1_i;
input wire                  we1_i;
input wire  [clog2(SZ)-1:0] addr0_i;
input wire  [clog2(SZ)-1:0] addr1_i;
input wire  [DW-1:0]        i1;
output wire [DW-1:0]        o0;
output wire [DW-1:0]        o1;

integer idx;

reg [DW-1:0] u [0:SZ-1];
initial begin
	for (idx = 0; idx < SZ; idx = idx + 1)
		u[idx] = 0;
	if (SRCFILE != "") begin
		$readmemh (SRCFILE, u);
	end
end

assign o0 = u[addr0_i];
assign o1 = u[addr1_i];

always @ (posedge clk1_i) begin
	if (we1_i)
		u[addr1_i] <= i1;
end

endmodule

`endif
