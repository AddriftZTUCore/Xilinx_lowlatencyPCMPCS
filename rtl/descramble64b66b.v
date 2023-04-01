/******************************************Copyright@2022**************************************
                                    AddiftUZT. zhanghx.  ALL rights reserved
                                    https://www.cnblogs.com/cnlntr/
=========================================FILE INFO.============================================
FILE Name       : descramble64b66b.v
Last Update     : 2023/04/01 14:17:09
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/04/01 14:17:09
Version         : 1.0
Description     : descramble64b66b.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/

module descramble64b66b(
	input  	wire   				clk  	,
	input   wire   				rst_n	,

	input 	wire    [64-1:0]	data_i 	,
    input   wire    [2 -1:0]    head_i  ,
	input   wire    			en  	,
	output	reg		[64-1:0]	data_o 	,
    output  reg     [2 -1:0]    head_o  ,
	output  reg					vld    	 
);
localparam [66-1:0] IDLEFRAME = {2'b10,64'h000000000000001e};

reg [58-1:0] shift;

function [58-1:0] descramble_shift;
    input           data_in ;
    input [58-1:0]  s       ;
    begin
        descramble_shift = {data_in,s[57:1]};
    end
endfunction

function [58+64-1 : 0] descramble;
    // input [64-1:0] data_in ;
    // input [58-1:0] s       ;
    // integer i;
    // begin
    //     for(i = 0;i < 64;i = i + 1)begin
    //         descramble[i] = s[0] ^ s[19] ^ data_in[i];
    //         s = descramble_shift(data_in[i],s);
    //     end
    //     descramble[58+64-1:64] = s;
    // end
    input   [64-1:0]    data_in ;
    input   [58-1:0]    s       ;
    integer             i       ;
    reg     [58-1:0]    s_r     ;
    begin
        s_r = s;
        for(i = 0;i < 64;i = i + 1)begin
            descramble[i] = s_r[0] ^ s_r[19] ^ data_in[i];
            s_r = descramble_shift(data_in[i],s_r);
        end
        descramble[58+64-1:64] = s_r;
    end
endfunction

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        {shift,data_o} <= {{58{1'b1}},{64{1'b0}}};
        vld <= 1'b0;
        head_o <= 2'b00;
    end
    else if(en)begin
        {shift,data_o} <= descramble(data_i,shift);
        vld <= 1'b1;
        head_o <= head_i;
    end
    else begin
        {shift,data_o} <= {shift,IDLEFRAME[64-1:0]};
        vld <= 1'b0;
        head_o <= IDLEFRAME[66-1:64];
    end
end

endmodule
