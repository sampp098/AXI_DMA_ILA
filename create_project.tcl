set proj_dir ./$proj_name
set bd_tcl_dir ./scripts
set board vision_som
set device k26
set rev None
set output {xsa}
#set xdc_list {./xdc/pin.xdc}


set proj_board [get_board_parts "*:kv260_som:*" -latest_file_version]
create_project -name $proj_name -force -dir $proj_dir -part [get_property PART_NAME [get_board_parts $proj_board]]
set_property board_part $proj_board [current_project]

#import_files -fileset constrs_1 $xdc_list

set_property board_connections {som240_1_connector xilinx.com:kv260_carrier:som240_1_connector:1.3}  [current_project]


update_ip_catalog

# Create block diagram design and set as current design
set design_name $proj_name
create_bd_design $proj_name
current_bd_design $proj_name


#Adding PS and setting the PS Config

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__FPGA_PL1_ENABLE {0} CONFIG.PSU__USE__S_AXI_GP0 {1} CONFIG.PSU__USE__S_AXI_GP1 {1}] [get_bd_cells zynq_ultra_ps_e_0]

#PS CLOCK connection

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/saxihpc0_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/saxihpc1_fpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]

#importing the AXI_Cache HDL

add_files -norecurse -scan_for_includes {./hdl/AXIS_Cache_HDL_v1_0.vhd ./hdl/AXIS_Cache_HDL_v1_0_S_AXI_CTRL.vhd}
import_files -norecurse {./hdl/AXIS_Cache_HDL_v1_0.vhd ./hdl/AXIS_Cache_HDL_v1_0_S_AXI_CTRL.vhd}

create_bd_cell -type module -reference AXIS_Cache_HDL_v1_0 AXIS_Cache_HDL_v1_0_0

#Ading Axi DMA
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0
endgroup
set_property -dict [list CONFIG.c_sg_length_width {20} CONFIG.c_sg_include_stscntrl_strm {0} CONFIG.c_mm2s_burst_size {256} CONFIG.c_s2mm_burst_size {256}] [get_bd_cells axi_dma_0]

#adding Block Memory for the SG
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]

#adding AXI BRAM controler

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]
copy_bd_objs /  [get_bd_cells {axi_bram_ctrl_0}]

#adding AXI SmartConnect
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]

#adding AXI Interconnect

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
copy_bd_objs /  [get_bd_cells {axi_interconnect_0}]

#addin axi timer
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 axi_timer_0
endgroup
set_property -dict [list CONFIG.mode_64bit {1}] [get_bd_cells axi_timer_0]

#adding axi interconnect for rest modues
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2
endgroup
set_property -dict [list CONFIG.NUM_MI {4}] [get_bd_cells axi_interconnect_2]

#Wiring
connect_bd_intf_net [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]

connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC0_FPD] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC1_FPD]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

set_property location {0.5 -215 462} [get_bd_cells axi_dma_0]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins AXIS_Cache_HDL_v1_0_0/m_axis_output]
connect_bd_intf_net [get_bd_intf_pins AXIS_Cache_HDL_v1_0_0/s_axis_input] [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins axi_dma_0/M_AXI_MM2S]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_SG] [get_bd_intf_pins smartconnect_0/S00_AXI]
regenerate_bd_layout

startgroup
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells zynq_ultra_ps_e_0]
endgroup


connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins AXIS_Cache_HDL_v1_0_0/s_axi_ctrl]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M01_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M02_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]

connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M03_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_dma_0/m_axi_sg_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_dma_0/s_axi_lite_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/M00_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_1/ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_1/M00_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_2/ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_2/M00_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_2/M03_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_2/S00_ACLK]
endgroup

regenerate_bd_layout

#Debug
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_dma_0_M_AXIS_MM2S}]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {AXIS_Cache_HDL_v1_0_0_m_axis_output}]
startgroup
connect_bd_net -net row_or_col_o [get_bd_pins AXIS_Cache_HDL_v1_0_0/row_or_col_o]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {row_or_col_o }]
endgroup
startgroup
connect_bd_net -net write_stream_done_o [get_bd_pins AXIS_Cache_HDL_v1_0_0/write_stream_done_o]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {write_stream_done_o }]
endgroup
startgroup
connect_bd_net -net read_stream_done_o [get_bd_pins AXIS_Cache_HDL_v1_0_0/read_stream_done_o]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {read_stream_done_o }]
endgroup
startgroup
connect_bd_net -net start_read_stream_pulse_o [get_bd_pins AXIS_Cache_HDL_v1_0_0/start_read_stream_pulse_o]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {start_read_stream_pulse_o }]
endgroup
startgroup
connect_bd_net -net start_write_stream_pulse_o [get_bd_pins AXIS_Cache_HDL_v1_0_0/start_write_stream_pulse_o]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {start_write_stream_pulse_o }]
endgroup
startgroup
connect_bd_net -net start_read_stream_monitor [get_bd_pins AXIS_Cache_HDL_v1_0_0/start_read_stream_monitor]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {start_read_stream_monitor }]
endgroup
startgroup
connect_bd_net -net start_write_stream_monitor [get_bd_pins AXIS_Cache_HDL_v1_0_0/start_write_stream_monitor]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {start_write_stream_monitor }]
endgroup
startgroup
connect_bd_net -net read_stream_pointer_monitor [get_bd_pins AXIS_Cache_HDL_v1_0_0/read_stream_pointer_monitor]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {read_stream_pointer_monitor }]
endgroup
startgroup
connect_bd_net -net write_stream_pointer_monitor [get_bd_pins AXIS_Cache_HDL_v1_0_0/write_stream_pointer_monitor]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_nets {write_stream_pointer_monitor }]
endgroup

apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_intf_nets axi_dma_0_M_AXIS_MM2S] {AXIS_SIGNALS "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "New" APC_EN "0" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_intf_nets AXIS_Cache_HDL_v1_0_0_m_axis_output] {AXIS_SIGNALS "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" APC_EN "0" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets read_stream_done_o] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets read_stream_pointer_monitor] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets row_or_col_o] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets start_read_stream_monitor] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets start_read_stream_pulse_o] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets start_write_stream_monitor] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets start_write_stream_pulse_o] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets write_stream_done_o] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
                                                          [get_bd_nets write_stream_pointer_monitor] {PROBE_TYPE "Data and Trigger" CLK_SRC "/zynq_ultra_ps_e_0/pl_clk0" SYSTEM_ILA "Auto" } \
                                                         ]


                                                         
