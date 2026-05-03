#gui_set_current_task -name {Design Planning}

######################################################################
# Initialize Floorplan
######################################################################
# Create corners and P/G pads and define all pad cell locations:
source pad_cell_cons.tcl

#initialize_floorplan -core_utilization 0.8 -left_io2core 30.0 -bottom_io2core 30.0 -right_io2core 30.0 -top_io2core 30.0
create_floorplan -core_utilization 0.48 -left_io2core 30.0 -bottom_io2core 30.0 -right_io2core 30.0 -top_io2core 30.0 
#-control_type width_and_height -core_width 1500 -core_height 500

source derive_pg.tcl
save_mw_cel -as 2_1_floorplan_init

#move_objects -to {300 300} [get_cells inst_idct/ram8x8_1/mem]
#move_objects -to {300 450} [get_cells inst_idct/ram8x8_2/mem]
# 确保在摆放宏单元前，已经执行了 create_floorplan！

# 1. 卷积层 (u_conv) 的 SRAM
move_objects -to {300 300}  [get_cells {inst_CNN_Top/u_cnn/u_conv/bias_rom/sram_inst}]
move_objects -to {300 450}  [get_cells {inst_CNN_Top/u_cnn/u_conv/weight_rom/sram_inst[0].u_sram}]
move_objects -to {300 600}  [get_cells {inst_CNN_Top/u_cnn/u_conv/weight_rom/sram_inst[1].u_sram}]
move_objects -to {300 750}  [get_cells {inst_CNN_Top/u_cnn/u_conv/weight_rom/sram_inst[2].u_sram}]
move_objects -to {300 900}  [get_cells {inst_CNN_Top/u_cnn/u_conv/weight_rom/sram_inst[3].u_sram}]
move_objects -to {300 1050} [get_cells {inst_CNN_Top/u_cnn/u_conv/weight_rom/sram_inst[4].u_sram}]

# 2. 深度卷积层 (u_dwconv) 的 SRAM
move_objects -to {300 1200} [get_cells {inst_CNN_Top/u_cnn/u_dwconv/bias_rom/sram_inst}]
move_objects -to {300 1350} [get_cells {inst_CNN_Top/u_cnn/u_dwconv/weight_rom/sram_inst}]

# 3. 逐点卷积层 (u_pwconv) 的 SRAM
move_objects -to {300 1500} [get_cells {inst_CNN_Top/u_cnn/u_pwconv/bias_rom/sram_inst}]
move_objects -to {300 1650} [get_cells {inst_CNN_Top/u_cnn/u_pwconv/weight_rom/sram_inst[0].u_sram}]
move_objects -to {300 1800} [get_cells {inst_CNN_Top/u_cnn/u_pwconv/weight_rom/sram_inst[1].u_sram}]

# 4. 后处理层 (u_postprocess) 的 SRAM
move_objects -to {300 1950} [get_cells {inst_CNN_Top/u_cnn/u_postprocess/u_postprocess_sigmoid/sram_inst0}]
move_objects -to {300 2150} [get_cells {inst_CNN_Top/u_cnn/u_postprocess/u_postprocess_sigmoid/sram_inst1}]
move_objects -to {300 2350} [get_cells {inst_CNN_Top/u_cnn/u_postprocess/u_linear_weightROM/sram_lo}]
move_objects -to {300 2550} [get_cells {inst_CNN_Top/u_cnn/u_postprocess/u_linear_weightROM/sram_hi}]

# 【非常重要】摆完之后，把这 15 个硬宏单元牢牢钉死在原地！
set_dont_touch_placement [get_cells -hier -filter "is_hard_macro == true"]

## Create placement blockage around the macro to avoid DRC violations
##  1. You can create the placement blockage in the GUI:
##	i. In the menu, find "Floorplan" -- "Create placement blockage ..."
##	ii. In the layout window, use the mouse to create the placement blockage 
##  2. Or, you can use commands, for example:
	source create_macro_placement_blockage.tcl
set_attribute [all_macro_cells] is_placed true
set_attribute [all_macro_cells] is_fixed true
save_mw_cel -as 2_2_floorplan_macro


### Build the power plan structure
source pns.tcl
commit_fp_rail
preroute_instances
preroute_standard_cells -fill_empty_rows -remove_floating_pieces
analyze_fp_rail -nets {VDD VSS} -voltage_supply 1.98 -pad_masters {PVSS1W PVDD1W}
save_mw_cel -as 2_3_floorplan_pns

set_pnet_options -complete "METAL4 METAL5"
create_fp_placement -timing_driven -no_hierarchy_gravity
route_zrt_global

#Perform timing analysis
redirect -tee ../reports/floorplan.timing { report_timing }
save_mw_cel -as 2_4_floorplan_complete

remove_placement -object_type standard_cell
write_def -version 5.6 -placed -all_vias -blockages -routed_nets -specialnets -rows_tracks_gcells -output ../outputs/CNN_Top.def
