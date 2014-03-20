// colorizer Module for Tunnel Vision Project
//
//	Author:			Tunnel Vision Project Team
//	Last Modified:	20-Mar-2014
//	
//	 Revision History
//	 ----------------
//	 7/8 -Mar-2014		Took the colorizer Module from Project1
//	 17-Mar-2014		added green color to the module inorder to ressemble trees on the screen
//
//	Description:
//	------------
//	This module takes the 2-bit pixel inputs from the Bot and Icon modules.	 
//	8-bit output is produced  of which 3 MSB bits  are red, 
//	2 LSB bits are blue and remaining 3 bits are green. 
//	
//	 Inputs:
//			clock           - 25MHz Clock
//			rst             - Active-high synchronous reset
//			video_on        - 1 = in active video area; 0 = blanking;
//			world_pixel     -  pixel (location) value
//			icon			-  pixel showing bot location and orientation
//	 Outputs:
//			red				-	All 3 bits 1's gives red color output
//			green			-	All 3 bits 1's gives green color output
//			blue			-	All 2 bits 1's gives blue color output
//			
//////////
module colorizer (
input clock, rst,
input video_on,
input [1:0] wall,
input [1:0] icon,
output reg [2:0] red,
output reg [2:0] green,
output reg [1:0] blue
);

reg [7:0] out_color;

always @ (*) begin	// assigning out_color to red, green, blue
	red = out_color[7:5];	//MSB 3-bits for red
	green = out_color[4:2];	//remaining 3-bits for green
	blue = out_color[1:0];	//LSB 2-bits for blue
end

always @ (posedge clock) begin
	if (rst) begin
		out_color <= 8'h0;
	end
	else begin
		if (video_on == 0) begin	// when video_on is 0, the screen will be blank
			out_color <= 8'h0;			
		end
		else begin
			if(icon == 2'b10) begin
				out_color <= 8'b000_111_11;		// Cyan color for Icon color 2
			end
			else if (icon == 2'b01) begin
				out_color <= 8'b100_000_00;		// Maroon Color for Icon color 1
			end
			else if(icon == 2'b11) begin
				out_color <= 8'b111_000_11;		// Magenta color for Icon color 3			
			end
			else begin
				case (wall)
					2'b00 : out_color <= 8'b111_111_11;		// white back ground
					2'b01 : out_color <= 8'b000_111_00;		// green line
					2'b10 : out_color <= 8'b111_000_00;		// Dark Red color for Obstruction
					2'b11 : out_color <= 8'b100_100_10;		// Grey for Reserved Area
					default : out_color <= 8'b000_000_00;	
				endcase
			end	
		end
	end
end

endmodule


		



