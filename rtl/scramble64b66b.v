/******************************************Copyright@2022**************************************
									YUSUR CO. LTD. ALL rights reserved
								http://www.yusur.tech, http://www.carch.ac.cn
=========================================FILE INFO.============================================
FILE Name       : scramble64b66b.v
Last Update     : 2023/03/25 14:34:47
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/03/25 14:34:47
Version         : 1.0
Description     : the 64b66b scramble.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/
module scramble64b66b(
	input  	wire   				clk  	,
	input   wire   				rst_n	,

	input 	wire    [64-1:0]	data_i 	,
	input   wire    [2 -1:0] 	head_i	,
	input   wire    [6 -1:0]	seq_i   ,	
	input   wire    			en  	,

	output	reg		[64-1:0]	data_o 	,
	output  reg    	[2 -1:0] 	head_o  ,
	output  reg   	[6 -1:0]    seq_o 	,
	output  reg					vld    	 
);

reg [58-1:0] shift;

function [58-1:0] scramble_shift;
	input 				dat_in	;
	input  	[58-1:0]	s       ;
	reg  				xorbit	;
	begin
		xorbit 			= s[0] ^ s[19] ^ dat_in	;
		scramble_shift 	= {xorbit,s[57:1]}		;
	end
endfunction

function [58+64-1 : 0] scramble;
	// input [64-1:0] dat_in;
	// input [58-1:0] s     ;
	// integer i;
	// begin
	// 	for(i = 0;i < 64;i = i + 1)begin
	// 		s = scramble_shift(dat_in[i],s);
	// 		scramble[i] = s[57];
	// 	end
	// 	scramble[58+64-1 : 64]  = s;
	// end
	input 	[64-1:0] 	dat_in	;
	input 	[58-1:0] 	s     	;
	integer 			i		;
	reg		[58-1:0]	s_r		;
	begin
		s_r = s;
		for(i = 0;i < 64;i = i + 1)begin
			s_r = scramble_shift(dat_in[i],s_r);
			scramble[i] = s_r[57];
		end
		scramble[58+64-1 : 64]  = s_r;
	end
endfunction



always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		{shift,data_o} <= {{58{1'b1}},{64{1'b1}}};
		vld <= 1'b0;
		head_o <= 2'b00;
		seq_o <= 0;
	end
	else if(en)begin
		{shift,data_o} <= {scramble(data_i,shift)};
		vld <= 1'b1;
		head_o <= head_i;
		seq_o <= seq_i;
	end
	else begin
		{shift,data_o} <= {shift,data_o};
		vld <= 1'b0;
		head_o <= head_i;
		seq_o <= seq_i;
	end
end

endmodule
