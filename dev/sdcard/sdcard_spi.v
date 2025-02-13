// SPDX-License-Identifier: GPL-2.0-only
// (c) William Fonkou Tambe

`include "lib/ram/ram2clk1i1o.v"

`include "./sdcard_spi_phy.v"

`include "lib/perint/pi1q.v"

module sdcard_spi (

	 rst_i

	,clk_mem_i
	,clk_i
	,clk_phy_i

	,sclk_o
	,di_o
	,do_i
	,cs_o

	,pi1_op_i
	,pi1_addr_i
	,pi1_data_i
	,pi1_data_o
	,pi1_sel_i
	,pi1_rdy_o
	,pi1_mapsz_o

	,intrqst_o
	,intrdy_i
);

`include "lib/clog2.v"

parameter PHYCLKFREQ = 1;

parameter ARCHBITSZ = 32;

localparam PHYBLKSZ = 512;

localparam CLOG2ARCHBITSZBY8 = clog2(ARCHBITSZ/8);
localparam ADDRBITSZ = (ARCHBITSZ-CLOG2ARCHBITSZBY8);

input wire rst_i;

`ifdef USE2CLK
input wire [2 -1 : 0] clk_mem_i;
input wire [2 -1 : 0] clk_i;
input wire [2 -1 : 0] clk_phy_i;
`else
input wire [1 -1 : 0] clk_mem_i;
input wire [1 -1 : 0] clk_i;
input wire [1 -1 : 0] clk_phy_i;
`endif

output wire sclk_o;
output wire di_o;
input  wire do_i;
output wire cs_o;

input  wire [2 -1 : 0]             pi1_op_i;
input  wire [ADDRBITSZ -1 : 0]     pi1_addr_i;
input  wire [ARCHBITSZ -1 : 0]     pi1_data_i;
output wire [ARCHBITSZ -1 : 0]     pi1_data_o;
input  wire [(ARCHBITSZ/8) -1 : 0] pi1_sel_i;
output wire                        pi1_rdy_o;
output wire [ADDRBITSZ -1 : 0]     pi1_mapsz_o;

output reg  intrqst_o = 0;
input  wire intrdy_i;

assign pi1_mapsz_o = (PHYBLKSZ/(ARCHBITSZ/8));

localparam CLOG2PHYBLKSZ = clog2(PHYBLKSZ);

localparam PI1QMASTERCOUNT = 1;
localparam PI1QARCHBITSZ   = ARCHBITSZ;
wire pi1q_rst_w = rst_i;
wire m_pi1q_clk_w = clk_mem_i;
wire s_pi1q_clk_w = clk_i;
`include "lib/perint/inst.pi1q.v"

assign m_pi1q_op_w[0] = pi1_op_i;
assign m_pi1q_addr_w[0] = pi1_addr_i;
assign m_pi1q_data_w1[0] = pi1_data_i;
assign pi1_data_o = m_pi1q_data_w0[0];
assign m_pi1q_sel_w[0] = pi1_sel_i;
assign pi1_rdy_o = m_pi1q_rdy_w[0];

reg [ARCHBITSZ -1 : 0] s_pi1q_data_w1_ = 0;
assign s_pi1q_data_w1 = s_pi1q_data_w1_;

assign s_pi1q_rdy_w = 1;

localparam PINOOP = 2'b00;
localparam PIWROP = 2'b01;
localparam PIRDOP = 2'b10;
localparam PIRWOP = 2'b11;

localparam CMDRESET = 0;
localparam CMDSWAP  = 1;
localparam CMDREAD  = 2;
localparam CMDWRITE = 3;
localparam CMD_CNT  = 4;

localparam STATUSPOWEROFF = 0;
localparam STATUSREADY    = 1;
localparam STATUSBUSY     = 2;
localparam STATUSERROR    = 3;

wire phy_tx_pop_w, phy_rx_push_w;

wire [8 -1 : 0] phy_rx_data_w;
reg  [8 -1 : 0] phy_tx_data_w;

reg phy_cmd = 0;

reg [ADDRBITSZ -1 : 0] phy_cmdaddr = 0;

wire [ADDRBITSZ -1 : 0] phy_blkcnt_w;

wire phy_err_w;

wire phy_rst_w = (rst_i | (s_pi1q_op_w == PIRWOP && s_pi1q_addr_w == CMDRESET && s_pi1q_data_w0));

reg  phy_cmd_pending_a = 0;
reg  phy_cmd_pending_b = 0;
wire phy_cmd_pending = (phy_cmd_pending_a ^ phy_cmd_pending_b);

wire phy_cmd_pop_w;

always @ (posedge clk_phy_i[0]) begin
	if (rst_i || (phy_cmd_pop_w && phy_cmd_pending))
		phy_cmd_pending_b <= phy_cmd_pending_a;
end

wire phy_bsy = (phy_cmd_pending || !phy_cmd_pop_w);

sdcard_spi_phy
#(
	.CLKFREQ (PHYCLKFREQ)
) phy (

	 .rst_i (phy_rst_w)

	,.clk_i (clk_phy_i)

	,.sclk_o (sclk_o)
	,.di_o   (di_o)
	,.do_i   (do_i)
	,.cs_o   (cs_o)

	,.cmd_pop_o      (phy_cmd_pop_w)
	,.cmd_data_i     (phy_cmd)
	,.cmdaddr_data_i (phy_cmdaddr)
	,.cmd_empty_i    (!phy_cmd_pending)

	,.rx_push_o (phy_rx_push_w)
	,.rx_data_o (phy_rx_data_w)

	,.tx_pop_o   (phy_tx_pop_w)
	,.tx_data_i  (phy_tx_data_w)

	,.blkcnt (phy_blkcnt_w)

	,.err (phy_err_w)
);

wire pi1_op_is_rdop = (s_pi1q_op_w == PIRDOP || (s_pi1q_op_w == PIRWOP && s_pi1q_addr_w >= CMD_CNT));
wire pi1_op_is_wrop = (s_pi1q_op_w == PIWROP || (s_pi1q_op_w == PIRWOP && s_pi1q_addr_w >= CMD_CNT));

reg cacheselect = 0;

reg [CLOG2PHYBLKSZ -1 : 0] cachephyaddr = 0;

wire [(CLOG2PHYBLKSZ-CLOG2ARCHBITSZBY8) -1 : 0] cache0addr =
	cacheselect ? s_pi1q_addr_w : cachephyaddr[CLOG2PHYBLKSZ -1 : CLOG2ARCHBITSZBY8];
wire [(CLOG2PHYBLKSZ-CLOG2ARCHBITSZBY8) -1 : 0] cache1addr =
	cacheselect ? cachephyaddr[CLOG2PHYBLKSZ -1 : CLOG2ARCHBITSZBY8] : s_pi1q_addr_w;

wire [ARCHBITSZ -1 : 0] cache0dato;
wire [ARCHBITSZ -1 : 0] cache1dato;

wire [ARCHBITSZ -1 : 0] cachephydata = cacheselect ? cache1dato : cache0dato;

wire [ARCHBITSZ -1 : 0] phy_rx_data_w_byteselected =
	(cachephyaddr[1:0] == 0) ? {cachephydata[31:8], phy_rx_data_w} :
	(cachephyaddr[1:0] == 1) ? {cachephydata[31:16], phy_rx_data_w, cachephydata[7:0]} :
	(cachephyaddr[1:0] == 2) ? {cachephydata[31:24], phy_rx_data_w, cachephydata[15:0]} :
	                           {phy_rx_data_w, cachephydata[23:0]};

wire [ARCHBITSZ -1 : 0] cache0dati = cacheselect ? s_pi1q_data_w0 : phy_rx_data_w_byteselected;
wire [ARCHBITSZ -1 : 0] cache1dati = cacheselect ? phy_rx_data_w_byteselected : s_pi1q_data_w0;

always @* begin
	if (cachephyaddr[1:0] == 0)
		phy_tx_data_w = cacheselect ? cache1dato[7:0] : cache0dato[7:0];
	else if (cachephyaddr[1:0] == 1)
		phy_tx_data_w = cacheselect ? cache1dato[15:8] : cache0dato[15:8];
	else if (cachephyaddr[1:0] == 2)
		phy_tx_data_w = cacheselect ? cache1dato[23:16] : cache0dato[23:16];
	else
		phy_tx_data_w = cacheselect ? cache1dato[31:24] : cache0dato[31:24];
end

reg  intrdy_i_sampled = 0;
wire intrdy_i_negedge = (!intrdy_i && intrdy_i_sampled);

reg  phy_err_w_sampled = 0;
wire phy_err_w_posedge = (phy_err_w && !phy_err_w_sampled);

reg  phy_bsy_sampled = 0;
wire phy_bsy_negedge = (!phy_bsy && phy_bsy_sampled);

wire cache0read  = cacheselect ? pi1_op_is_rdop : phy_tx_pop_w;
wire cache1read  = cacheselect ? phy_tx_pop_w : pi1_op_is_rdop;
wire cache0write = cacheselect ? pi1_op_is_wrop : phy_rx_push_w;
wire cache1write = cacheselect ? phy_rx_push_w : pi1_op_is_wrop;

ram2clk1i1o #(

	 .SZ (PHYBLKSZ/(ARCHBITSZ/8))
	,.DW (ARCHBITSZ)

) cache0 (

	 .rst_i (rst_i)

	,.clk_i  (clk_i)
	,.we_i   (cache0write)
	,.addr_i (cache0addr)
	,.i      (cache0dati)
	,.o      (cache0dato)
);

ram2clk1i1o #(

	 .SZ (PHYBLKSZ/(ARCHBITSZ/8))
	,.DW (ARCHBITSZ)

) cache1 (

	  .rst_i (rst_i)

	,.clk_i  (clk_i)
	,.we_i   (cache1write)
	,.addr_i (cache1addr)
	,.i      (cache1dati)
	,.o      (cache1dato)
);

reg [2 -1 : 0] status;

always @* begin
	if (rst_i)
		status = STATUSPOWEROFF;
	else if (phy_err_w)
		status = STATUSERROR;
	else if (phy_rst_w || phy_bsy)
		status = STATUSBUSY;
	else
		status = STATUSREADY;
end

always @ (posedge clk_i[0]) begin

	intrqst_o <= intrqst_o ? ~intrdy_i_negedge : (phy_err_w_posedge || phy_bsy_negedge);

	if (s_pi1q_op_w == PIRWOP && s_pi1q_addr_w == CMDSWAP)
		cacheselect <= ~cacheselect;

	if (pi1_op_is_rdop)
		s_pi1q_data_w1_ <= cacheselect ? cache0dato : cache1dato;
	else if (s_pi1q_op_w == PIRWOP) begin
		if (s_pi1q_addr_w == CMDRESET)
			s_pi1q_data_w1_ <= {{30{1'b0}}, status};
		else if (s_pi1q_addr_w == CMDSWAP)
			s_pi1q_data_w1_ <= PHYBLKSZ;
		else if (s_pi1q_addr_w == CMDREAD || s_pi1q_addr_w == CMDWRITE)
			s_pi1q_data_w1_ <= phy_blkcnt_w;
	end

	if (!phy_bsy)
		cachephyaddr <= 0;
	else if (cacheselect ? (cache1read | cache1write) : (cache0read | cache0write))
		cachephyaddr <= cachephyaddr + 1'b1;

	if (s_pi1q_op_w == PIRWOP && (s_pi1q_addr_w == CMDREAD || s_pi1q_addr_w == CMDWRITE)) begin
		phy_cmd_pending_a <= ((!phy_cmd_pending) ^ phy_cmd_pending_a);
		phy_cmd <= (s_pi1q_addr_w == CMDWRITE);
		phy_cmdaddr <= s_pi1q_data_w0;
	end

	intrdy_i_sampled  <= intrdy_i;
	phy_err_w_sampled <= phy_err_w;
	phy_bsy_sampled   <= phy_bsy;
end

endmodule
