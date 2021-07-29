// Copyright (c) William Fonkou Tambe
// All rights reserved.

if (rst_i) begin
	gprrdyon <= 0;
	gprrdyrstidx <= {CLOG2GPRCNTTOTAL{1'b1}};
end else if (gprrdyoff) begin
	if (gprrdyrstidx)
		gprrdyrstidx <= gprrdyrstidx - 1'b1;
	else
		gprrdyon <= 1;
end

if (gprwriteenable && gprindex[CLOG2GPRCNTPERCTX -1 : 0] == 13)
	gpr13val <= gprdata;
