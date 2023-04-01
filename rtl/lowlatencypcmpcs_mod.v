`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/27 21:48:40
// Design Name: 
// Module Name: lowlatencypcmpcs_mod
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


module lowlatencypcmpcs_mod(
    /********* GTX *********/
    input   wire                sys_clk     ,
    input   wire                gtrx_p      ,
    input   wire                gtrx_n      ,
    output  wire                gttx_p      ,
    output  wire                gttx_n      ,
    input   wire                gtrefclk_p  ,
    input   wire                gtrefclk_n  ,

    input   wire    [66-1:0]    dat_in      ,
    input   wire                dat_vld     ,
    output  wire                dat_rdy     ,
    output  wire                tx_clk      ,
    output  wire                tx_rst_n   ,    

    output  wire    [64-1:0]    dat_out     ,
    output  wire    [2 -1:0]    head_out    ,
    output  wire                dat_nd      ,
    output  wire                rx_clk      ,
    output wire                 rx_rst_n     
);

    /*********** signal reset ***********/
    wire                    soft_reset_tx_in            ;
    wire                    soft_reset_rx_in            ;
    wire                    dont_reset_on_data_error_in ;
    wire                    gt0_tx_fsm_reset_done_out   ;
    wire                    gt0_rx_fsm_reset_done_out   ;
    wire                    rxresetdone                 ;
    wire                    txresetdone                 ;

    /*********** signal clock ***********/
    wire                    gt0_tx_mmcm_lock_out        ;
    wire                    gt0_rx_mmcm_lock_out        ;

    /*********** signal user tx data ***********/
    wire                    extxclk                     ;
    wire                    txuserrdy = 1'b1            ;
    wire    [64-1:0]        txdat                       ;
    wire    [2 -1:0]        txhead                      ;
    wire    [6 -1:0]        txseq                       ;
    wire                    gttx_rst_n                  ;


    /*********** signal user rx data ***********/
    wire                    exrxclk                     ;
    wire                    rx_lock_sync                ;
    wire                    rxuserrdy = 1'b1            ;
    wire    [64-1:0]        rxdat                       ;
    wire                    rxdat_vld                   ;
    wire    [2- 1:0]        rxhead                      ;
    wire                    rxhead_vld                  ;
    wire                    rxgearboxslip               ;

    /*********** signal drp ***********/
    wire    [9 -1:0]        gt0_drpaddr_in              ;
    wire    [16-1:0]        gt0_drpdi_in                ;
    wire    [16-1:0]        gt0_drpdo_out               ;
    wire                    gt0_drpen_in                ;
    wire                    gt0_drprdy_out              ;
    wire                    gt0_drpwe_in                ;

    /*********** signal loopback ***********/
    wire    [3 -1:0]        gt0_loopback_in             ;

    wire                    gt0_rxratedone_out          ;
    wire                    gt0_rxoutclkfabric_out      ;

    /*********** signal monitor ***********/
    //[7] - Internal clock
    //Adaptation loops:
    //[6:0] - RXOS, RXDFEVP, RXDFEUT
    //[5:0] - RXDFETAP2, RXDFETAP3
    //[4:0] - RXDFETAP4, RXDFETAP5
    //[4:1] - RXDFEAGC
    //[6:3] - RXDFELF (GTH transceiver only), RXLPMHF, RXLPMLF
    wire    [8 -1:0]        gt0_dmonitorout_out ;

    /*********** tx fifo ***********/
    wire                    gttx_fifo_ren       ;
    wire    [66-1:0]        gttx_fifo_rdat      ;
    wire                    gttx_fifo_empty     ;

    /*********** seq_togearbox ***********/
    wire    [66-1:0]        seq_togearbox_datin     ;
    wire                    seq_togearbox_vld       ;
    wire                    seq_togearbox_rdy       ;
    wire    [64-1:0]        seq_togearbox_dat_o     ;
    wire    [ 2-1:0]        seq_togearbox_dat_head_o;
    wire                    seq_togearbox_dat_vld_o ;
    wire    [ 6-1:0]        seq_togearbox_dat_seq   ;

    /*********** scramble64b66b ***********/
    wire    [64-1:0]        scramble64b66b_dat_in   ;   
    wire    [ 2-1:0]        scramble64b66b_head_in  ;
    wire    [ 6-1:0]        scramble64b66b_seq_i    ;
    wire                    scramble64b66b_en       ;                   

    /*********** reset ***********/
    assign soft_reset_tx_in             = 1'b0;
    assign soft_reset_rx_in             = 1'b0;
    assign dont_reset_on_data_error_in  = 1'b0;

    /*********** drp ***********/
    assign gt0_drpaddr_in               = 9'd0;
    assign gt0_drpdi_in                 = 16'd0;
    assign gt0_drpen_in                 = 1'b0;
    assign gt0_drpwe_in                 = 1'b0;

    /*********** loopback ***********/
    //000: Normal operation
    //001: Near-End PCS Loopback
    //010: Near-End PMA Loopback
    //011: Reserved
    //100: Far-End PMA Loopback
    //101: Reserved
    //110: Far-End PCS Loopback
    assign gt0_loopback_in              = 3'b000;

    assign tx_clk = extxclk;

    assign tx_rst_n  = gt0_tx_fsm_reset_done_out;
    assign gttx_rst_n = gt0_tx_fsm_reset_done_out;
    assign gtrx_rst_n = rxresetdone;

    assign seq_togearbox_vld   = dat_vld;
    assign seq_togearbox_datin = dat_in ;
    assign dat_rdy             = seq_togearbox_rdy;

    seq_togearbox u_seq_togearbox(
        .clk     ( exrxclk                  ),
        .rst_n   ( gttx_rst_n               ),

        .dat_i   ( seq_togearbox_datin      ),
        .vld     ( seq_togearbox_vld        ),
        .rdy     ( seq_togearbox_rdy        ),

        .dat_o   ( seq_togearbox_dat_o      ),
        .head_o  ( seq_togearbox_dat_head_o ),
        .vld_o   ( seq_togearbox_dat_vld_o  ),
        .seq     ( seq_togearbox_dat_seq    ) 
    );

    assign scramble64b66b_dat_in    =   seq_togearbox_dat_o     ;
    assign scramble64b66b_head_in   =   seq_togearbox_dat_head_o;
    assign scramble64b66b_seq_i     =   seq_togearbox_dat_seq   ;
    assign scramble64b66b_en        =   seq_togearbox_dat_vld_o ;

    scramble64b66b u_scramble64b66b(
        .clk     ( exrxclk                  ),
        .rst_n   ( gttx_rst_n               ),
        .data_i  ( scramble64b66b_dat_in    ),
        .head_i  ( scramble64b66b_head_in   ),
        .seq_i   ( scramble64b66b_seq_i     ),
        .en      ( scramble64b66b_en        ),
        .data_o  ( txdat                    ),
        .head_o  ( txhead                   ),
        .seq_o   ( txseq                    ),
        .vld     (                          )
    );

    pcspcm64b66b  pcspcm64b66b_i
    (
     .soft_reset_tx_in(soft_reset_tx_in), // input wire soft_reset_tx_in
     .soft_reset_rx_in(soft_reset_rx_in), // input wire soft_reset_rx_in
     .dont_reset_on_data_error_in(dont_reset_on_data_error_in), // input wire dont_reset_on_data_error_in
     .q1_clk0_gtrefclk_pad_n_in(gtrefclk_p), // input wire q1_clk0_gtrefclk_pad_n_in
     .q1_clk0_gtrefclk_pad_p_in(gtrefclk_n), // input wire q1_clk0_gtrefclk_pad_p_in
     .gt0_tx_mmcm_lock_out(gt0_tx_mmcm_lock_out), // output wire gt0_tx_mmcm_lock_out
     .gt0_rx_mmcm_lock_out(gt0_rx_mmcm_lock_out), // output wire gt0_rx_mmcm_lock_out
     .gt0_tx_fsm_reset_done_out(gt0_tx_fsm_reset_done_out), // output wire gt0_tx_fsm_reset_done_out
     .gt0_rx_fsm_reset_done_out(gt0_rx_fsm_reset_done_out), // output wire gt0_rx_fsm_reset_done_out
     .gt0_data_valid_in(rx_lock_sync), // input wire gt0_data_valid_in

    .gt0_txusrclk_out(), // output wire gt0_txusrclk_out
    .gt0_txusrclk2_out(extxclk), // output wire gt0_txusrclk2_out
    .gt0_rxusrclk_out(), // output wire gt0_rxusrclk_out
    .gt0_rxusrclk2_out(exrxclk), // output wire gt0_rxusrclk2_out
    //_________________________________________________________________________
    //GT0  (X0Y3)
    //____________________________CHANNEL PORTS________________________________
    //-------------------------- Channel - DRP Ports  --------------------------
        .gt0_drpaddr_in                 (gt0_drpaddr_in), // input wire [8:0] gt0_drpaddr_in
        .gt0_drpdi_in                   (gt0_drpdi_in), // input wire [15:0] gt0_drpdi_in
        .gt0_drpdo_out                  (gt0_drpdo_out), // output wire [15:0] gt0_drpdo_out
        .gt0_drpen_in                   (gt0_drpen_in), // input wire gt0_drpen_in
        .gt0_drprdy_out                 (gt0_drprdy_out), // output wire gt0_drprdy_out
        .gt0_drpwe_in                   (gt0_drpwe_in), // input wire gt0_drpwe_in
    //------------------------- Digital Monitor Ports --------------------------
        .gt0_dmonitorout_out            (gt0_dmonitorout_out), // output wire [7:0] gt0_dmonitorout_out
    //----------------------------- Loopback Ports -----------------------------
        .gt0_loopback_in                (gt0_loopback_in), // input wire [2:0] gt0_loopback_in
    //--------------------------- PCI Express Ports ----------------------------
        .gt0_rxrate_in                  (3'b000), // input wire [2:0] gt0_rxrate_in
    //------------------- RX Initialization and Reset Ports --------------------
        .gt0_eyescanreset_in            (1'b0), // input wire gt0_eyescanreset_in
        .gt0_rxuserrdy_in               (rxuserrdy), // input wire gt0_rxuserrdy_in
    //------------------------ RX Margin Analysis Ports ------------------------
        .gt0_eyescandataerror_out       (), // output wire gt0_eyescandataerror_out
        .gt0_eyescantrigger_in          (1'b0), // input wire gt0_eyescantrigger_in
    //----------------------- Receive Ports - CDR Ports ------------------------
        .gt0_rxcdrhold_in               (1'b0), // input wire gt0_rxcdrhold_in
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
        .gt0_rxdata_out                 (rxdat), // output wire [63:0] gt0_rxdata_out
    //----------------- Receive Ports - Pattern Checker Ports ------------------
        .gt0_rxprbserr_out              (), // output wire gt0_rxprbserr_out
        .gt0_rxprbssel_in               (3'b000), // input wire [2:0] gt0_rxprbssel_in
    //----------------- Receive Ports - Pattern Checker ports ------------------
        .gt0_rxprbscntreset_in          (1'b0), // input wire gt0_rxprbscntreset_in
    //------------------------- Receive Ports - RX AFE -------------------------
        .gt0_gtxrxp_in                  (gtrx_p), // input wire gt0_gtxrxp_in
    //---------------------- Receive Ports - RX AFE Ports ----------------------
        .gt0_gtxrxn_in                  (gtrx_n), // input wire gt0_gtxrxn_in
    //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
        .gt0_rxbufreset_in              (1'b0), // input wire gt0_rxbufreset_in
        .gt0_rxbufstatus_out            (    ), // output wire [2:0] gt0_rxbufstatus_out
    //------------------- Receive Ports - RX Equalizer Ports -------------------
        .gt0_rxdfelpmreset_in           (1'b0), // input wire gt0_rxdfelpmreset_in
        .gt0_rxmonitorout_out           (), // output wire [6:0] gt0_rxmonitorout_out
        .gt0_rxmonitorsel_in            (2'b00), // input wire [1:0] gt0_rxmonitorsel_in
    //---------- Receive Ports - RX Fabric ClocK Output Control Ports ----------
        .gt0_rxratedone_out             (gt0_rxratedone_out), // output wire gt0_rxratedone_out
    //------------- Receive Ports - RX Fabric Output Control Ports -------------
        .gt0_rxoutclkfabric_out         (     ), // output wire gt0_rxoutclkfabric_out
    //-------------------- Receive Ports - RX Gearbox Ports --------------------
        .gt0_rxdatavalid_out            (rxdat_vld), // output wire gt0_rxdatavalid_out
        .gt0_rxheader_out               (rxhead), // output wire [1:0] gt0_rxheader_out
        .gt0_rxheadervalid_out          (rxhead_vld), // output wire gt0_rxheadervalid_out
    //------------------- Receive Ports - RX Gearbox Ports  --------------------
        .gt0_rxgearboxslip_in           (rxgearboxslip), // input wire gt0_rxgearboxslip_in
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
        .gt0_gtrxreset_in               (1'b0), // input wire gt0_gtrxreset_in
        .gt0_rxpcsreset_in              (1'b0), // input wire gt0_rxpcsreset_in
        .gt0_rxpmareset_in              (1'b0), // input wire gt0_rxpmareset_in
    //---------------- Receive Ports - RX Margin Analysis ports ----------------
        .gt0_rxlpmen_in                 (1'b0), // input wire gt0_rxlpmen_in
    //--------------- Receive Ports - RX Polarity Control Ports ----------------
        .gt0_rxpolarity_in              (1'b0), // input wire gt0_rxpolarity_in
    //------------ Receive Ports -RX Initialization and Reset Ports ------------
        .gt0_rxresetdone_out            (rxresetdone), // output wire gt0_rxresetdone_out
    //---------------------- TX Configurable Driver Ports ----------------------
        .gt0_txpostcursor_in            (5'b00000), // input wire [4:0] gt0_txpostcursor_in
        .gt0_txprecursor_in             (5'b00000), // input wire [4:0] gt0_txprecursor_in
    //------------------- TX Initialization and Reset Ports --------------------
        .gt0_gttxreset_in               (1'b0), // input wire gt0_gttxreset_in
        .gt0_txuserrdy_in               (txuserrdy), // input wire gt0_txuserrdy_in
    //---------------- Transmit Ports - Pattern Generator Ports ----------------
        .gt0_txprbsforceerr_in          (1'b0), // input wire gt0_txprbsforceerr_in
    //-------------------- Transmit Ports - TX Buffer Ports --------------------
        .gt0_txbufstatus_out            (), // output wire [1:0] gt0_txbufstatus_out
    //------------- Transmit Ports - TX Configurable Driver Ports --------------
        .gt0_txdiffctrl_in              (4'b0000), // input wire [3:0] gt0_txdiffctrl_in
        .gt0_txinhibit_in               (1'b0), // input wire gt0_txinhibit_in
        .gt0_txmaincursor_in            (7'b0000), // input wire [6:0] gt0_txmaincursor_in
    //---------------- Transmit Ports - TX Data Path interface -----------------
        .gt0_txdata_in                  (txdat), // input wire [63:0] gt0_txdata_in
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
        .gt0_gtxtxn_out                 (gttx_n), // output wire gt0_gtxtxn_out
        .gt0_gtxtxp_out                 (gttx_p), // output wire gt0_gtxtxp_out
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        .gt0_txoutclkfabric_out         (), // output wire gt0_txoutclkfabric_out
        .gt0_txoutclkpcs_out            (), // output wire gt0_txoutclkpcs_out
    //------------------- Transmit Ports - TX Gearbox Ports --------------------
        .gt0_txheader_in                (txhead), // input wire [1:0] gt0_txheader_in
        .gt0_txsequence_in              ({1'b0,txseq}), // input wire [6:0] gt0_txsequence_in
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
        .gt0_txpcsreset_in              (1'b0), // input wire gt0_txpcsreset_in
        .gt0_txpmareset_in              (1'b0), // input wire gt0_txpmareset_in
        .gt0_txresetdone_out            (txresetdone), // output wire gt0_txresetdone_out
    //--------------- Transmit Ports - TX Polarity Control Ports ---------------
        .gt0_txpolarity_in              (1'b0), // input wire gt0_txpolarity_in
    //---------------- Transmit Ports - pattern Generator Ports ----------------
        .gt0_txprbssel_in               (3'b000), // input wire [2:0] gt0_txprbssel_in

    //____________________________COMMON PORTS________________________________
    .gt0_qplllock_out(), // output wire gt0_qplllock_out
    .gt0_qpllrefclklost_out(), // output wire gt0_qpllrefclklost_out
    .gt0_qplloutclk_out(), // output wire gt0_qplloutclk_out 
    .gt0_qplloutrefclk_out(), // output wire gt0_qplloutrefclk_out
    .sysclk_in(sys_clk) // input wire sysclk_in
);

    get_sync_head u_get_sync_head(
        .clk       ( exrxclk        ),
        .rst_n     ( gtrx_rst_n     ),
        .en        ( rxhead_vld     ),
        .dat_i     ( rxhead         ),
        .slid_vld  ( rxgearboxslip  ),
        .locked    ( rx_lock_sync   )
    );

    descramble64b66b u_descramble64b66b(
        .clk     ( exrxclk          ),
        .rst_n   ( rx_lock_sync     ),
        .data_i  ( rxdat            ),
        .head_i  ( rxhead           ),
        .en      ( rxdat_vld        ),
        .data_o  ( dat_out          ),
        .head_o  ( head_out         ),
        .vld     ( dat_nd           )
    );

assign rx_clk = exrxclk;
assign rx_rst_n = rx_lock_sync;

endmodule
