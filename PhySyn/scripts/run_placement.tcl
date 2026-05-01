# IC Compiler run script for idct_floorplan_complete
report_ignored_layers
report_pnet_options
source ndr.tcl
check_physical_design -stage pre_place_opt
check_physical_constraints
save_mw_cel -as 3_1_place_setup

# --- 在 place_opt 之前加上以下内容 ---
# 1. 移除前端可能带入的“理想网络”假象，让 ICC 直面真实的物理延时
remove_ideal_network [get_ports rst_b]
remove_ideal_network [get_ports en]

# 2. 开启高扇出网络自动综合 (Auto High-Fanout Synthesis)，允许工具疯狂插 Buffer
set_ahfs_options -remove_effort high
set_ahfs_options -enable_port_punching true

#set_separate_process_options -placement false
place_opt
redirect -tee ../reports/placement.timing { report_timing }
report_design -physical
report_qor
report_power
save_mw_cel -as 3_2_place_complete
