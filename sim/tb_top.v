`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/31 23:51:26
// Design Name: 
// Module Name: tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_top;

reg                    sys_clk     ;
wire                   gtrx_p      ;
wire                   gtrx_n      ;
wire                   gttx_p      ;
wire                   gttx_n      ;
wire                   gtrefclk_p  ;
wire                   gtrefclk_n  ;

parameter REFCYCLE  = 6400;
parameter SYSCYCLE  = 10000;

reg refclk;

initial refclk = 1;
always #(REFCYCLE/2) refclk = ~refclk;

initial sys_clk = 1;
always #(SYSCYCLE/2) sys_clk = ~sys_clk;


assign gtrefclk_p = refclk;
assign gtrefclk_n = ~refclk;

assign gtrx_p = gttx_p;
assign gtrx_n = gttx_n;

top u_top(
    .clk         ( sys_clk      ),
    .gtrx_p      ( gtrx_p      ),
    .gtrx_n      ( gtrx_n      ),
    .gttx_p      ( gttx_p      ),
    .gttx_n      ( gttx_n      ),
    .gtrefclk_p  ( gtrefclk_p  ),
    .gtrefclk_n  ( gtrefclk_n  )
);

endmodule
