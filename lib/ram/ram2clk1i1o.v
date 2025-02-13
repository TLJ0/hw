// SPDX-License-Identifier: GPL-2.0-only
// (c) William Fonkou Tambe

`ifndef RAM2CLK1I1O_V
`define RAM2CLK1I1O_V

`ifdef USE2CLK
`include "lib/ram/bram.v"
`endif

module ram2clk1i1o (
	rst_i, clk_i ,we_i ,addr_i ,i ,o
);

`include "lib/clog2.v"

parameter SZ = 2;
parameter DW = 32;

parameter SRCFILE = "";

input wire rst_i;

`ifdef USE2CLK
input wire [2 -1 : 0] clk_i;
`else
input wire [1 -1 : 0] clk_i;
`endif

input wire we_i;

input wire [clog2(SZ) -1 : 0] addr_i;

input  wire [DW -1 : 0] i;
output wire [DW -1 : 0] o;

`ifdef USE2CLK

bram #(

	 .SZ      (SZ)
	,.DW      (DW)
	,.SRCFILE (SRCFILE)

) bram (

	 .clk0_i  (clk_i[1])   ,.clk1_i  (clk_i[0])
	,.en0_i   (1'b1)       ,.en1_i   (1'b1)
	                       ,.we1_i   (we_i)
	,.addr0_i (addr_i)     ,.addr1_i (addr_i)
	                       ,.i1      (i)
	,.o0      (o)          ,.o1      ()
);

`else

integer idx;

reg [DW -1 : 0] u [SZ -1 : 0];
initial begin
	for (idx = 0; idx < SZ; idx = idx + 1)
		u[idx] = 0;
	if (SRCFILE != "") begin
		$readmemh (SRCFILE, u);
	end
end

assign o = u[addr_i];

always @ (posedge clk_i[0]) begin
	if (we_i)
		u[addr_i] <= i;
end

`endif

endmodule

`endif
