// SPDX-License-Identifier: GPL-2.0-only
// (c) William Fonkou Tambe

if (rst_i) begin

	opldmemrqst <= 0;
	oplddone <= 0;

end else if (gprctrlstate == GPRCTRLSTATEOPLD) begin

	oplddone <= 0;

end else begin

	if (opldmemrqst) begin

		if (dcachemasterrdy) begin
			if (opldbyteselect == 4'b1111)
				opldresult <= dcachemasterdato;
			else if (opldbyteselect == 4'b0011)
				opldresult <= {{16{1'b0}}, dcachemasterdato[15:0]};
			else if (opldbyteselect == 4'b1100)
				opldresult <= {{16{1'b0}}, dcachemasterdato[31:16]};
			else if (opldbyteselect == 4'b0001)
				opldresult <= {{24{1'b0}}, dcachemasterdato[7:0]};
			else if (opldbyteselect == 4'b0010)
				opldresult <= {{24{1'b0}}, dcachemasterdato[15:8]};
			else if (opldbyteselect == 4'b0100)
				opldresult <= {{24{1'b0}}, dcachemasterdato[23:16]};
			else if (opldbyteselect == 4'b1000)
				opldresult <= {{24{1'b0}}, dcachemasterdato[31:24]};

			oplddone <= 1;

			opldmemrqst <= 0;
		end

	end else begin

		if (miscrdyandsequencerreadyandgprrdy12 && isopld && dtlb_rdy && (dcachemasterrdy || opldfault)
			`ifdef PUMMU
			`ifdef PUHPTW
			&& opldfault__hptwddone
			`endif
			`endif
			) begin

			if (!opldfault)
				opldmemrqst <= 1;

			opldgpr <= gprindex1;

			opldbyteselect <= dcachemastersel;
		end
	end
end
