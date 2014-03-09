// Icon Module for Rojobot World Video Controller
//
//	Author:			Bhavana & Erik
//	Last Modified:	3-Feb-2014
//	
//	 Revision History
//	 ----------------
//	 25-Jan-14		Added the Icon Module
//	 27-Jan-2014	Modified the orientation equations
//	 3-Feb-2014		Added comments for better understanding.
//
//	Description:
//	------------
//	 This module stores the 16x16 image of the Rojobot 
//	 and outputs correct orientation of bot based on Botinfo_reg.
//	 The modules outputs bot icon only when the bot location matches with that of pixel address.
//
//	
//	 Inputs:
//			clock           - 25MHz Clock
//			rst             - Active-high synchronous reset
//			LocX_reg		- X-coordinate of rojobot's location		
//			LocY_reg		- Y-coordinate of rojobot's location
//			BotInfo_reg		- Information about rojobot's activity
//			Pixel_row		- (10 bits) current pixel row address
//			Pixel_column	- (10 bits) current pixel column address
//			
//	 Outputs:
//			icon			-  pixel showing bot location and orientation
//			
//////////

`define BOT_POS_X 8'd64
`define BOT_POS_Y 8'd64
`define WALL_POS_Y 8'd75
`define WALL_WIDTH 5'd16;

module video_game_controller (
input clock, rst,
input [7:0] game_info_reg,				
input [9:0] Pixel_row,
input [9:0] Pixel_column,
output reg [1:0] wall,
output reg [1:0] icon
);

reg [1:0] bitmap_bot_1 [0:5] [0:5];	// normal image bitmap

integer i,j;
reg [9:0] locX,locY,WallY;
reg [4:0] wall_width;

always @(*) begin
	for (i=0; i<=5; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
		    //square box
			   bitmap_bot_1[i][j] = 2'b11;
		end
	end
end

always @ (posedge clock) begin
	if (rst) begin
		icon <= 2'b00;
		locX <= {`BOT_POS_X,2'b00};
		locY <= {`BOT_POS_Y,2'b00};
	end
	else begin
		if(Pixel_row == 10'b0 && Pixel_column == 10'b0) begin
			if(game_info_reg[0]) begin // move left
				locX <= locX - 10'd1;
			end
			else begin
				locX <= locX + 10'd1;
			end
		end
			
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
			//condition to know whether pixel address matches with that of bot location
			icon <= bitmap_bot_1 [Pixel_row - locY] [Pixel_column - locX];	//0 Degree
		end
		else begin
			icon <= 2'b00; // transparent
		end
	end
end

always @ (posedge clock) begin
	if (rst) begin
		wall <= 2'b00;
		WallY <= {`BOT_POS_Y,2'b00};
		wall_width <= `WALL_WIDTH;
	end
	else begin
/*	
		if(Pixel_column[4:0] == 5'b0) begin
			if(game_info_reg[2:1] == 2'b10) begin
				WallY <= WallY - 10'd1;
			end
			else if(game_info_reg[2:1] == 2'b01) begin
				WallY <= WallY + 10'd1;
			end
			else if(game_info_reg[2:1] == 2'b11) begin
				WallY <= WallY;
			end			
			else begin
				WallY <= WallY;
			end
		end
*/		
		if ((Pixel_column == WallY) ||(Pixel_column == (WallY-wall_width))) begin
		//if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
			//condition to know whether pixel address matches with that of bot location
			wall <= 2'b10;	//0 Degree
		end
		else begin
			wall <= 2'b00; // transparent
		end
	end
end	

endmodule