// sevensegment.v - 4-digit 7-segment display controller
//
// Copyright David Glover, 2012-13, 2014
// 
// Created By:		David Glover
// Last Modified:	31-Dec-2013 (RK)
//
// Revision History:
// -----------------
// Apr-2013		DG		Created this module for the Digilent Nexys 3
// Dec-2013		RK		Cleaned up the formatting.  No functional changes
//
// Description:
// ------------
// This module controls the 4-digit 7-segment display found on
// the Nexys3 FPGA board.  The four digits can be displayed as
// hex digits or as special characters for blanking the digit or
// displaying a single segment.  The decimal points (dots) between
// each digit are also controlled.  The digits are displayed
// according to the following code.	
// 
//   value			Displays
//  0 - 9		Characters 0 to 9
//  10 - 15     Characters A to F
//  16 - 22     Single segments a - g
//  23 			Blank (Off)
//  24 - 28		Uppercase H, R, L and lower case r, l
//  29 - 31     Blank (Off)
//
//	The decimal points are on or off for each digit according to input dp
// 
///////////////////////////////////////////////////////////////////////////
module sevensegment (
	input 				clk,					// 100 MHz system clock 
	input 				reset,					// system reset signal

	input		[4:0]	d0, d1, d2, d3,			// digits to be displayed
	input		[3:0]	dp,						// decimal points to be displayed

	output reg	[7:0]	seg = 8'b11111111,		// output to seven segment display cathode
	output reg	[3:0]	an = 4'b1110,			// output to seven segment display anode
	
	output	reg [31:0]	digits_out = 32'b0		// for simulation only
);

	reg [17:0]		clk_cnt = 18'b0;	
	wire [7:0]		dig0, dig1, dig2, dig3;			// cathode outputs for each digit
	
    parameter simulate = 0;
    localparam clock_cnt = simulate ? 18'd5			// Count when simulating
                                    : 18'd200_000;	// Count when running on HW (500 Hz) 
	localparam digit1 = 4'b1110;
	localparam digit2 = 4'b1101;
	localparam digit3 = 4'b1011;
	localparam digit4 = 4'b0111;
	
	always @ (posedge clk) begin
		if (reset || (clk_cnt == clock_cnt))
			clk_cnt <= 1'b0;
		else 
			clk_cnt <= clk_cnt + 1'b1 ;
	end

	always @ (posedge clk) begin
		if (reset) 
			an <= digit1;
		else if (clk_cnt == clock_cnt)
			case (an)
				digit1: an <= digit2;
				digit2: an <= digit3;
				digit3: an <= digit4;
				digit4: an <= digit1;
				default: an <= digit1;
			endcase
	end

	always @ (posedge clk) begin
		case (an) 
			digit1: seg <= dig0;
			digit2: seg <= dig1;
			digit3: seg <= dig2;
			digit4: seg <= dig3;
			default: seg <= 8'b0;
		endcase
	end
	
Digit Digit0 (
	.clk(clk),
	.d(d0),
	.dp(dp[0]),
	.seg(dig0)
);

Digit Digit1 (
	.clk(clk),
	.d(d1),
	.dp(dp[1]),
	.seg(dig1)
);

Digit Digit2 (
	.clk(clk),
	.d(d2),
	.dp(dp[2]),
	.seg(dig2)
);

Digit Digit3 (
	.clk(clk),
	.d(d3),
	.dp(dp[3]),
	.seg(dig3)
);

endmodule

module Digit (
	input 				clk,
	input 		[4:0]	d,			// digit code to be displayed
	input				dp,			// decimal point to be displayed

	output reg	[7:0]	seg 		// output to seven segment display cathode
);

localparam zero	= 7'b1000000;
localparam one	= 7'b1111001;
localparam two	= 7'b0100100;
localparam three = 7'b0110000;
localparam four = 7'b0011001;
localparam five = 7'b0010010;
localparam six = 7'b0000010;
localparam seven = 7'b1111000;
localparam eight = 7'b0000000;
localparam nine = 7'b0010000;
localparam A = 7'b0001000;
localparam B = 7'b0000011;
localparam C = 7'b1000110;
localparam D = 7'b0100001;
localparam E = 7'b0000110;
localparam F = 7'b0001110;
localparam seg_a = 7'b1111110;
localparam seg_b = 7'b1111101;
localparam seg_c = 7'b1111011;
localparam seg_d = 7'b1110111;
localparam seg_e = 7'b1101111;
localparam seg_f = 7'b1011111;
localparam seg_g = 7'b0111111;

localparam upH = 7'b0001001;
localparam upL = 7'b1000111;
localparam upR = 7'b0001000;
localparam lol = 7'b1001111;
localparam lor = 7'b0101111;

localparam  blank = 7'b1111111;


always @ (posedge clk) begin
	case (d)
		5'd00: seg <= {~dp,zero};
		5'd01: seg <= {~dp,one};
		5'd02: seg <= {~dp,two};
		5'd03: seg <= {~dp,three};
		5'd04: seg <= {~dp,four};
		5'd05: seg <= {~dp,five};
		5'd06: seg <= {~dp,six};
		5'd07: seg <= {~dp,seven};
		5'd08: seg <= {~dp,eight};
		5'd09: seg <= {~dp,nine};
		5'd10: seg <= {~dp,A};
		5'd11: seg <= {~dp,B};
		5'd12: seg <= {~dp,C};
		5'd13: seg <= {~dp,D};
		5'd14: seg <= {~dp,E};
		5'd15: seg <= {~dp,F};
		5'd16: seg <= {~dp,seg_a};
		5'd17: seg <= {~dp,seg_b};
		5'd18: seg <= {~dp,seg_c};
		5'd19: seg <= {~dp,seg_d};
		5'd20: seg <= {~dp,seg_e};
		5'd21: seg <= {~dp,seg_f};
		5'd22: seg <= {~dp,seg_g};
		5'd24: seg <= {~dp,upH};
		5'd25: seg <= {~dp,upL};
		5'd26: seg <= {~dp,upR};
		5'd27: seg <= {~dp,lol};
		5'd28: seg <= {~dp,lor};		
		default: seg <= {~dp,blank};
	endcase
end

endmodule
	
