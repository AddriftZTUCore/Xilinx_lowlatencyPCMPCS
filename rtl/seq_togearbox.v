/******************************************Copyright@2022**************************************
                                    AddiftUZT. zhanghx.  ALL rights reserved
                                        https://www.cnblogs.com/cnlntr/
=========================================FILE INFO.============================================
FILE Name       : seq_togearbox.v
Last Update     : 2023/04/01 14:18:57
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/04/01 14:18:57
Version         : 1.0
Description     : seq_togearbox.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/
module seq_togearbox(
    input   wire                clk     ,
    input   wire                rst_n   ,

    input   wire    [66-1:0]    dat_i   ,
    input   wire                vld     ,
    output  reg                 rdy     ,

    output  reg     [64-1:0]    dat_o   ,
    output  reg     [2 -1:0]    head_o  ,
    output  reg                 vld_o   , 
    output  reg     [6 -1:0]    seq        
);

localparam [66-1:0] IDLEFRAME = {2'b10,64'h000000000000001e};

reg     [6-1:0]     cnt_seq     ;
wire                add_cnt_seq ;
wire                end_cnt_seq ;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_seq <= 0;
    end
    else if(add_cnt_seq)begin
        if(end_cnt_seq)
            cnt_seq <= 0;
        else
            cnt_seq <= cnt_seq + 1;
    end
end
assign add_cnt_seq = 1'b1;
assign end_cnt_seq = add_cnt_seq && cnt_seq == 33 - 1;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rdy <= 1'b1;
    else if(cnt_seq == 32 - 1 && add_cnt_seq)
        rdy <= 1'b0;
    else
        rdy <= 1'b1;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        {head_o,dat_o} <= 66'd0     ;
        seq            <= 6'd0      ;
        vld_o          <= 0;
    end
    else if(rdy)begin
        if(vld)begin
            {head_o,dat_o} <= dat_i     ;
            seq            <= cnt_seq   ;
            vld_o          <= 1         ;
        end
        else begin
            {head_o,dat_o} <= IDLEFRAME ;
            seq            <= cnt_seq   ;
            vld_o          <= 1         ;
        end
    end
    else begin
        {head_o,dat_o} <= {head_o,dat_o};
        seq            <= seq           ;
        vld_o          <= 0             ;
    end
end

endmodule
