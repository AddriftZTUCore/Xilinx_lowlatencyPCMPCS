set_property PACKAGE_PIN D6 [get_ports gtrefclk_n]
set_property PACKAGE_PIN J4 [get_ports gtrx_p]
set_property PACKAGE_PIN F17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_false_path -from [get_pins u_lowlatencypcmpcs_mod/pcspcm64b66b_i/inst/pcspcm64b66b_init_i/gt0_txresetfsm_i/tx_fsm_reset_done_int_reg/C] -to [all_registers]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets rx_clk]
