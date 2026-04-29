# Script step 1 - Data Setup and Basic Flow
#

# 1. 使用变量替换掉写死的 cnn_chip，避免冲突和残留
exec rm -rf ../${DESIGN_NAME}.mw
#
############################################################
# Create Milkyway Design Library
############################################################

# 2. 将所有用到的 SRAM 的物理库路径添加进去（注意去掉了 .db 后缀，且为了可读性做了换行对齐）
create_mw_lib ../${DESIGN_NAME}.mw -open -technology $tech_file -mw_reference_library  "\
    $mw_path/smic18_5ml \
    $mw_path/SP018W_V1p5_5MT \
    $mw_path/S018V3EBCDSP_X8Y4D72_PR \
    $mw_path/S018V3EBCDSP_X8Y4D77_PR \
    $mw_path/S018V3EBCDSP_X64Y4D16_PR \
    $mw_path/S018V3EBCDSP_X64Y4D32_PR \
    $mw_path/S018V3EBCDSP_X8Y4D128_PR \
    $mw_path/S018V3EBCDSP_X8Y4D16_PR \
    $mw_path/S018V3EBCDSP_X8Y4D32_PR"

############################################################
# Load the netlist, constraints and controls.
############################################################

# 3. 将 -top 改为你的新顶层模块名
# 【必查】：请确认 CNN_Top_clk_with_driving.v 中的 module 名称是否就叫 CNN_Top。
# 如果 module 名称和文件名一模一样，这里也可以直接写成 -top ${DESIGN_NAME}
import_designs $verilog_file -format verilog -top CNN_Top 

############################################################
# Load TLU+ files
############################################################
set_tlu_plus_files -max_tluplus $tlup_max -min_tluplus $tlup_min -tech2itf_map  $tlup_map

check_library
check_tlu_plus_files
list_libs

source derive_pg.tcl
check_mv_design -power_nets

read_sdc $sdc_file
check_timing
report_timing_requirements
report_disable_timing
report_case_analysis
report_clock
report_clock -skew
redirect -tee ../reports/data_setup.timing { report_timing }

source opt_ctrl.tcl
source zic_timing.tcl
#exec cat zic.timing
#remove_ideal_network [get_ports scan_en]
save_mw_cel -as 1_datasetup