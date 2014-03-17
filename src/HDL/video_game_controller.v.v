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
`define WALL_POS_Y 8'd0
`define WALL_WIDTH 6'd48

module video_game_controller (
input clock, rst,
input [7:0] game_info_reg ,
input [7:0] randomized_value,				
input [9:0] Pixel_row,
input [9:0] Pixel_column,
output reg [1:0] wall,
output reg collison_detect,
output wire [1:0] icon
);

reg [1:0] bitmap_bot_1 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_2 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_3 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_4 [0:5] [0:5];	// normal image bitmap

reg [1:0] bitmap_tree [0:9] [0:9];	// normal image bitmap

integer i,j,p,q;
reg [9:0] k,k_r;
reg [7:0]cnt;
reg [9:0] locX,locY,WallY, wally_left, wally_right, wally_left_prev, wally_right_prev;
reg [5:0] wall_width, wall_width_r;
reg [31:0] counter;
reg [7:0] randomized_value_f;
reg l_extreme_reached;
reg r_extreme_reached;
reg width_smple;
reg game_completed;
//reg collison_detect;
//reg test;
reg [1:0] icon_actual;

always @(posedge clock) begin
	if(rst) begin
		counter <= 32'd0;
		randomized_value_f <= 8'd0;
		width_smple <= 1'd0;
	end
	else begin
		counter <= counter + 1'd1;
		if(game_info_reg[4] == 1'd1) begin //game level
			if(counter[21:0] == 22'h3F_FFFF) begin
				randomized_value_f <= randomized_value;
			end	
			if(counter[21:0] == 22'h3F_FFFF) begin
				width_smple <= 1'd1;
			end
			else begin
				width_smple <= 1'd0;
			end					
		end
		else begin
			if(counter[22:0] == 23'h7F_FFFF) begin
				randomized_value_f <= randomized_value;
			end	
			if(counter[22:0] == 23'h7F_FFFF) begin
				width_smple <= 1'd1;
			end
			else begin
				width_smple <= 1'd0;
			end	
		end
	end
end

	
always @(*) begin
	for (i=0; i<=5; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
		   //square box
			 bitmap_bot_1[i][j] = 2'b11;
			//triangle
			if(i == 0 && (j==4) )
				bitmap_bot_2[i][j] = 2'b11;
			else if(i == 1 && j==3)
				bitmap_bot_2[i][j] = 2'b11;			
			else if(i == 2 && (j == 2 || j ==1))
				bitmap_bot_2[i][j] = 2'b11;	
			else if(i ==3 && (j == 2 || j == 1))
				bitmap_bot_2[i][j] = 2'b11;			
			else if(i == 4 && (j == 3))
				bitmap_bot_2[i][j] = 2'b11;			
			else if(i == 5 && j == 4)
				bitmap_bot_2[i][j] = 2'b11;			
			else
				bitmap_bot_2[i][j] = 2'b00;
				
			//Bot
			if(i == 0 && (j==3) )
				bitmap_bot_3[i][j] = 2'b11;
			else if(i == 1 && (j==2 || j==3 || j==4 || j==5))
				bitmap_bot_3[i][j] = 2'b11;			
			else if(i == 2 && (j==0|| j==1 || j==2 || j==3))
				bitmap_bot_3[i][j] = 2'b11;	
			else if(i ==3 && (j==0|| j==1 || j==2 || j==3))
				bitmap_bot_3[i][j] = 2'b11;			
			else if(i == 4 && (j==2 || j==3 || j==4 || j==5))
				bitmap_bot_3[i][j] = 2'b11;			
			else if(i == 5 &&(j==3))
				bitmap_bot_3[i][j] = 2'b11;			
			else
				bitmap_bot_3[i][j] = 2'b00;
				
			//Hammer
			if(i == 1 && (j==0 || j==1 || j==2))
				bitmap_bot_4[i][j] = 2'b11;			
			else if(i == 2 )
				bitmap_bot_4[i][j] = 2'b11;	
			else if(i ==3)
				bitmap_bot_4[i][j] = 2'b11;			
			else if(i == 4 && (j==0 || j==1 || j==2))
				bitmap_bot_4[i][j] = 2'b11;						
			else
				bitmap_bot_4[i][j] = 2'b00;			
				
		end
	end	
end

always @ (posedge clock) begin
	if (rst) begin
		icon_actual <= 2'b00;
		locX <= {`BOT_POS_X,2'b00};
		locY <= {`BOT_POS_Y,2'b00};
	end
	else begin
		if(Pixel_row == 10'b0 && Pixel_column == 10'b0) begin
			if(game_info_reg[1:0] == 2'b10) begin // move left
				locX <= locX - 10'd1;
			end
			else if(game_info_reg[1:0] == 2'b01) begin // move right
				locX <= locX + 10'd1;
			end
/*			else if(game_info_reg[1:0] == 2'b11) begin // move right
				test <= 1;
			end */
			else begin // no change
			//	test <= 1;
				locX <= locX;
			end
		end
			
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h5)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h5)) ) begin
			//condition to know whether pixel address matches with that of bot location
			case (game_info_reg[6:5])
				2'b00 : begin 
					if(bitmap_bot_1[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
						else 
							icon_actual <= 2'b11;
					end
					else begin
						icon_actual <= bitmap_bot_1 [5 - Pixel_column + locX][Pixel_row - locY] ;	
					end	
				end
				2'b11 : begin 
					if(bitmap_bot_2[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
						else 
							icon_actual <= 2'b11;
					end
					else begin
						icon_actual <= bitmap_bot_2 [5 - Pixel_column + locX][Pixel_row - locY] ;	
					end	
				end
				2'b10 : begin 
					if(bitmap_bot_3[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
						else 
							icon_actual <= 2'b11;
					end
					else begin
						icon_actual <= bitmap_bot_3 [5 - Pixel_column + locX][Pixel_row - locY] ;	
					end	
				end
				2'b11 : begin 
					if(bitmap_bot_4[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
						else 
							icon_actual <= 2'b11;
					end
					else begin
						icon_actual <= bitmap_bot_4[5 - Pixel_column + locX][Pixel_row - locY] ;	
					end	
				end				
				//2'b01 : icon_actual <= bitmap_bot_2 [5 - Pixel_column + locX][Pixel_row - locY] ;	
				//2'b10 : icon_actual <= bitmap_bot_3 [5 - Pixel_column + locX][Pixel_row - locY] ;	
				//2'b11 : icon_actual <= bitmap_bot_4 [5 - Pixel_column + locX][Pixel_row - locY] ;	
			endcase	
		end
		else begin
			icon_actual <= 2'b00; // transparent
		end
	end
end

always @ (posedge clock) begin
	if (rst) begin
	   k <= 10'd256; 
		wall <= 2'b00;
		WallY <= {`WALL_POS_Y,2'b00};
		wall_width <= `WALL_WIDTH;
		wally_left <= WallY - wall_width + k;
		wally_right <= WallY + wall_width + k;
		wally_left_prev <= WallY - wall_width + k;
		wally_right_prev <= WallY + wall_width + k;
		cnt <= 8'd0;
	end
	else begin
		if(cnt[6:0] == 0 && Pixel_column == 10'd0 && Pixel_row == 10'd0) begin
			if(randomized_value[7:6] == 2'b11 || randomized_value[7:6] == 2'b01) begin		//slowing wall movement to right		
				if(wally_right <= 10'd500 && k <= 10'd500) begin
					k <= k + 10'd8;
				end
			end
			else begin
				if(wally_left >= 10'd100 && k >= 10'd100) begin
					k <= k - 10'd8;
				end	
			end
			
			if( (k%16) == 0) begin
				if(wall_width > 8) begin
					wall_width <= wall_width - 1'd1;
				end
				else begin
					wall_width <= wall_width + 2'd6;
				end
			end
			wally_left <= WallY - wall_width + k;
			wally_right <= WallY + wall_width + k;
			wally_left_prev <= wally_left;
			wally_right_prev <= wally_right;
		end

		if(Pixel_row[9:2] <= cnt) begin
			if((Pixel_column >= wally_left) &&(Pixel_column <= wally_right)) begin
				if((Pixel_column == wally_left) ||(Pixel_column == wally_right)) begin
					wall <= 2'b10;	
				end
				else begin
					wall <= 2'b11;
				end	
			end	
			else begin				
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 15+cnt) && (Pixel_column >= 10) && (Pixel_column <= 15) ) begin
					wall <= 2'b11;
				end
				else
					wall <= 2'b00; // transparent
			end
		end
		else begin
			if((Pixel_column >= wally_left_prev) &&(Pixel_column <= wally_right_prev)) begin
				if((Pixel_column == wally_left_prev) ||(Pixel_column == wally_right_prev)) begin
					wall <= 2'b10;	
				end
				else begin
					wall <= 2'b11;
				end	
			end	
			else begin
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 15+cnt) && (Pixel_column >= 10) && (Pixel_column <= 15) ) begin
					wall <= 2'b11;
				end
				else
					wall <= 2'b00; // transparent
			end		
		end	
		
		if(game_info_reg[4] == 1) begin //Increase game speed
			if(Pixel_column == 10'd0 && Pixel_row[9:3] == 7'd0) begin
				cnt <= cnt + 1'd1;
			end			
		end
		else begin
			if(Pixel_column == 10'd0 && Pixel_row[9:2] == 8'd0) begin
				cnt <= cnt + 1'd1;
			end	
		end
	end	
end

always @ (posedge clock) begin
	if(rst) begin
		collison_detect <= 1'd0;
	end
	else begin
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
			if(wally_left >= locX || wally_right <= (locX + 4'h6)) begin
				collison_detect <= 1'd1;
			end
		end		
	end
end	

/////Game completed -- '1' in game status means stop displaying icon
always @ (posedge clock) begin
	if(rst) begin
		game_completed <= 1'd0;
	end
	else begin
		//game_completed <= game_info_reg[7];
		game_completed <= collison_detect;
	end
end	

assign icon = game_completed ? Pixel_row[1:0] : icon_actual;


//TREE
always @(*) begin
	for (p=0; p<=9; p=p+1) begin
		for (q=0; q<=9; q=q+1) begin
			if(p==0 && (q==5 || q==6))
				bitmap_tree[p][q] = 2'b11;
			else if(p==1 && (q==5 | q==6 | q==7 | q==8 ))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==2 && (q==5 | q==6 | q==7 | q==8 ))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==3 && (q != 4))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==4)
				bitmap_tree[p][q] = 2'b11;			
			else if(p==5)
				bitmap_tree[p][q] = 2'b11;			
			else if(p==6 && (q!=4 ))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==7 && (q==5 | q==6 | q==7))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==8 && (q==5 | q==6 | q==7 ))
				bitmap_tree[p][q] = 2'b11;			
			else if(p==9 && (q==5 | q==6))
				bitmap_tree[p][q] = 2'b11;			
			else
				bitmap_tree[p][q] = 2'b00;				
		end
	end
end	
endmodule
