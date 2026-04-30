# ==========================================================================
# 1. 创建边角 (Corner) 和 额外的电源/地 (PG) Pad
# ==========================================================================
# 创建 4 个角落的 Pad
create_cell {CornerLL CornerLR CornerTR CornerTL} PCORNERW

# 创建核心(Core)供电 Pad
create_cell {vss1_l vss1_r vss1_t vss1_b} PVSS1W
create_cell {vdd1_l vdd1_r vdd1_t vdd1_b} PVDD1W

# 创建环(IO)供电 Pad
create_cell {vss2_l vss2_r vss2_t vss2_b} PVSS2W
create_cell {vdd2_l vdd2_r vdd2_t vdd2_b} PVDD2W

# ==========================================================================
# 2. 绑定四个边角的位置
# 边框代号：1=左侧(Left), 2=顶部(Top), 3=右侧(Right), 4=底部(Bottom)
# ==========================================================================
set_pad_physical_constraints -pad_name "CornerTL" -side 1
set_pad_physical_constraints -pad_name "CornerTR" -side 2
set_pad_physical_constraints -pad_name "CornerLR" -side 3
set_pad_physical_constraints -pad_name "CornerLL" -side 4

# ==========================================================================
# 3. 绑定信号与供电 Pad 的位置
# ==========================================================================

# --------------------------------------------------------------------------
# 左侧 (Side 1): 时钟、复位、控制信号 + 输入特征 0~7
# --------------------------------------------------------------------------
set_pad_physical_constraints -pad_name "PIW_clk"   -side 1 -order 1
set_pad_physical_constraints -pad_name "PIW_rst_b" -side 1 -order 2
set_pad_physical_constraints -pad_name "PIW_en"    -side 1 -order 3
set_pad_physical_constraints -pad_name "PIW_start" -side 1 -order 4

# 左侧中间插入供电 Pad
set_pad_physical_constraints -pad_name "vdd2_l" -side 1 -order 5
set_pad_physical_constraints -pad_name "vdd1_l" -side 1 -order 6
set_pad_physical_constraints -pad_name "vss1_l" -side 1 -order 7
set_pad_physical_constraints -pad_name "vss2_l" -side 1 -order 8

# 放置 feature_in[0:7]
set order_idx 9
for {set i 0} {$i <= 7} {incr i} {
    set_pad_physical_constraints -pad_name "gen_piw_feature[$i].PIW_feature" -side 1 -order $order_idx
    incr order_idx
}

# --------------------------------------------------------------------------
# 顶部 (Side 2): 输入特征 8~19
# --------------------------------------------------------------------------
set order_idx 1
# 放置 feature_in[8:13]
for {set i 8} {$i <= 13} {incr i} {
    set_pad_physical_constraints -pad_name "gen_piw_feature[$i].PIW_feature" -side 2 -order $order_idx
    incr order_idx
}

# 顶部中间插入供电 Pad
set_pad_physical_constraints -pad_name "vdd2_t" -side 2 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vdd1_t" -side 2 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss1_t" -side 2 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss2_t" -side 2 -order $order_idx; incr order_idx

# 放置 feature_in[14:19]
for {set i 14} {$i <= 19} {incr i} {
    set_pad_physical_constraints -pad_name "gen_piw_feature[$i].PIW_feature" -side 2 -order $order_idx
    incr order_idx
}

# --------------------------------------------------------------------------
# 右侧 (Side 3): 输入特征 20~31
# --------------------------------------------------------------------------
set order_idx 1
# 放置 feature_in[20:25]
for {set i 20} {$i <= 25} {incr i} {
    set_pad_physical_constraints -pad_name "gen_piw_feature[$i].PIW_feature" -side 3 -order $order_idx
    incr order_idx
}

# 右侧中间插入供电 Pad
set_pad_physical_constraints -pad_name "vdd2_r" -side 3 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vdd1_r" -side 3 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss1_r" -side 3 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss2_r" -side 3 -order $order_idx; incr order_idx

# 放置 feature_in[26:31]
for {set i 26} {$i <= 31} {incr i} {
    set_pad_physical_constraints -pad_name "gen_piw_feature[$i].PIW_feature" -side 3 -order $order_idx
    incr order_idx
}

# --------------------------------------------------------------------------
# 底部 (Side 4): 输出结果 0~7 + done 信号
# --------------------------------------------------------------------------
set order_idx 1

set_pad_physical_constraints -pad_name "PO8W_done" -side 4 -order $order_idx; incr order_idx

# 放置 result_byte[0:3]
for {set i 0} {$i <= 3} {incr i} {
    set_pad_physical_constraints -pad_name "gen_po8w_result[$i].PO8W_result" -side 4 -order $order_idx
    incr order_idx
}

# 底部中间插入供电 Pad
set_pad_physical_constraints -pad_name "vdd2_b" -side 4 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vdd1_b" -side 4 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss1_b" -side 4 -order $order_idx; incr order_idx
set_pad_physical_constraints -pad_name "vss2_b" -side 4 -order $order_idx; incr order_idx

# 放置 result_byte[4:7]
for {set i 4} {$i <= 7} {incr i} {
    set_pad_physical_constraints -pad_name "gen_po8w_result[$i].PO8W_result" -side 4 -order $order_idx
    incr order_idx
}