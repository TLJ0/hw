// SPDX-License-Identifier: GPL-2.0-only
// (c) Loic Jonathan Tambe

module pwm (

	 rst_i

	,clk_i

	,pi1_op_i
	,pi1_addr_i
	,pi1_data_i
	,pi1_data_o
	,pi1_sel_i
	,pi1_rdy_o
	,pi1_mapsz_o

	,pwm_i
	,pwm_o
);

`include "lib/clog2.v"
parameter PWM_COUNT = 8;
parameter CLKFREQ = 1;

parameter ARCHBITSZ = 32;

localparam CLOG2ARCHBITSZBY8 = clog2(ARCHBITSZ/8);
localparam ADDRBITSZ = (ARCHBITSZ-CLOG2ARCHBITSZBY8);

parameter CLOG2_PWM_COUNT = clog2(PWM_COUNT);

input wire rst_i;

input wire clk_i;

input  wire [2 -1 : 0]             pi1_op_i;
input  wire [ADDRBITSZ -1 : 0]     pi1_addr_i;
input  wire [ARCHBITSZ -1 : 0]     pi1_data_i;
output reg  [ARCHBITSZ -1 : 0]     pi1_data_o = 0;
input  wire [(ARCHBITSZ/8) -1 : 0] pi1_sel_i;
output wire                        pi1_rdy_o;
output wire [ADDRBITSZ -1 : 0]     pi1_mapsz_o;


input  wire [PWM_COUNT -1 : 0] pwm_i;
output reg [PWM_COUNT -1 : 0] pwm_o;

assign pi1_rdy_o = 1;

assign pi1_mapsz_o = 1;

localparam PINOOP = 2'b00;
localparam PIWROP = 2'b01;
localparam PIRDOP = 2'b10;
localparam PIRWOP = 2'b11;

localparam CMD_SELECT = 2'b00;
localparam CMD_PERIOD = 2'b01;

localparam CLOCKCYCLESPERBITLIMIT = (1<<(ARCHBITSZ-2));
localparam CLOG2CLOCKCYCLESPERBITLIMIT = (ARCHBITSZ-2);

reg [(ARCHBITSZ - 2) -1 : 0] counter [PWM_COUNT -1 : 0];

reg [CLOG2_PWM_COUNT -1 : 0] sel = 0;

reg [(ARCHBITSZ - 2) -1 : 0] period [PWM_COUNT -1 : 0];
reg [(ARCHBITSZ - 2) -1 : 0] duty_cycle [PWM_COUNT -1 : 0];

integer i;

always @ (posedge clk_i) begin

	for(i=0; i<PWM_COUNT; i=i+1) begin
		if (counter[i] < period[i])
			counter[i] <= counter[i] + 1;
		else counter[i] <= 0;
	
		pwm_o[i] <= (counter[i] < duty_cycle[i]) ? 1:0;
	end
	
	if (pi1_op_i == PIRDOP) begin
		pi1_data_o <= pwm_i;
	end else if (pi1_op_i == PIWROP) begin
		pi1_data_o <= CLKFREQ;
	end
	
	if (pi1_op_i == PIRWOP) begin
		if (pi1_data_i[1:0] == CMD_SELECT) begin
			sel <= pi1_data_i[ARCHBITSZ -1 : 2];
		end else if (pi1_data_i[1:0] == CMD_PERIOD) begin
			period[sel] <= pi1_data_i[ARCHBITSZ -1 : 2];
		end
	end
	
	if (pi1_op_i == PIWROP) begin
		duty_cycle[sel] <= pi1_data_i;
	end
	
end

endmodule
