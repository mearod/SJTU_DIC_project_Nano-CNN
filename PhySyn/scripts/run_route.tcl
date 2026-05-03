source common_optimization_settings_icc.tcl
source common_placement_settings.tcl
source common_post_cts_timing_settings.tcl
source common_route_si_settings_zrt_icc.tcl

report_constraint -all
all_ideal_nets
all_high_fanout -nets -threshold 501
report_preferred_routing_direction
report_tlu_plus_files
check_legality
verify_pg_nets

set_route_zrt_common_options -post_detail_route_redundant_via_insertion medium
set_route_zrt_detail_options -optimize_wire_via_effort_level high

report_routing_rules; 
report_route_opt_strategy; 
report_route_zrt_common_options; 
report_route_zrt_global_options; 
report_route_zrt_track_options; 
report_route_zrt_detail_options; 

# =========================================================================
# 【关键修复 1】：强制提取时钟树的 RC 寄生参数
set_extraction_options -max_pins 100000

# 【新增修复 2】：开启全时钟域的 Hold Time（保持时间）自动修复！
# 这句话能让工具自动插小 Buffer，完美消灭那 -0.02ns 的 Hold 违例
set_fix_hold [all_clocks]
# =========================================================================

route_opt -initial_route_only
redirect -tee ../reports/route_initial1.timing { report_timing }
report_clock_tree -summary
report_clock_timing -type skew
report_qor
report_constraint -all
save_mw_cel -as 5_route_0

route_opt -skip_initial_route  -power
save_mw_cel -as 5_route_1
redirect -tee ../reports/route_power1.timing { report_timing }

source derive_pg.tcl
verify_zrt_route
verify_lvs  

route_opt -incremental  
save_mw_cel -as 5_route_2

# =========================================================================
# 【关键修复 3】：专门修复 Max Trans/Cap 违例
echo "SCRIPT-Info: Running Design Rule fixing..."
set_route_opt_strategy -fix_design_rule_effort high
route_opt -only_design_rule
save_mw_cel -as 5_route_3_drv_fixed

# 【新增修复 4】：暴力多轮 ECO 寻线，强行解开最后的 13 个物理短路 (Shorts)！
# 默认只跑几次可能解不开死结，这里放宽到 20 次，让布线器死磕到底
echo "SCRIPT-Info: Running intense ECO route to fix remaining shorts..."
route_zrt_eco -max_number_of_iterations 20

# 跑完立刻检查，确认 Short 是否变成了 0
verify_zrt_route
# =========================================================================

report_design_physical -route
save_mw_cel -as 5_route_final