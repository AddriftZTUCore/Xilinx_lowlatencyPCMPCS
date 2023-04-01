/******************************************Copyright@2022**************************************
									AddiftUZT. zhanghx.  ALL rights reserved
										https://www.cnblogs.com/cnlntr/
=========================================FILE INFO.============================================
FILE Name       : get_sync_head.v
Last Update     : 2023/04/01 14:17:51
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/04/01 14:17:51
Version         : 1.0
Description     : get_sync_head.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/
module get_sync_head(
	input  wire         clk    		,
	input  wire   		rst_n		,
	input  wire			en			,
	input  wire	[2-1:0]	dat_i 		,

	output reg 			slid_vld 	,
	output reg 			locked	  
);
parameter MAXVLD  = 64;
parameter MAXIVLD = 16;

localparam 	IDLE 		= 	5'b00001,
			RESET_CNT	=	5'b00010,
			TEST_SH     =   5'b00100,
			GOOD        =   5'b01000,
			SLIP        =   5'b10000;

reg		[5-1:0] 	state_c					;
reg 	[5-1:0] 	state_n					;
wire        		idl2resetcnt_start		;
wire        		resetcnt2testsh_start	;
wire        		testsh2resetcnt_start	;
wire        		testsh2good_start		;
wire        		testsh2slip_start		;
wire   				good2resetcnt_start		;
wire     			slip2resetcnt_start		;

reg 	[6-1:0] 	cnt_sh					;
wire 				add_cnt_sh				;
wire   				end_cnt_sh				;

reg     [6-1:0]		cnt_invalid_sh			;
wire    			add_cnt_invalid_sh		;
wire   				end_cnt_invalid_sh		;

wire    			sh_invalid				;

reg   				sycflag  				;

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		sycflag <= 1'b0;
	else if((dat_i == 2'b10) && en)
		sycflag <= 1'b1;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		state_c <= IDLE;
	else
		state_c <= state_n;
end

always @(*)begin
	case (state_c)
		IDLE: begin
			if(idl2resetcnt_start)
				state_n = RESET_CNT;
			else
				state_n = state_c;
		end
		RESET_CNT: begin
			if(resetcnt2testsh_start)
				state_n = TEST_SH;
			else
				state_n = state_c;
		end
		TEST_SH: begin
			if(testsh2resetcnt_start)
				state_n = RESET_CNT;
			else if(testsh2good_start)
				state_n = GOOD;
			else if(testsh2slip_start)
				state_n = SLIP;
			else
				state_n = state_c;
		end
		GOOD: begin
			if(good2resetcnt_start)
				state_n = RESET_CNT;
			else
				state_n = state_c;
		end
		SLIP: begin
			if(slip2resetcnt_start)
				state_n = RESET_CNT;
			else
				state_n = state_c;
		end
		default: begin
			state_n = IDLE;
		end
	endcase
end

assign idl2resetcnt_start 	 = sycflag								;
assign resetcnt2testsh_start = 1'b1									;
assign testsh2resetcnt_start = (cnt_invalid_sh >  0) && end_cnt_sh	;
assign testsh2good_start	 = (cnt_invalid_sh == 0) && end_cnt_sh	;
assign testsh2slip_start	 = end_cnt_invalid_sh                 	;
assign good2resetcnt_start   = 1'b1								  	;
assign slip2resetcnt_start	 = 1'b1							      	;

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt_sh <= 0;
	end
	else if(state_c == RESET_CNT)begin
		cnt_sh <= 0;
	end
	else if(add_cnt_sh)begin
		if(end_cnt_sh)
			cnt_sh <= 0;
		else
			cnt_sh <= cnt_sh + 1;
	end
end
assign add_cnt_sh = (state_c == TEST_SH) && en;
assign end_cnt_sh = add_cnt_sh && cnt_sh == MAXVLD - 1;

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cnt_invalid_sh <= 0;
	end
	else if(state_c == RESET_CNT)begin
		cnt_invalid_sh <= 0;
	end
	else if(add_cnt_invalid_sh)begin
		if(end_cnt_invalid_sh)
			cnt_invalid_sh <= 0;
		else
			cnt_invalid_sh <= cnt_invalid_sh + 1;
		end
	end
assign add_cnt_invalid_sh = (state_c == TEST_SH) && sh_invalid;
assign end_cnt_invalid_sh = add_cnt_invalid_sh && cnt_invalid_sh == MAXIVLD - 1 ;

assign sh_invalid = en && ((dat_i == 2'b11) || (dat_i == 2'b00));

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		locked <= 1'b0;
	else if(state_c == GOOD)
		locked <= 1'b1;
	else if(state_c == SLIP)
		locked <= 1'b0;
end

always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		slid_vld <= 1'b0;
	else if(state_c == SLIP)
		slid_vld <= 1'b1;
	else
		slid_vld <= 1'b0;
end

endmodule
