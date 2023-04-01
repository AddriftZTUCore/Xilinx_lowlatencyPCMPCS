/******************************************Copyright@2022**************************************
                                    AddiftUZT. zhanghx.  ALL rights reserved
                                        https://www.cnblogs.com/cnlntr/
=========================================FILE INFO.============================================
FILE Name       : top.v
Last Update     : 2023/04/01 14:19:09
Latest Versions : 1.0
========================================AUTHOR INFO.===========================================
Created by      : zhanghx
Create date     : 2023/04/01 14:19:09
Version         : 1.0
Description     : top.
=======================================UPDATE HISTPRY==========================================
Modified by     : 
Modified date   : 
Version         : 
Description     : 
*************************************Confidential. Do NOT disclose****************************/


module top(
    input   wire clk        ,
    input   wire gtrx_p     ,
    input   wire gtrx_n     ,
    output  wire gttx_p     ,
    output  wire gttx_n     ,
    input   wire gtrefclk_p ,
    input   wire gtrefclk_n  
);

wire          clk_100M  ;

wire          tx_clk    ;
wire          tx_rst_n  ;
wire          rx_clk    ;
wire          rx_rst_n  ;

wire [66-1:0] fram      ;
wire          fram_vld  ;
wire          fram_rdy  ;

wire [66-1:0] fram_out  ;
wire          fram_nd   ;

sys_mmcm u_sys_mmcm(
    // Clock out ports
    .clk_out1   (clk_100M),
    // Clock in ports
    .clk_in1    (clk     )
);  // input clk_in1


gen_fram_mod u_gen_fram_mod(
    .clk      ( tx_clk      ),
    .rst_n    ( tx_rst_n    ),

    .dat_o    ( fram        ),
    .dat_vld  ( fram_vld    ),
    .dat_rdy  ( fram_rdy    ) 
);

lowlatencypcmpcs_mod u_lowlatencypcmpcs_mod(
    .sys_clk    ( clk_100M          ),

    .gtrx_p     ( gtrx_p            ),
    .gtrx_n     ( gtrx_n            ),
    .gttx_p     ( gttx_p            ),
    .gttx_n     ( gttx_n            ),
    .gtrefclk_p ( gtrefclk_p        ),
    .gtrefclk_n ( gtrefclk_n        ),

    .dat_in     ( fram              ),
    .dat_vld    ( fram_vld          ),
    .dat_rdy    ( fram_rdy          ),
    .tx_clk     ( tx_clk            ),
    .tx_rst_n   ( tx_rst_n          ),

    .dat_out    ( fram_out[64-1: 0] ),
    .head_out   ( fram_out[66-1:64] ),
    .dat_nd     ( fram_nd           ),
    .rx_clk     ( rx_clk            ),
    .rx_rst_n   ( rx_rst_n          ) 
);


ila_0 u_ila_0 (
	.clk(tx_clk), // input wire clk

	.probe0(fram), // input wire [65:0]  probe0  
	.probe1(fram_vld), // input wire [0:0]  probe1 
	.probe2(fram_rdy) // input wire [0:0]  probe2
);

ila_1 u_ila_1 (
	.clk(rx_clk), // input wire clk

	.probe0(fram_out), // input wire [65:0]  probe0  
	.probe1(fram_nd) // input wire [0:0]  probe1
);


endmodule
