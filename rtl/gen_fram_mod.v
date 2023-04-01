/******************************************Copyright@2022**************************************
                                    AddiftUZT. zhanghx.  ALL rights reserved
                                        https://www.cnblogs.com/cnlntr/
=========================================FILE INFO.============================================
FILE Name       : gen_fram_mod.v
Last Update     : 2023/04/01 14:17:27
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/04/01 14:17:27
Version         : 1.0
Description     : gen_fram_mod.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/

module gen_fram_mod(
        input wire              clk     ,
        input wire              rst_n   ,
        
        output reg  [66-1:0]    dat_o   ,
        output reg              dat_vld ,
        input  wire             dat_rdy  
    );

localparam [66-1:0] IDLEFRAME = {2'b10,64'h000000000000001e};

reg     [7-1:0]     cnt_txframe     ;
wire                add_cnt_txframe ;
wire                end_cnt_txframe ;

reg [66-1:0] frame [11-1:0];
initial begin
    frame[0]  = {2'b10,64'hd555555555555578};
    frame[1]  = {2'b01,64'h8b0e380577200008};
    frame[2]  = {2'b01,64'h0045000800000000};
    frame[3]  = {2'b01,64'h061b0000661c2800};
    frame[4]  = {2'b01,64'h00004d590000d79e};
    frame[5]  = {2'b01,64'h0000eb4a2839d168};
    frame[6]  = {2'b01,64'h12500c7a00007730};
    frame[7]  = {2'b01,64'h000000008462d21e};
    frame[8]  = {2'b01,64'h79f7eb9300000000};
    frame[9]  = {2'b10,64'h0000000000000087};
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_txframe <= 0;
    end
    else if(add_cnt_txframe)begin
        if(end_cnt_txframe)
            cnt_txframe <= 0;
        else
            cnt_txframe <= cnt_txframe + 1;
        end
end
assign add_cnt_txframe = dat_rdy;
assign end_cnt_txframe = add_cnt_txframe && cnt_txframe == 128 - 1;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dat_o   <= 'd0;
        dat_vld <= 'd0;
    end
    else if(cnt_txframe >= 0 && cnt_txframe < 10 && add_cnt_txframe)begin
        dat_o   <= frame[cnt_txframe];
        dat_vld <= 1'b1;
    end
    // else begin
    //     dat_o   <= IDLEFRAME;
    //     dat_vld <= 1;
    // end
    else begin
        dat_o   <= 'd0;
        dat_vld <= 'd0;
    end
end

endmodule
