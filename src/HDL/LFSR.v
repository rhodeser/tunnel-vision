`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:46:18 03/12/2014 
// Design Name: 
// Module Name:    lfsr 
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
module lfsr(
	//input [7:0]seed,
	input clk,reset,
	//output reg[1:0]out
	output reg[7:0]randomized_value
    );
	 
reg [7:0]q;
//reg [7:0] randomized_value;	 
wire feedback = randomized_value[7] ^ randomized_value[5] ^ randomized_value[4] ^ randomized_value[3];
//wire []randomized_value
always @(posedge clk or posedge reset)
begin
if (reset==1)
	begin
		q <= 4'hf;
		randomized_value <= q;
		//randomized_value <= 4'hf;
	end
else
	begin
		q <= {randomized_value[6:0],feedback};
		randomized_value <= q;
	//	randomized_value <= {randomized_value[6:0],feedback};
	//	randomized_value <= randomized_value[7:6];
	end
end	

endmodule
