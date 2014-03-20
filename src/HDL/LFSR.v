`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author:			Tunnel Vision Project Team
//  
// Create Date:    03/14/2014 
// Module Name:    lfsr 
// Project Name: 	Tunnel Vision
//
// Description: 
//	This module generates a random 8-bit number
//
//	 Inputs:
//			clock           - 25MHz Clock
//			rst             - Active-high synchronous reset
//	 Outputs:
//			randomized_value- 8-bit random number as output.
//
//////////////////////////////////////////////////////////////////////////////////
module lfsr(
	input clock,rst,
	output reg[7:0]randomized_value
    );
	 
reg [7:0]q;

wire feedback = randomized_value[7] ^ randomized_value[5] ^ randomized_value[4] ^ randomized_value[3];	//xor of 3rd, 4th, 5th and 7th bits

always @(posedge clock or posedge rst)
begin
	if (rst==1)
		begin
			q <= 8'hf;	//Initially all outputs are 1's
			randomized_value <= q;	//output is assigned to q
		end
	else
		begin
			q <= {randomized_value[6:0],feedback};	//xored output is fed back as input.
			randomized_value <= q;	//output generates a random number on each clock cycle
		end
end	

endmodule
