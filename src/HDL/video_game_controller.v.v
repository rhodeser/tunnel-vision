// Icon Module for Rojobot World Video Controller
//
//	Author:			Tunnel Vision Team
//	Last Modified:	20-Mar-2014
//	
//	 Revision History
//	 ----------------
//	 7/8 -Mar-2014		Took the icon module from project 1 and modified the inputs/outputs according to the new project
//	 9/10/11-Mar-2014	Initial two straight walls were created with an icon movement based on the inputs from picoblaze	
//	 12/13/14-Mar-2014  LFSR is created and based on its output straight walls movement to left/right
//	 15-Mar-2014		walls movement to left or right with a slight jerk in the straight walls based on LFSR,
//						edge detection logic was added so that walls do not go out of the screen
//   16-Mar-2014		Different icons were made, collision detect when icon touches wall, updating the collision detection info to picoblaze,
//						Difficulty Level logic based on the input from picoblaze
//   17-Mar-2014        switch logic to select icons, collision detection for new objects added in the tunnel, 
//						begin/game over screens, pause/restart logic, 1 tree is added to the background and tested its movement
//   18-Mar-2014	 	Back ground changes - added 5 trees on each side of the tunnel and randomized such that each appears randomly
//   19-Mar-2014        Added comments for better understanding             
//   20-Mar-2014        Final comments
//	Description:
//	------------
//	 All the Project's logic is in this module only.
//	 This module takes the game_info_reg as the input from picoblaze and gives the output collison_detect to picoblaze through the interface module.
//	 This module also gets the input randomized_value from LFSR and gives the outputs wall and icon which goes to colorizer module
//	 The icon selection using switches db_sw from seven segment is also implemented in this module
//	
//	 Inputs:
//			clock           - 25MHz Clock
//			rst             - Active-high synchronous reset
//			db_sw			- [4:1] are used for Icon's selection
//			start			- bottom push button is the start signal
//			pause			- top push button is the pause signal
//			game_info_reg	- (8-bits) [1:0]- bot's movement in X direction i.e. left/right
//										[4] - difficulty level. 1=>speed increases, 0 => Normal speed
//										    we use only these 3 bits in verilog point of view
//			randomized_value- LFSR output. MSB[7:6] out of 8-bits are used for randomization
//			Pixel_row		- (10 bits) current pixel row address
//			Pixel_column	- (10 bits) current pixel column address
//			
//	 Outputs:
//			collison_detect	- sets to 1, when collision occurs with either wall or object coming in between walls.
//			icon			- pixels of bot are sent to colorizer
//			wall			- pixels of wall are sent to colorizer
//			
//////////

`define BOT_POS_X 8'd64			//X-coordinate of bot's location when reset
`define BOT_POS_Y 8'd64			//Y-coordinate of bot's location when reset
`define WALL_POS_Y 8'd0			//Wall movement is only in Y direction and initializing its value to 0
`define WALL_WIDTH 6'd48		//Width/space between the two walls of the tunnel is initialized to 48

module video_game_controller (
input clock, rst,
input [7:0] db_sw,
input start,
input pause,
//input [1:0] bot_ctrl,
input [7:0] game_info_reg ,
input [7:0] randomized_value,				
input [9:0] Pixel_row,
input [9:0] Pixel_column,
output wire [1:0] wall,
output reg collison_detect,
output wire [1:0] icon
);

<<<<<<< HEAD
reg [1:0] bitmap_bot_1 [0:5] [0:5];	// square icon bitmap
reg [1:0] bitmap_bot_2 [0:5] [0:5];	// ant/small bug icon bitmap
reg [1:0] bitmap_bot_3 [0:5] [0:5];	// bot icon bitmap
reg [1:0] bitmap_bot_4 [0:5] [0:5];	// Hammer icon bitmap
reg [1:0] bitmap_bot_begin [0:21] [0:5]; // bitmap of BEGIN screen
reg [1:0] bitmap_bot_game_over [0:42] [0:5]; // bitmap of GAME OVER screen
reg [1:0] bitmap_tree [0:9] [0:12];	// bitmap of tree
=======
reg [1:0] bitmap_bot_1 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_2 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_3 [0:5] [0:5];	// normal image bitmap
reg [1:0] bitmap_bot_4 [0:5] [0:5];	// normal image bitmap

reg [1:0] bitmap_bot_begin [0:21] [0:5];
reg [1:0] bitmap_bot_game_over [0:42] [0:5];

reg [1:0] bitmap_bot_car [0:9] [0:10];	
reg [1:0] bitmap_tree [0:9] [0:12];	// normal image bitmap
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585

integer i,j,p,q;

// internal registers
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
reg [1:0] icon_actual;
reg [1:0] wall_actual;
reg start_sticky;
reg start_r;
reg pause_r;
reg pause_sticky;

//pause and re-start control logic
always @(posedge clock) begin
	if(rst) begin
		start_r <= 0;
		pause_r <= 0;
		pause_sticky <= 0;
		start_sticky <= 0;
	end
	else begin
		start_r <= start;	//input start is flopped
		pause_r <= pause;	//input pause is flopped
		if(~start_r & start) begin	//start_sticky is asserted and pause_sticky is de-asserted when we see a rise on start signal
			start_sticky <= 1;
			pause_sticky <= 0;
		end
		if(~pause_r & pause) begin	//pause_sticky is asserted and start_sticky is de-asserted when we see a rise on pause signal
			start_sticky <= 0;
			pause_sticky <= 1;
		end	
	end
end


// ICONS SHAPES
//
//	 i - Vertically/column wise
//	 j - Horizontally/row wise
//	 # - colored pixel
//
//	1)	SQUARE ICON
//		0 1 2 3 4 5 
//
//	0   # # # # # #  
//  1   # # # # # #    
//	2   # # # # # #
//  3   # # # # # #    
//  4   # # # # # #    
//  5   # # # # # #
//
//		2'b10 -- cyan color
//
//	2)	ANT/SMALL BUG ICON
//		0 1 2 3 4 5 
//
//	0          
//  1       # #     
//	2       # # 
//  3     #     #    
//  4   #         #    
//  5   
//
//	3)	BOT ICON
//		0 1 2 3 4 5 
//
//	0       # #   
//  1       # #     
//	2     # # # #
//  3   # # # # # #    
//  4     #     #    
//  5     #     #
//
//	4)	HAMMER ICON
//		0 1 2 3 4 5 
//
//	0     # # # # 
//  1     # # # #    
//	2     # # # #
//  3       # #     
//  4       # #    
//  5       # #
//
//		2'b11 -- Magenta color by default
//		2'b00 -- transparent
always @(*) begin
	for (i=0; i<=5; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
		   //square box
			 bitmap_bot_1[i][j] = 2'b10;	//cyan color
			//ant/small bug
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

// BEGIN SCREEN
//	 i - Vertically/column wise
//	 j - Horizontally/row wise
//	 # - colored pixel
//	 
//		0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 
//
//	0   # # #   # # #   #  #  #  #    #  #  #     #           #     			  
//  1   #   #   #       #                #        #  #        #               
//	2   #   #   #       #                #        #     #     #       
//  3   # # #   # # #   #     #  #       #        #        #  #       
//  4   #   #   #       #        #       #        #           #   
//  5   # # #   # # #   #  #  #  #    #  #  #     #           #
//
//		2'b11 -- Magenta color letters 
//		Transparent color in between letters and cyan color background
//
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
				bitmap_bot_begin[i][j] = 2'b00;		//transparent	
		end
	end	
end

// GAME OVER SCREEN
//	 i - Vertically/column wise
//	 j - Horizontally/row wise
//	 # - colored pixel
//	 
//		0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42
//
//	0   # # # #   # # #   #           #     #  #  #     			   #  #  #     #           #     #  #  #     #  #  #  #  #  
//  1   #         #   #   #  #     #  #     #                          #     #     #           #     #           #           #
//	2   #         #   #   #     #     #     #                          #     #     #           #     #           #  #  #  #  #  
//  3   #   # #   # # #   #           #     #  #                       #     #     #           #     #  #        #     #
//  4   #     #   #   #   #           #     #                          #     #        #     #        #           #        #
//  5   # # # #   #   #   #           #     #  #  #                    #  #  #           #           #  #  #     #           #
//
//		2'b11 -- Magenta color letters 
//		Transparent color in between letters and cyan color background
//
always @(*) begin
	for (i=0; i<=42; i=i+1) begin
		for (j=0; j<=5; j=j+1) begin
			//GAME OVER SCREEN
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
				bitmap_bot_game_over[i][j] = 2'b00;		//transparent	
		end
	end	
end	

//Bot movement during various signal
//pause signal -  No Movement
//start signal - Movement based on game_info_reg[1:0] 
//game_info_reg[1:0] = 01 - move right
//game_info_reg[1:0] = 10 - move left
//
// BEGIN and GAME OVER screens logic
always @ (posedge clock) begin
	if (rst) begin		//on reset, bot positions centre location
		icon_actual <= 2'b00;
		locX <= {`BOT_POS_X,2'b00};
		locY <= {`BOT_POS_Y,2'b00};
	end
	else if(~start_sticky & ~pause_sticky) begin	//until start signal is obtained, BEGIN screen is present on screen
		 if ((Pixel_row[9:3] >= 20) && (Pixel_row[9:3] <= 25) && (Pixel_column[9:3] >= 20) && (Pixel_column[9:3] <= 41)) begin 
		 // (Pixel_row[9:3] >= 20) && (Pixel_row[9:3] <= 25) means for Pixel_row values greater than 8*20=160 and less than 8*25=200 on actual screen
		 // (Pixel_column[9:3] >= 20) && (Pixel_column[9:3] <= 41) means for Pixel_column values greater than 8*20=160 and less than 8*41=328 on actual screen
 		 // BEGIN screen is of size 6x22. (20->25 is 6 and 20->41 is 22)
		 icon_actual <= bitmap_bot_begin[Pixel_column[9:3] - 20][Pixel_row[9:3] - 20];	
		 // As the if block is executed for Pixel_row[9:3] and Pixel_column[9:3] greater than 20, while accessing the bitmap_bot_begin register 20 is subtracted
		 // from pixel_row and pixel_column
		end	
		else begin
			icon_actual <= 2'b10;	//cyan color background
		end	
	end
	else if(game_completed) begin	//if game is over GAME OVER is printed on screen	
		if ((Pixel_row[9:3] >= 20) && (Pixel_row[9:3] <= 25) && (Pixel_column[9:3] >= 10) && (Pixel_column[9:3] <= 52)) begin
		// Pixel_row range from 160 to 200. Pixel_column range from 80 to 416 on actual screen
		// GAME OVER screen is of size 6x43. (20->25 is 6 and 10->52 is 43)
			icon_actual <= bitmap_bot_game_over[Pixel_column[9:3] - 10][Pixel_row[9:3] - 20];	
		// As the if block is executed for Pixel_row[9:3] greater than 20 and Pixel_column[9:3] greater than 10, while accessing the bitmap_bot_game_over register 20 is subtracted
		 // from pixel_row and 10 from pixel_column			
		end	
		else begin
			icon_actual <= 2'b10;	//cyan color background
		end		
	end
	else if(pause_sticky) begin	// when pause_sticky is asserted
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h5)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h5)) ) begin
<<<<<<< HEAD
			//condition to know whether pixel address matches with that of bot(icon1/icon2/icon3/icon4) location. All icons are of size 6x6.
			case (db_sw[4:1])	//Based on the ON switch bots are selected
				4'b0001 : begin //bitmap_bot_1 = SQUARE icon
					if(bitmap_bot_1[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin	//when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;	// Maroon color
=======
			//condition to know whether pixel address matches with that of bot location
			case (db_sw[4:1])
				4'b0001 : begin 
					if(bitmap_bot_1[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else 
							icon_actual <= 2'b11;	// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_1 [Pixel_column - locX][Pixel_row - locY] ;	//transparent
					end	
				end
				4'b0010 : begin //bitmap_bot_2 = ANT/SMALL BUG icon
					if(bitmap_bot_2[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin  //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;	// Maroon color
						else 
							icon_actual <= 2'b11;	// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_2 [Pixel_column - locX][Pixel_row - locY] ;	//transparent
					end	
				end
				4'b0100 : begin //bitmap_bot_3 = BOT icon
					if(bitmap_bot_3[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin	 //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;	// Maroon color
						else 
							icon_actual <= 2'b11;	// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_3 [Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				4'b1000 : begin //bitmap_bot_3 = HAMMER icon
					if(bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin	 //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin	
						icon_actual <= bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				default : begin //Default will be Hammer icon. For ex. when two switches are ON at the same time, icon will change to hammer shape
					if(bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin	 //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end				
			endcase	
		end
		else begin
			icon_actual <= 2'b00; // transparent
		end	
	end
<<<<<<< HEAD
	else begin	// when there is no pause. so bot's movement logic.
		if(Pixel_row == 10'b0 && Pixel_column == 10'b0 && cnt[3:0] == 0) begin	
		//we update the bot location when both pixel_row and pixel_column are 0. i.e. for every change of new screen
		//cnt[3:0] will determine how sensitive the robo should be.
		//For ex: cnt[2:0] makes robo more sensitive to push button pressing than cnt[3:0]																	
			if(game_info_reg[1:0] == 2'b10) begin // move left
=======
	else begin
		if(Pixel_row == 10'b0 && Pixel_column == 10'b0 && cnt[2:0] == 0) begin
			if(bot_ctrl[1:0] == 2'b10) begin // move left
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
				locX <= locX - 10'd1;
			end
			else if(game_info_reg[1:0] == 2'b01) begin // move right
				locX <= locX + 10'd1;
			end
			else begin // no change
				locX <= locX;
			end
		end
			
		if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h5)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h5)) ) begin
<<<<<<< HEAD
			//condition to know whether pixel address matches with that of bot(icon1/icon2/icon3/icon4) location. All icons are of size 6x6. 
			case (db_sw[4:1])	//Based on the ON switch bots are selected
				4'b0001 : begin 	//bitmap_bot_1 = SQUARE icon
					if(bitmap_bot_1[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
=======
			//condition to know whether pixel address matches with that of bot location
			case (db_sw[4:1])
				4'b0001 : begin 
					if(bitmap_bot_1[5 - Pixel_column + locX][Pixel_row - locY] == 2'b11) begin
						if(randomized_value[2] == 1)
							icon_actual <= 2'b01;
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_1 [Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				4'b0010 : begin 	//bitmap_bot_2 = ANT/SMALL BUG icon
					if(bitmap_bot_2[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_2 [Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				4'b0100 : begin 	//bitmap_bot_3 = BOT icon
					if(bitmap_bot_3[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_3 [Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				4'b1000 : begin 	//bitmap_bot_3 = HAMMER icon
					if(bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end
				default : begin //Default will be Hammer icon. For ex. when two switches are ON at the same time, icon will change to hammer shape
					if(bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] == 2'b11) begin //when the pixel of bot is colored(2'b11) then only animation(give different colors) is done otherwise make it transparent
						if(randomized_value[2] == 1)	// Animation for icon
							icon_actual <= 2'b01;		// Maroon color
						else 
							icon_actual <= 2'b11;		// Magenta color
					end
					else begin
						icon_actual <= bitmap_bot_4[Pixel_column - locX][Pixel_row - locY] ;	
					end	
				end				
			endcase	
		end
		else begin
			icon_actual <= 2'b00; // transparent
		end
	end
end

//wall movement logic. 
//wall movement is in Y direction.
always @ (posedge clock) begin
	if (rst) begin
	   k <= 10'd256; 	// Middle position of the screen
		wall_actual <= 2'b00;	//wall_actual is assigned to the output wall
		WallY <= {`WALL_POS_Y,2'b00};	//Initial wall position is 0
		wall_width <= `WALL_WIDTH;		//wall width or tunnel width is twice of value given by wall_width i.e. space between the two walls
		wally_left <= WallY - wall_width + k;	// wall_width is subtracted to get the position of left wall
		wally_right <= WallY + wall_width + k;	// wall_width is added so to get the position of right wall
		wally_left_prev <= WallY - wall_width + k;	// previous position of the left wall is saved
		wally_right_prev <= WallY + wall_width + k;	// previous position of the right wall is saved
		cnt <= 8'd0;	// count value for bot sensitivity and wall random movement speed
		randomized_value_f <= 8'd0;	//sampled output of LFSR
		collison_detect <= 1'd0;	// collision detection 
	end
	else if(~start_sticky & ~pause_sticky) begin //until start push button is pressed, there is no wall on the screen
		wall_actual <= 2'b00;
	end
	else if(game_completed) begin	//even when game is over, there is no wall on the screen
		wall_actual <= 2'b00;	
	end
	else if(pause_sticky) begin		// when pause is asserted
		if(Pixel_row[9:2] <= cnt) begin	//If present pixel_row is less than cnt then we update the wall position for this row otherwise we keep the previous position
										//This helps in smooth change in the wall movement. 
										// This is for the upper portion of the wall from where the transition is going to happen
			if((Pixel_column >= wally_left) &&(Pixel_column <= wally_right)) begin	// when pixel_row and column matches the tunnel and in-between area
				if((Pixel_column == wally_left) ||(Pixel_column == wally_right)) begin //Pixel_column matches the left and right positions of wall
					wall_actual <= 2'b10;	//Dark Red color -- indicating wall
				end
				else begin
<<<<<<< HEAD
					if(randomized_value_f[7:6] == 2'b11) begin	// object in between tunnel comes randomly to the left side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin //condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];	// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
						end																					// Object starts from 4 pixels from the left wall.
=======
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
						end
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
<<<<<<< HEAD
					else if(randomized_value_f[7:6] == 2'b01) begin	// object in between tunnel comes randomly to the right side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin //condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];	// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
						end																					// Object starts from 10 pixels from the right wall. 
=======
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
						end
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
					else
						wall_actual <= 2'b11;	//Grey color -- in between the two walls
				end	
			end	
<<<<<<< HEAD
			else begin	
				//Background trees logic.There are 5 trees on the LHS of the left wall and 5 trees on the RHS of the right wall.
				//If tunnel moves to the location of the tree then tree will not be displayed as tunnel is given more priority
				// Trees appearance is also randomized so that they all will not appear at the same time
				//Each tree is of size 13x10
				//As the X-axis(Pixel_row) is almost of same range for all trees, they will be nearly on the same line adjacent to each to other as Y-axis(Pixel_column) are different
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin 
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];	//tree1 to the LHS 
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];	//tree2 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];	//tree3 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];	//tree4 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];	//tree5 to the LHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];	//tree1 to the RHS 
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];	//tree2 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];	//tree3 to the RHS
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];	//tree4 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];	//tree5 to the RHS
=======
			else begin		
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
				end					
				else
					wall_actual <= 2'b00; // transparent
			end
		end
		else begin
		// This is for the lower portion of the wall from where the transition is going to happen
			if((Pixel_column >= wally_left_prev) &&(Pixel_column <= wally_right_prev)) begin	// when pixel_row and column matches the tunnel and in-between area
				if((Pixel_column == wally_left_prev) ||(Pixel_column == wally_right_prev)) begin	 //Pixel_column matches the left and right positions of wall
					wall_actual <= 2'b10;	//Dark Red color -- indicating wall
				end
				else begin
<<<<<<< HEAD
					if(randomized_value_f[7:6] == 2'b11) begin	// object in between tunnel comes randomly to the left side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin //condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];	// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
						end																					// Object starts from 4 pixels from the left wall.
=======
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
						end
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
					else if(randomized_value_f[7:6] == 2'b01) begin	
<<<<<<< HEAD
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin //condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];	// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
						end																					// Object starts from 10 pixels from the right wall.
=======
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
						end
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
					else
						wall_actual <= 2'b11;	//Grey color -- in between the two walls
				end	
			end	
			else begin
<<<<<<< HEAD
			//Background trees logic. Same as explained above.
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];	//tree1 to the LHS 
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];	//tree2 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];	//tree3 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];	//tree4 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];	//tree5 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];	//tree1 to the RHS 
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];	//tree2 to the RHS 
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];	//tree3 to the RHS 
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];	//tree4 to the RHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];	//tree5 to the RHS 
=======
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
				end					
				else
					wall_actual <= 2'b00; // transparent
			end		
		end		
	end
	//PAUSE LOGIC COMPLETED
	
	
	else begin	//when there is no pause => movement of walls to the left/right. Decrease/Increase in width of the wall. Bot's movement to left/right.
				//Background trees movement. Object in between tunnel movement
				//collision detection with walls and with objects in between the tunnel.
	if(cnt[6:0] == 0 && Pixel_column == 10'd0 && Pixel_row == 10'd0) begin	//For every new screen
			if(randomized_value[7:6] == 2'b11 || randomized_value[7:6] == 2'b01) begin	//slowing wall movement to right		
				if(wally_right <= 10'd500 && k <= 10'd500) begin	//Right Edge detection. This helps not to move wall out of the screen
					k <= k + 10'd8;									//Move to the right
				end
			end
			else begin
				if(wally_left >= 10'd100 && k >= 10'd100) begin	//Left Edge detection. This helps not to move wall out of the screen
					k <= k - 10'd8;								//Move to the left
				end	
			end
			
			if( (k%16) == 0) begin					//checking for every 2 changes in k value
				if(wall_width > 8) begin			//to make sure that wall width doesn't shrink below 8
					wall_width <= wall_width - 1'd1;	//decrement the wall width
				end
				else begin
					wall_width <= wall_width + 2'd6;	//increment the wall width
				end
			end
			wally_left <= WallY - wall_width + k;	// new wall_width is subtracted to get the new position of left wall
			wally_right <= WallY + wall_width + k;	// new wall_width is added to get the new position of right wall
			wally_left_prev <= wally_left;			// previous position of the left wall is saved
			wally_right_prev <= wally_right;		// previous position of the right wall is saved
			randomized_value_f <= randomized_value;	//sampled output of LFSR
		end
		//The same logic, but when the game is in the moving state
		if(Pixel_row[9:2] <= cnt) begin//If present pixel_row is less than cnt then we update the wall position for this row otherwise we keep the previous position
										//This helps in smooth change in the wall movement. 
										// This is for the upper portion of the wall from where the transition is going to happen
			// This is for the upper portion of the wall from where the transition is going to happen
			if((Pixel_column >= wally_left) &&(Pixel_column <= wally_right)) begin // when pixel_row and column matches the tunnel and in-between area
				if((Pixel_column == wally_left) ||(Pixel_column == wally_right)) begin	//Pixel_column matches the left and right positions of wall
					wall_actual <= 2'b10;	//Dark Red color -- indicating wall
				end
				else begin
<<<<<<< HEAD
					if(randomized_value_f[7:6] == 2'b11) begin	// object in between tunnel comes randomly to the left side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin//condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
=======
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
							///////
							//collision detection logic
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
							//collision of the bot with the object in between the tunnel, based on the bot locations. bot is of size 6x6
								collison_detect <= 1'd1;
							end		
							///////								
						end
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
<<<<<<< HEAD
					else if(randomized_value_f[7:6] == 2'b01) begin	// object in between tunnel comes randomly to the right side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin//condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
=======
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
							///////
							//collision detection logic
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
							//collision of the bot with the object in between the tunnel, based on the bot locations. bot is of size 6x6
								collison_detect <= 1'd1;
							end		
							///////								
						end
						else
							wall_actual <= 2'b11;	//Grey color -- in between the two walls
					end
					else
						wall_actual <= 2'b11;	//Grey color -- in between the two walls
				end	
			end	
			else begin
			///////
			//collision detection logic
				if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
				//collision of the bot with the wall based on the bot locations. bot is of size 6x6
					collison_detect <= 1'd1;
				end		
			///////
<<<<<<< HEAD
				//Background trees logic. Same as explained above.
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];	//tree1 to the LHS 
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];	//tree2 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];	//tree3 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];	//tree4 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];	//tree5 to the LHS 
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];	//tree1 to the RHS 
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];	//tree2 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];	//tree3 to the RHS
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];	//tree4 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];	//tree5 to the RHS
=======
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
				end					
				else
					wall_actual <= 2'b00; // transparent
			end
		end
		else begin
		// This is for the upper portion of the wall from where the transition is going to happen
			if((Pixel_column >= wally_left_prev) &&(Pixel_column <= wally_right_prev)) begin	// when pixel_row and column matches the tunnel and in-between area		
				if((Pixel_column == wally_left_prev) ||(Pixel_column == wally_right_prev)) begin//Pixel_column matches the left and right positions of wall
					wall_actual <= 2'b10;	//Dark Red color -- indicating wall
				end
				else begin
<<<<<<< HEAD
					if(randomized_value_f[7:6] == 2'b11) begin// object in between tunnel comes randomly to the left side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin//condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
=======
					if(randomized_value_f[7:6] == 2'b11) begin
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_left+10) && (Pixel_column <= wally_left+10+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_left+4-Pixel_column][Pixel_row[9:2]-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
							//collision of the bot with the object in between the tunnel, based on the bot locations. bot is of size 6x6
							collison_detect <= 1'd1;
							end		
							///////	
						end
						else
							wall_actual <= 2'b11;//Grey color -- in between the two walls
					end
<<<<<<< HEAD
					else if(randomized_value_f[7:6] == 2'b01) begin	// object in between tunnel comes randomly to the right side of the wall
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin//condition to match the object in between the tunnel
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];// object in between tunnel is of bitmap_bot_1 shape and is of size 6x6
=======
					else if(randomized_value_f[7:6] == 2'b01) begin	
						if ((Pixel_row[9:2] >= cnt) && (Pixel_row[9:2] <= 5+cnt) && (Pixel_column >= wally_right-15) && (Pixel_column <= wally_right-15+5) ) begin
							wall_actual <= bitmap_bot_1[5+wally_right-10-Pixel_column][Pixel_row[9:2]-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
							///////
							if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
							//collision of the bot with the object in between the tunnel, based on the bot locations. bot is of size 6x6
							collison_detect <= 1'd1;
							end		
							///////								
						end				
						else
							wall_actual <= 2'b11;//Grey color -- in between the two walls
					end
					else
						wall_actual <= 2'b11;//Grey color -- in between the two walls
				end	
			end	
			else begin
			///////
			//collision detection logic
				if ((Pixel_row >= locY) && (Pixel_row <= (locY + 3'h6)) && (Pixel_column >= locX) && (Pixel_column <= (locX + 4'h6)) ) begin
				//collision of the bot with the wall based on the bot locations. bot is of size 6x6
					collison_detect <= 1'd1;
				end		
<<<<<<< HEAD
			///////	
			//Background trees logic. Same as explained above.			
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];	//tree1 to the LHS
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];	//tree2 to the LHS
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];	//tree3 to the LHS
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];	//tree4 to the LHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];	//tree5 to the LHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];	//tree1 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];	//tree2 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];	//tree3 to the RHS
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];	//tree4 to the RHS
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];	//tree5 to the RHS
=======
			///////			
				if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 10) && (Pixel_column <= 22) && (randomized_value_f[7:6] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 10][Pixel_row[9:2]-10-cnt];
				end
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 40) && (Pixel_column <= 52) && (randomized_value_f[7:6] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 40][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 60) && (Pixel_column <= 72) && (randomized_value_f[7:6] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 60][Pixel_row[9:2]-13-cnt];
				end	
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 100) && (Pixel_column <= 112) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 100][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 120) && (Pixel_column <= 132) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 120][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 320) && (Pixel_column <= 332) && (randomized_value_f[7:6] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 320][Pixel_row[9:2]-10-cnt];
				end	
				else if ((Pixel_row[9:2] >= 20+cnt) && (Pixel_row[9:2] <= 29+cnt) && (Pixel_column >= 360) && (Pixel_column <= 372) && (randomized_value_f[5:4] == 2'b10)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 360][Pixel_row[9:2]-20-cnt];
				end	
				else if ((Pixel_row[9:2] >= 13+cnt) && (Pixel_row[9:2] <= 22+cnt) && (Pixel_column >= 400) && (Pixel_column <= 412) && (randomized_value_f[5:4] == 2'b01)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 400][Pixel_row[9:2]-13-cnt];
				end		
				else if ((Pixel_row[9:2] >= 18+cnt) && (Pixel_row[9:2] <= 27+cnt) && (Pixel_column >= 450) && (Pixel_column <= 462) && (randomized_value_f[5:4] == 2'b11)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 450][Pixel_row[9:2]-18-cnt];
				end	
				else if ((Pixel_row[9:2] >= 10+cnt) && (Pixel_row[9:2] <= 19+cnt) && (Pixel_column >= 490) && (Pixel_column <= 502) && (randomized_value_f[5:4] == 2'b00)) begin
					//wall_actual <= 2'b11;
					wall_actual <= bitmap_tree[Pixel_column - 490][Pixel_row[9:2]-10-cnt];
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
				end					
				else
					wall_actual <= 2'b00; // transparent
			end		
		end		
		
<<<<<<< HEAD
		if(game_info_reg[4] == 1) begin //Increase game speed, by incrementing the cnt either 4 or 8 times based on the input from picoblaze
			if(Pixel_column == 10'd0 && Pixel_row[9:3] == 7'd0) begin	//fast
				cnt <= cnt + 1'd1; // Increment the count 8 times for every new screen
			end			
		end
		else begin
			if(Pixel_column == 10'd0 && Pixel_row[9:2] == 8'd0) begin  //slow
				cnt <= cnt + 1'd1;	//Increment the count 4 times for every new screen
=======
		if(game_info_reg[4] == 1) begin //Increase game speed
			if(Pixel_column == 10'd0 && Pixel_row[9:3] == 7'd0) begin	//fast
		//	if(Pixel_column == 10'd0 && Pixel_row[9:2] == 8'd0) begin     //slow
				cnt <= cnt + 1'd1;
			end			
		end
		else begin
			if(Pixel_column == 10'd0 && Pixel_row[9:2] == 8'd0) begin		//fast
		//	if(Pixel_column == 10'd0 && Pixel_row[9:1] == 9'd0) begin //slow
				cnt <= cnt + 1'd1;
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
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
<<<<<<< HEAD
		game_completed <= collison_detect;	//when collision is detected, game_completed is asserted so that GAME OVER appears on screen
=======
		game_completed <= collison_detect;
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585
	end
end	

assign icon = icon_actual;
assign wall = wall_actual;


//TREE
//	 i - Horizontally/row wise
//	 j - Vertically/column wise
//	 # - colored pixel
//	 
//		0 1 2 3 4 5 6 7 8 9  
//
//	0   		# #  
//  1         # # # #     
//	2       # # # # # #
//  3     # # # # # # # #   
//  4   # # # # # # # # # #   
//  5           #
//  6           #
//  7           #
//  8           #
//  9           #
// 10           #
// 11           #
// 12           #
//
//		2'b01 -- green color to the top portion of the tree
//		2'b11 -- grey color to the straight line portion of tree
always @(*) begin
	for (p=0; p<=9; p=p+1) begin
		for (q=0; q<=12; q=q+1) begin
			if((p==0||p==9) && (q==4))
				bitmap_tree[p][q] = 2'b01;
			else if((p==1||p==8) && (q==4 || q==3))
				bitmap_tree[p][q] = 2'b01;			
			else if((p==2||p==7) && (q==4 || q==3 || q==2))
				bitmap_tree[p][q] = 2'b01;			
			else if((p==3||p==6) && (q==4||q==3 || q==2 || q==1))
				bitmap_tree[p][q] = 2'b01;		
			else if((p==5 | p==4) && (q==4||q==3 || q==2 || q==1 || q==0))
				bitmap_tree[p][q] = 2'b01;	
			else if(p==4)
				bitmap_tree[p][q] = 2'b11;		
			else
				bitmap_tree[p][q] = 2'b00;	// transparent			
		end
	end
end	


<<<<<<< HEAD
=======
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
	for (i=0; i<=9; i=i+1) begin
		for (j=0; j<=10; j=j+1) begin
			//car
			if((i==0 | i==1 | i==2 | i==3 | i==6 | i==7 | i==8 | i==9) && (j==3 | j==4 | j==5 | j==9 | j==10))
				bitmap_bot_car[i][j] = 2'b01;
			else if((i==4 | i==5) && (j==0 | j==1 | j==2 | j==6 | j==7 | j==8))
				bitmap_bot_car[i][j] = 2'b01;			
			else
				bitmap_bot_car[i][j] = 2'b00;				
		end
	end	
end
>>>>>>> 7eec690f246ee3e2db5f7ac9fff4c131370e1585

endmodule
