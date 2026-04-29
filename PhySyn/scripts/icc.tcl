# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Global Design Variables (添加全局变量，方便以后一键替换)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set DESIGN_NAME "CNN_Top_clk_with_driving"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Logic Library settings
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
lappend search_path ~/Desktop/Workspace/SMIC18/db ../scripts ../design

# 【注意】这里我暂时保留了你旧代码中的两个SRAM。
# 如果你的新网表(CNN_Top)用到了 db 文件夹里的其他SRAM（比如 X64Y4D32 等），请把它们的名字加到下面这个字符串里，用空格隔开。
set macro_db "S018V3EBCDSP_X8Y4D72_PR.db S018V3EBCDSP_X8Y4D77_PR.db S018V3EBCDSP_X64Y4D16_PR.db S018V3EBCDSP_X64Y4D32_PR.db S018V3EBCDSP_X8Y4D128_PR.db S018V3EBCDSP_X8Y4D16_PR.db S018V3EBCDSP_X8Y4D32_PR.db"

set_app_var target_library "slow.db $macro_db"
set_app_var link_library "* slow.db SP018W_V1p5_max.db $macro_db"

set_min_library slow.db -min_version fast.db
set_min_library SP018W_V1p5_max.db -min_version SP018W_V1p5_min.db

# 使用 foreach 循环自动将所有宏单元的 min_library 设置为 -none，让代码更清爽
foreach db_file $macro_db {
    set_min_library $db_file -none
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Physical Library settings
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set mw_path "~/Desktop/Workspace/SMIC18/mw_lib"
set tech_file "~/Desktop/Workspace/SMIC18/tech/smic18_5lm.tf"
set tlup_map "~/Desktop/Workspace/SMIC18/tlup/smic018_5lm_map"
set tlup_max "~/Desktop/Workspace/SMIC18/tlup/smiclog018_5lm_cell_max.tluplus"
set tlup_min "~/Desktop/Workspace/SMIC18/tlup/smiclog018_5lm_cell_min.tluplus"

# 使用前面定义的变量来指定网表和SDC文件
set verilog_file "../design/${DESIGN_NAME}.v"
set sdc_file "../design/${DESIGN_NAME}.sdc"

set_app_var sh_enable_page_mode false

source run_data_setup.tcl
source run_design_planning.tcl
source run_placement.tcl
source run_cts.tcl
source run_route.tcl
source run_finishing.tcl