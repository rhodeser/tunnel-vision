`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////
// University		:	Portland State University
// Term			:	Winter 2014
// Engineer		:	
// 
// Create Date		:	01:08:20 02/22/2014 
// Module Name		:	Nexys3fpga 
// Project Name		:	Project 1 (System on Chip)
// Tool versions	:	Xilinx ISE 14.7
//
// Dependencies			kcpsm6.v,SevenSegment.v, debounce.v,game_interface.v,dtg.v
//						colorizer.v, video_game_controller.v,lfsr.v	 
//	
//	Description		:
//	This module is the top module for the RojoBot Project 1, in which all modules are instantiated.
//
// Modules Instantiated:
// 1.  debounce
// 2.  sevensegment
// 3.  game_interface
// 4.  game_control_logic
// 5.  video_game_controller
// 6.  lfsr
// 7.  kcpsm6
// 8.  DCM_SP
// 9.  dtg
// 10. colorizer
// 
//
// Revision: 
// Revision 0.01 
//
// nexys3fpga.v - Top level module for Nexys3 as used in the ECE 540 Getting Started project
//
// Modified from S3E Starter Board files by David Glover, 29-April-2012.
//
// 
// Created By		:	 Bhavana, Erik Rhodes, Nikhil Patil
// Last Modified	:	 18-March-2013
//
// Revision History:
// -----------------
// Nov-2008		RK		Created this module for the S3E Starter Board
// Apr-2012		DG		Modified for Nexys 3 board
// Dec-2014		RJ		Cleaned up formatting.  No functional changes
// Jan-2014		NP		Modified and added
// Feb-2014		BD		Modified and added
// March-2014		ER,NP		Modified and added
// Description:
// ------------
// Top level module for the ECE 540 Getting Started reference design
// on the Nexys3 FPGA Board (Xilinx XC6LX16-CS324)
//
////////////////////////////////////////////////////////////////////////////////////////////

module Nexys3fpga (
	input 			clk100,         		// 100MHz clock from on-board oscillator
	input			btnl, btnr,			// pushbutton inputs - left and right
	input			btnu, btnd,			// pushbutton inputs - top and bottom
	input			btns,				// pushbutton inputs - center button
	input	[7:0]		sw,				// switch inputs
	
	output	[7:0]		led,  				// LED outputs	
	
	output 	[7:0]		seg,				// Seven segment display cathode pins
	output	[3:0]		an,				// Seven segment display anode pins	
	
	output	[3:0]		JA,				// JA Header
	
	output	[2:0]		vgaRed,				// VGA CONNECTION FOR RED COLOR
	output	[2:0]		vgaGreen,			// VGA CONNECTION FOR GREEN COLOR
	output	[2:1]		vgaBlue,			// VGA CONNECTION FOR BLUE COLOR
	output			Hsync,				// HORIZONTAL SYNC
	output			Vsync				// VERTICAL SYNC
	
); 

	// INTERNAL VARIABLES
	
	wire 	[7:0]		db_sw;				// debounced switches
	wire 	[4:0]		db_btns;			// debounced buttons
	
	wire			sysclk;				// 100MHz clock from on-board oscillator	
	wire			sysreset;			// system reset signal - asserted high to force reset
	
	//PART II START/////
	

	wire			clk25;

	
	wire 	[4:0]		dig3, dig2, 
				dig1, dig0;			// display digits
	wire 	[3:0]		decpts;				// decimal points
	wire 	[7:0]		chase_segs;			// chase segments from Rojobot (debug)

		
	
//////////NEXYS3_BOT_IF/////////

	wire 	[7:0]		game_info;
	wire 	[7:0] 		randomized_value;
	wire 			collison_detect;



	wire 	[3:0]		port_id;
	wire 	[7:0]		out_port;
	wire 	[7:0]		in_port;


	wire			k_write_strobe;
	wire			write_strobe;
	wire			read_strobe;
	wire			interrupt;
	wire			interrupt_ack;
//wire 	[7:0]		led;


////////////BOT.V///////////////

	wire	[1:0]		vid_pixel_out;
	wire	[9:0]		vid_row;
	wire	[9:0]		vid_col;

///////KCPSM6.V//////////////////

	wire 	[9:0]		address;
	wire	[17:0]		instruction;
	wire			bram_enable;
	wire			kcpsm6_reset;

/////////PROJECT1DEMO.V///////////

	wire			rdl;
	wire			sleep;

////PART II DTG.V//////////

//wire					horiz_sync;
//wire					vert_sync;
	wire			video_on;
//wire					pixel_row;
//wire					pixel_column;

/////// PART II COLORIZER.V//////////


	wire	[1:0] 		icon,wall;

////// VIDEO CONTROLLER/////

	wire	[9:0]		vid_row_shifted;
	wire	[9:0]		vid_col_shifted;



			
	// global assigns
	assign	sysclk 		= clk100;
	assign 	sysreset 	= db_btns[0];
	assign	JA 		= {sysclk, sysreset, 2'b0};
	
	assign 	kcpsm6_reset 	= (rdl || sysreset); //// CHANGED
	

	assign 	vid_row_shifted	=   vid_row>> 2;
	assign	vid_col_shifted	=   vid_col>> 2;
	

	
	// INSTANTUATE THE DEBOUNCE MODULE
	
	debounce DB (
		.clk(sysclk),	
		.pbtn_in({btnl,btnu,btnr,btnd,btns}),
		.switch_in(sw),
		.pbtn_db(db_btns),
		.swtch_db(db_sw)
	);	
		
	// INSTANTUATE THE 7 SEGMENT MODULE
	
	sevensegment SSB (
		// inputs for control signals
		.d0(dig0),
		.d1(dig1),
 		.d2(dig2),
		.d3(dig3),
		.dp(decpts),
		// outputs to seven segment display
		.seg(seg),			
		.an(an),				
		// clock and reset signals (100 MHz clock, active high reset)
		.clk(sysclk),
		.reset(sysreset),
		// ouput for simulation only
		.digits_out(digits_out)
	);

					
	
	// INSTANTUATE THE NEXYS3_BOT_IF MODULE (INTERFACE)
	
	game_interface game_int(
		.clk(sysclk),
		.rst(sysreset),
		.game_info(game_info),
		.collison_detect(collison_detect),
		.db_btns(db_btns[4:1]),
		.db_sw(db_sw),
		.dig3(dig3),
		.dig2(dig2),
		.dig1(dig1),
		.dig0(dig0),
		.dp(decpts),
		.port_id(port_id),
		.out_port(out_port),
		.in_port(in_port),
		.k_write_strobe(k_write_strobe),
		.write_strobe(write_strobe),
		.read_strobe(read_strobe),
		.interrupt(interrupt),
		.interrupt_ack(interrupt_ack),
		.led(led),
		.randomized_value(random_value)
	);	
	
	// instantiate LSFR
	lfsr lfsr_1(
		.clk(sysclk),
		.reset(sysreset),
		.randomized_value(randomized_value)
    	);
	
	// INSTANTUATE KCPSM6 MODULE (CONTROLLER)
	
	kcpsm6 kcpsm6(

		.address 	(address),
		.instruction 	(instruction),
		.bram_enable 	(bram_enable),
		.port_id 	(port_id),
		.write_strobe 	(write_strobe),
		.k_write_strobe(k_write_strobe),
		.out_port	(out_port),
		.read_strobe 	(read_strobe),
		.in_port 	(in_port),
		.interrupt	(interrupt),
		.interrupt_ack  (interrupt_ack),
		.reset 		(kcpsm6_reset),
		.sleep		(1'b0),
		.clk 		(sysclk) 
	);

	// INSTANTUATE THE PROJECT1DEMO MODULE
	
	game_control_logic  game_ctrl(

		.rdl 		(rdl),
		.enable 	(bram_enable),
		.address 	(address),
		.instruction 	(instruction),
		.clk 		(sysclk)

	);

////////////////////////PART II STARTS HERE//////////////


   wire            clkfb_in, clk0_buf;
	
	//assign 	clkfb_in	= clk100;					/// PART II 
   
   // DCM clock feedback buffer
   BUFG CLK0_BUFG_INST (.I(clk0_buf), .O(clkfb_in));

// DCM_SP: Digital Clock Manager Circuit
// Spartan-3E/3A, Spartan-6
// Xilinx HDL Libraries Guide, version 11.2

	DCM_SP #(
		.CLKDV_DIVIDE(4.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
		// 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		.CLKFX_DIVIDE(1), // Can be any integer from 1 to 32
		.CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
		.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
		.CLKIN_PERIOD(10.0), // Specify period of input clock
		.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
		.CLK_FEEDBACK("1X"), // Specify clock feedback of NONE, 1X or 2X
		.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
		// an integer from 0 to 15
		.DLL_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for DLL
		.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
		.PHASE_SHIFT(0), // Amount of fixed phase shift from -255 to 255
		.STARTUP_WAIT("FALSE") // Delay configuration DONE until DCM LOCK, TRUE/FALSE
		) DCM_SP_inst (
		.CLK0(clk0_buf), // 0 degree DCM CLK output
		.CLK180(), // 180 degree DCM CLK output
		.CLK270(), // 270 degree DCM CLK output
		.CLK2X(), // 2X DCM CLK output
		.CLK2X180(), // 2X, 180 degree DCM CLK out
		.CLK90(), // 90 degree DCM CLK output
		.CLKDV(clk25), // Divided DCM CLK out (CLKDV_DIVIDE)
		.CLKFX(), // DCM CLK synthesis out (M/D)
		.CLKFX180(), // 180 degree CLK synthesis out
		.LOCKED(), // DCM LOCK status output
		.PSDONE(), // Dynamic phase adjust done output
		.STATUS(), // 8-bit DCM status bits output
		.CLKFB(clkfb_in), // DCM clock feedback
		.CLKIN(clk100), // Clock input (from IBUFG, BUFG or DCM)
		.PSCLK(1'b0), // Dynamic phase adjust clock input
		.PSEN(1'b0), // Dynamic phase adjust enable input
		.PSINCDEC(1'b0), // Dynamic phase adjust increment/decrement
		.RST(1'b0) // DCM asynchronous reset input
	);
// End of DCM_SP_inst instantiation


// INSTANTIATE DTG.V MODULE


	dtg dtg(
		.clock(clk25),
		.rst(sysreset),
		.horiz_sync(Hsync),
		.vert_sync(Vsync),
		.video_on(video_on),
		.pixel_row(vid_row),
		.pixel_column(vid_col)
	);



// INSTANTIATE COLORIZE.V MODULE


	colorizer colorizer(
		.clock(clk25),
		.rst(sysreset),
		.video_on(video_on),
		.wall(wall),
		.icon(icon),
		.red(vgaRed),
		.green(vgaGreen),
		.blue(vgaBlue)
		
	);



	video_game_controller game_control(
		.clock(clk25),
		.rst(sysreset),
		.db_sw(db_sw),
		.start(db_btns[1]),
		.pause(db_btns[3]),
		.game_info_reg(game_info),
		.bot_ctrl({db_btns[4],db_btns[2]}),
		.collison_detect(collison_detect),
		.randomized_value(randomized_value),
		.Pixel_row(vid_row),
		.Pixel_column(vid_col),
		.icon(icon),
		.wall(wall)
	);
			
endmodule
