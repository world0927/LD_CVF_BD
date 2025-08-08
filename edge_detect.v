`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        ACT BRAIN
// Engineer:       Y.Yamaguchi
// 
// Create Date: 
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

// Template
/*
edge_detect edge_detect (
								// Input
								.i_clk (),
								.i_rst (),
								.i_sig (),
								
								// Output
								.o_up1 (),   // rise edge 1clock delay
								.o_up2 (),   // rise edge 2clock delay
								.o_dn1 (),   // fall edge 1clock delay
								.o_dn2 ()    // fall edge 2clock delay
								);
*/

module edge_detect (
						// Input
						i_clk,
						i_rst,
						i_sig,
						
						// Output
						o_up1,
						o_up2,
						o_dn1,
						o_dn2
						);
						
	// Input
	input       i_clk;
	input       i_rst;
	input       i_sig;
	
	// Output
	output      o_up1;
	output      o_up2;
	output      o_dn1;
	output      o_dn2;
	
	// Reg
	reg         sig_en1;
	reg         sig_en2;
	reg         sig_en3;
	
	
	always @(posedge i_clk or negedge i_rst)
		begin
			if (~i_rst)
				begin
					sig_en1 <= 1'b0;
					sig_en2 <= 1'b0;
					sig_en3 <= 1'b0;
				end
			else
				begin
					sig_en1 <= i_sig;
					sig_en2 <= sig_en1;
					sig_en3 <= sig_en2;
				end
		end
		
	// rise edge detect
	assign o_up1 = sig_en1 & !sig_en2;   // 1clock delay
	assign o_up2 = sig_en2 & !sig_en3;   // 2clock delay
	
	// fall edge detect
	assign o_dn1 = !sig_en1 & sig_en2;   // 1clock delay
	assign o_dn2 = !sig_en2 & sig_en3;   // 2clock delay
	

endmodule

