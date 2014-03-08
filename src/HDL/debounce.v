// debounce.v - debounces pushbuttons and switches
//
// Copyright Roy Kravitz, 2008-2013, 2014
// 
// Created By:		Roy Kravitz
// Last Modified:	31-Dec-2013 (RK)
//
// Revision History:
// -----------------
// Sep-2008		RK		Created this module for the Digilent S3E Starter Board
// Sep-2012		RK		Modified module for the Digilent Nexys 3 board
// Dec-2013		RK		Cleaned up the formatting.  No functional changes
//
// Description:
// ------------
// This circuit filters out mechanical bounce. It works by taking
// several time samples of the pushbutton and changing its output
// only after several sequential samples are the same value
// 
///////////////////////////////////////////////////////////////////////////

`timescale  1 ns / 1 ns
module debounce (
	//inputs
	input				clk,				// clock	
	input 		[4:0]	pbtn_in,			// pushbutton inputs
	input 		[7:0]	switch_in,			// slider switch inputs
	
	//outputs
	output reg	[4:0]	pbtn_db  = 5'h0, 	// debounced outputs of pushbuttons	
	output reg	[7:0]	swtch_db = 8'h0		// debounced outputs of slider switches
);
	parameter simulate = 0;
    localparam debounce_cnt = simulate ? 22'd5          // debounce clock when simulating
                                       : 22'd4_000_000; // debounce count when running on HW

	//shift registers used to debounce switches and buttons	
	reg [21:0]	db_count = 22'h0;	//counter for debouncer
	reg [4:0]	shift_pb0 = 5'h0, shift_pb1 = 5'h0, shift_pb2 = 5'h0, shift_pb3 = 5'h0, shift_pb4 = 5'h0;
	reg [3:0]	shift_swtch0 = 4'h0, shift_swtch1 = 4'h0, shift_swtch2 = 4'h0, shift_swtch3 = 4'h0;	
    reg [3:0]	shift_swtch4 = 4'h0, shift_swtch5 = 4'h0, shift_swtch6 = 4'h0, shift_swtch7 = 4'h0;
			
	// debounce clock
	always @(posedge clk)
	begin 
		if (db_count == debounce_cnt)
			db_count <= 1'b0;	//takes 40mS to reach 4,000,000
		else
			db_count <= db_count + 1'b1;
	end
	
	always @(posedge clk) 
	begin
		if (db_count == debounce_cnt) begin	//sample every 40mS
			//shift registers for pushbuttons
			shift_pb0	<= (shift_pb0 << 1) | pbtn_in[0];		
			shift_pb1	<= (shift_pb1 << 1) | pbtn_in[1];		
			shift_pb2	<= (shift_pb2 << 1) | pbtn_in[2];		
			shift_pb3	<= (shift_pb3 << 1) | pbtn_in[3];
			shift_pb4 	<= (shift_pb4 << 1) | pbtn_in[4]; 
			
			//shift registers for slider switches
			shift_swtch0 <= (shift_swtch0 << 1) | switch_in[0];
			shift_swtch1 <= (shift_swtch1 << 1) | switch_in[1];
			shift_swtch2 <= (shift_swtch2 << 1) | switch_in[2];
			shift_swtch3 <= (shift_swtch3 << 1) | switch_in[3];
			shift_swtch4 <= (shift_swtch4 << 1) | switch_in[4];
			shift_swtch5 <= (shift_swtch5 << 1) | switch_in[5];
			shift_swtch6 <= (shift_swtch6 << 1) | switch_in[6];
			shift_swtch7 <= (shift_swtch7 << 1) | switch_in[7];
		end
		
		//debounced pushbutton outputs
		case(shift_pb0) 4'b0000: pbtn_db[0] <= 0; 4'b1111: pbtn_db[0] <= 1; endcase
		case(shift_pb1) 4'b0000: pbtn_db[1] <= 0; 4'b1111: pbtn_db[1] <= 1; endcase
		case(shift_pb2) 4'b0000: pbtn_db[2] <= 0; 4'b1111: pbtn_db[2] <= 1; endcase
		case(shift_pb3) 4'b0000: pbtn_db[3] <= 0; 4'b1111: pbtn_db[3] <= 1; endcase
		case(shift_pb4) 4'b0000: pbtn_db[4] <= 0; 4'b1111: pbtn_db[4] <= 1; endcase
		
		//debounced slider switch outputs
		case(shift_swtch0) 4'b0000: swtch_db[0] <= 0;  4'b1111: swtch_db[0] <= 1; endcase
		case(shift_swtch1) 4'b0000: swtch_db[1] <= 0;  4'b1111: swtch_db[1] <= 1; endcase
		case(shift_swtch2) 4'b0000: swtch_db[2] <= 0;  4'b1111: swtch_db[2] <= 1; endcase
		case(shift_swtch3) 4'b0000: swtch_db[3] <= 0;  4'b1111: swtch_db[3] <= 1; endcase	
		case(shift_swtch4) 4'b0000: swtch_db[4] <= 0;  4'b1111: swtch_db[4] <= 1; endcase
		case(shift_swtch5) 4'b0000: swtch_db[5] <= 0;  4'b1111: swtch_db[5] <= 1; endcase
		case(shift_swtch6) 4'b0000: swtch_db[6] <= 0;  4'b1111: swtch_db[6] <= 1; endcase
		case(shift_swtch7) 4'b0000: swtch_db[7] <= 0;  4'b1111: swtch_db[7] <= 1; endcase
	end
	
endmodule
