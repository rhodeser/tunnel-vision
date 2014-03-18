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
input [7:0] db_sw,
input start,
input pause,
input [1:0] bot_ctrl,
input [7:0] game_info_reg ,
input [7:0] randomized_value,				
input [9:0] Pixel_row,
input [9:0] Pixel_column,
output wire [1:0] wall,
output reg collison_detect,
output wire [1:0] icon
);

reg [1:0] bitmap_bot_1 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_2 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_3 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_4 [0:5] [0:5];	// normal image bitmap

reg [1:0] bitmap_bot_begin [0:21] [0:5];
reg [1:0] bitmap_bot_game_over [0:42] [0:5];

reg [1:0] bitmap_bot_car [0:2] [0:3];	
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
reg [1:0] wall_actual;
reg start_sticky;
reg start_r;
reg pause_r;
reg pause_sticky;

always @(posedge clock) begin
	if(rst) begin
		start_r <= 0;
		pause_r <= 0;
		pause_sticky <= 0;
		start_sticky <= 0;
	end
	else begin
		start_r <= start;
		pause_r <= pause;
		if(~start_r & start) begin
			start_sticky <= 1;
			pause_sticky <= 0;
		end
		if(~pause_r & pause) begin
			start_sticky <= 0;
			pause_sticky <= 1;
		end	
	end
end

always @(posedge clock) begin
	if(rst) begin
		counter <= 32'd0;
		width_smple <= 1'd0;
	end
	else begin
		counter <= counter + 1'd1;
		if(game_info_reg[4] == 1'd1) begin //game level
			if(counter[21:0] == 22'h3F_FFFF) begin
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
			 bitmap_bot_1[i][j] = 2'b10;
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
	else if(~start_sticky & ~pause_sticky) begin
		 if ((Pixel_row[9:3] >= 20) && (Pixel_row[9:3] <= 25) && (Pixel_column[9:3] >= 20) && (Pixel_column[9:3] <= 41)) begin
			//icon_actual <= bitmap_bot_begin[22 - Pixel_column[9:3] + 20][Pixel_row[9:3] - 20];	
			icon_actual <= bitmap_bot_begin[Pixel_column[9:3] - 20][Pixel_row[9:3] - 20];	
			
		end	
		else begin
			icon_actual <= 2'b10;
		end	
	end
	else if(game_completed) begin	
		if ((Pixel_row[9:3] >= 20) && (Pixel_row[9:3] <= 25) && (Pixel_column[9:3] >= 10) && (Pixel_column[9:3] <= 52)) begin
			//icon_actual <= bitmap_bot_begin[22 - Pixel_column[9:3] + 20][Pixel_row[9:3] - 20];	
			icon_actual <= bitmap_bot_game_over[Pixel_column[9:3] - 10][Pixel_row[9:3] - 20];				
		end	
		else begin
			icon_actual <= 2'b10;
		end		
	end
	else if(pause_sticky) begin
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h5)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h5)) ) begin
			//condition to know whether pixel address matches with that of bot location
			case (db_sw[3:0])
				4'b0001 : begin 
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
				4'b0010 : begin 
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
				4'b0100 : begin 
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
				4'b1000 : begin 
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
				default : begin 
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
	else begin
		if(Pixel_row == 10'b0 && Pixel_column == 10'b0 && cnt[3:0] == 0) begin
			if(bot_ctrl[1:0] == 2'b10) begin // move left
				locX <= locX - 10'd1;
			end
			else if(bot_ctrl[1:0] == 2'b01) begin // move right
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
			case (db_sw[3:0])
				4'b0001 : begin 
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
				4'b0010 : begin 
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
				4'b0100 : begin 
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
				4'b1000 : begin 
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
				default : begin 
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
		wall_actual <= 2'b00;
		WallY <= {`WALL_POS_Y,2'b00};
		wall_width <= `WALL_WIDTH;
		wally_left <= WallY - wall_width + k;
		wally_right <= WallY + wall_width + k;
		wally_left_prev <= WallY - wall_width + k;
		wally_right_prev <= WallY + wall_width + k;
		cnt <= 8'd0;
		randomized_value_f <= 8'd0;
		collison_detect <= 1'd0;
	end
	else if(~start_sticky & ~pause_sticky) begin
		wall_actual <= 2'b00;
	end
	else if(game_completed) begin
		wall_actual <= 2'b00;	
	end
	else if(pause_sticky) begin
		if(Pixel_row[9:2] <= cnt) begin
			if((Pixel_column >= wally_left) &&(Pixel_column <= wally_right)) begin
				if((Pixel_column == wally_left) ||(Pixel_column == wally_right)) begin
					wall_actual <= 2'b10;	
				end
				else begin
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+4) && (Pixel_column <= wally_left+4+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
						end
						else
							wall_actual <= 2'b11;
					end
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-10) && (Pixel_column <= wally_right-10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
						end
						else
							wall_actual <= 2'b11;
					end
					else
						wall_actual <= 2'b11;
				end	
			end	
			else begin	
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 19) ) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[19 - Pixel_column[9:2] + 10][Pixel_row[9:2] - 10+cnt];
				end
				else
					wall_actual <= 2'b00; // transparent
			end
		end
		else begin
			if((Pixel_column >= wally_left_prev) &&(Pixel_column <= wally_right_prev)) begin
				if((Pixel_column == wally_left_prev) ||(Pixel_column == wally_right_prev)) begin
					wall_actual <= 2'b10;	
				end
				else begin
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+4) && (Pixel_column <= wally_left+4+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
						end
						else
							wall_actual <= 2'b11;
					end
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-10) && (Pixel_column <= wally_right-10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
						end	
						else
							wall_actual <= 2'b11;
					end
					else
						wall_actual <= 2'b11;
				end	
			end	
			else begin
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 19) ) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[19 - Pixel_column[9:2] + 10][Pixel_row[9:2] - 10+cnt];
				end
				else
					wall_actual <= 2'b00; // transparent
			end		
		end		
	end
	//PAUSE LOGIC COMPLETED
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
			randomized_value_f <= randomized_value;
		end

		if(Pixel_row[9:2] <= cnt) begin
			if((Pixel_column >= wally_left) &&(Pixel_column <= wally_right)) begin
				if((Pixel_column == wally_left) ||(Pixel_column == wally_right)) begin
					wall_actual <= 2'b10;	
				end
				else begin
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+4) && (Pixel_column <= wally_left+4+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
								collison_detect <= 1'd1;
							end		
							///////								
						end
						else
							wall_actual <= 2'b11;
					end
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-10) && (Pixel_column <= wally_right-10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
								collison_detect <= 1'd1;
							end		
							///////								
						end
						else
							wall_actual <= 2'b11;
					end
					else
						wall_actual <= 2'b11;
				end	
			end	
			else begin
			///////
				if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
					collison_detect <= 1'd1;
				end		
			///////
				
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 19) ) begin
					wall_actual <= bitmap_tree[19 - Pixel_column[9:2] + 10][Pixel_row[9:2] - 10+cnt];
				end
				else
					wall_actual <= 2'b00; // transparent
			end
		end
		else begin
			if((Pixel_column >= wally_left_prev) &&(Pixel_column <= wally_right_prev)) begin
				if((Pixel_column == wally_left_prev) ||(Pixel_column == wally_right_prev)) begin
					wall_actual <= 2'b10;	
				end
				else begin
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+4) && (Pixel_column <= wally_left+4+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
								collison_detect <= 1'd1;
							end		
							///////	
						end
						else
							wall_actual <= 2'b11;
					end
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-10) && (Pixel_column <= wally_right-10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
								collison_detect <= 1'd1;
							end		
							///////								
						end				
						else
							wall_actual <= 2'b11;
					end
					else
						wall_actual <= 2'b11;
				end	
			end	
			else begin
			///////
				if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
					collison_detect <= 1'd1;
				end		
			///////			
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 19) ) begin
					wall_actual <= bitmap_tree[19 - Pixel_column[9:2] + 10][Pixel_row[9:2] - 10+cnt];
				end
				else
					wall_actual <= 2'b00; // transparent
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

assign icon = icon_actual;
assign wall = wall_actual;


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

// BEGIN SCREEN
always @(*) begin
	for (i=0; i<=21; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
			//BEGIN SCREEN
			if(i == 0 || i == 2 || i == 4 || i == 8 || i == 14 || i == 17 || i == 21)
				bitmap_bot_begin[i][j] = 2'b11;
			else if(i == 1 && (j == 0 || j ==3 || j ==5))
				bitmap_bot_begin[i][j] = 2'b11;			
			else if(i == 5 && (j == 0 || j == 3 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;	
			else if(i == 6 && (j == 0 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;			
			else if(i == 9 && (j == 0 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;			
			else if(i == 10 && (j == 3 || j == 0 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;				
			else if(i == 11 && (j == 3 || j == 04|| j == 5))
				bitmap_bot_begin[i][j] = 2'b11;								
			else if(i == 13 && (j == 0 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;	
			else if(i == 15 && (j == 0 || j == 5))
				bitmap_bot_begin[i][j] = 2'b11;	
			else if(i == 18 && (j == 1))
				bitmap_bot_begin[i][j] = 2'b11;	
			else if(i == 19 && (j == 2 ))
				bitmap_bot_begin[i][j] = 2'b11;	
			else if(i == 20 && (j == 3))
				bitmap_bot_begin[i][j] = 2'b11;	
			else
				bitmap_bot_begin[i][j] = 2'b00;				
		end
	end	
end

// GAME OVER SCREEN
always @(*) begin
	for (i=0; i<=42; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
			//BEGIN SCREEN
			if(i==0 | i==5 | i==7 | i==9 | i==13 | i==15 | i==24 | i==26 | i==34 | i==38)
				bitmap_bot_game_over[i][j] = 2'b11;
			else if( (i==1 | i==25 | i==36 | i==17) &(j==0 | j==5))
				bitmap_bot_game_over[i][j] = 2'b11;	
			else if( (i==2 | i==35| i==16) & (j==0 | j==3 | j==5))
				bitmap_bot_game_over[i][j] = 2'b11;					
			else if( (i==3) & (j==0 | j==4 | j==3 | j==5))
				bitmap_bot_game_over[i][j] = 2'b11;									
			else if( (i==6) & (j==0 | j==3))
				bitmap_bot_game_over[i][j] = 2'b11;					
			else if( (i==10 | i==12) & (j==1))
				bitmap_bot_game_over[i][j] = 2'b11;
			else if( (i==11) & (j==2))
				bitmap_bot_game_over[i][j] = 2'b11;
			else if( (i==28 | i==32) & (j==0 | j==1 | j==2 | j==3))
				bitmap_bot_game_over[i][j] = 2'b11;				
			else if( (i==29 | i==31) & (j==4))
				bitmap_bot_game_over[i][j] = 2'b11;	
			else if( (i==30) & (j==5))
				bitmap_bot_game_over[i][j] = 2'b11;
			else if( (i==39) & (j==0 | j==2))
				bitmap_bot_game_over[i][j] = 2'b11;				
			else if( (i==40) & (j==0 | j==2 | j==3))
				bitmap_bot_game_over[i][j] = 2'b11;	
			else if( (i==41) & (j==0 | j==2 | j==4))
				bitmap_bot_game_over[i][j] = 2'b11;
			else if( (i==42) & (j==0 | j==1 | j==2 | j==5))
				bitmap_bot_game_over[i][j] = 2'b11;				
			else
				bitmap_bot_game_over[i][j] = 2'b00;			
		end
	end	
end
//car shape
always @(*) begin
	for (i=0; i<=2; i=i+1) begin
		for (j=0; j<=3; j=j+1) begin
			//car
			if(i == 0 && (j == 1 || j ==3))
				bitmap_bot_car[i][j] = 2'b01;
			else if(i == 1 && (j == 0 || j ==2))
				bitmap_bot_car[i][j] = 2'b01;			
			else if(i == 2 && (j == 1 || j == 3))
				bitmap_bot_car[i][j] = 2'b01;	
			else
				bitmap_bot_car[i][j] = 2'b00;				
		end
	end	
end

endmodule
