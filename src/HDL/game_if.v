`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company			: 
// Engineer			: 
// 
// Create Date		:    01:08:20 01/26/2014 
// Design Name		: 
// Module Name		:    nexys3_bot_if 
// Project Name	: 
// Target Devices	: 
// Tool versions	: 
// Description		: 
//
// Dependencies	: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module game_interface(

	input					clk,
	input 					rst,
	output reg	[7:0]		game_info,
	//input					upd_sysregs,
	
	// SEVEN SEGMENT.V CONNECTIONS
	
	output reg	[4:0]		dig3,
	output reg	[4:0]		dig2,
	output reg	[4:0]		dig1,
	output reg	[4:0]		dig0,
	
	output reg	[3:0]		dp,
	
	// DEBOUNCE.V CONNECTIONS
	
	input		[4:1]		db_btns,
	input		[7:0]		db_sw,
	input		[1:0]		randomized_value,
	//input 					game_status,
	input collison_detect,
	// LED OUT
	
	output reg [7:0]		led,
	
	// KCPSM6.V CONNECTIONS
	
	input		[7:0]		port_id,
	input		[7:0]		out_port,
	
	output reg	[7:0]		in_port,
	
	input					k_write_strobe,
	input					write_strobe,
	input					read_strobe,
	
	output reg				interrupt,	
	input					interrupt_ack
	
	
    );
	 
reg [25:0] count;
reg flag;
//reg collison_detect_f;

always @(posedge clk)
begin
	
	if(write_strobe == 1'b1)
	begin
		case(port_id)
		
		8'h02 		:begin
								led <= out_port; 						
						 end		
		
		8'h03 		:begin
								dig3 <= out_port; 						
						 end

		8'h04			 :begin
								dig2 <= out_port; 						
						 end	

		8'h05			 :begin
								dig1 <= out_port; 						
						 end		

		8'h06			 :begin
								dig0 <= out_port; 						
						 end		

		8'h07			 :begin
								dp <= out_port; 						
						 end			

		8'h09			 :begin
								game_info <= out_port; 						
						 end		

		default		:begin
								dp<= out_port;
						 end
		endcase
	end	
end	


// READ STROBE OPERATION

always @(posedge clk)
begin

	case(port_id)	
		8'h00			:begin
								in_port <= {db_btns[4],db_btns[3],db_btns[2],db_btns[1]}; 						
						 end	

		8'h01			:begin
								in_port <= db_sw; 						
						 end				
		8'h0F			:begin
								in_port <= randomized_value; 						
						 end	
		8'h02			:begin
								in_port <= collison_detect;
						end									 
	 endcase
end
	
	
	// INTERRUPT & INTERRUPT ACK
always @ (posedge clk)
	begin
		if(rst) begin
			count <= 26'b0;
			flag <= 1'b0;
//			collison_detect_f <= 1'd0;
		end
		else begin
//			collison_detect_f <= collison_detect;
			if (game_info[4] == 1'b0) begin 			//check level, speed up interrupt (meaning score)
				flag <= 1'b0;
				if(count <= 10000000) begin
						count <= count +1;
						
				end
				else begin
						count <= 0;
				end
			end
		
		else begin
			flag <= 1'b1;
			if(count <= 4000000) begin
						count <= count +1;
				end
				else begin
						count <= 0;
				end
			end
			end
		if (rst) begin
			interrupt <= 1'b0;
		end
		else begin
			if(interrupt_ack == 1'b1)
			begin
				interrupt <= 1'b0;
			end
			else begin
//				if(count == 10000000 || (collison_detect^collison_detect_f))
				if (flag == 1'b0) begin
					if(count == 10000000 || collison_detect==1 )
					begin
						interrupt <= 1'b1;
					end
				end
				if (flag == 1'b1) begin
					if(count == 4000000 || collison_detect==1 )
					begin
					interrupt <= 1'b1;
					end
				end
			end
		end		
	end
endmodule
