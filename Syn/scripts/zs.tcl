#Library Setup
set search_path "$search_path ../rtl/cnn ../scripts ../../../LIB/mem ../../../SMIC18/lib ../work"

# 把标准单元库 (slow.lib)、IO库 (SP018W...) 和所有的 SRAM 库全部放进 target_lib
set target_lib "slow.lib SP018W_V1p8_max.lib S018V3EBCDSP_X8Y4D16_PR_tt_1.8_25.lib S018V3EBCDSP_X8Y4D32_PR_tt_1.8_25.lib S018V3EBCDSP_X8Y4D72_PR_tt_1.8_25.lib S018V3EBCDSP_X8Y4D77_PR_tt_1.8_25.lib S018V3EBCDSP_X8Y4D128_PR_tt_1.8_25.lib S018V3EBCDSP_X64Y4D16_PR_tt_1.8_25.lib S018V3EBCDSP_X64Y4D32_PR_tt_1.8_25.lib"

# link_priority 同样需要包含所有的库名字（去掉 .lib 后缀，最前面保留 *）
set link_priority "* slow SP018W_V1p8_max S018V3EBCDSP_X8Y4D16_PR_tt_1.8_25 S018V3EBCDSP_X8Y4D32_PR_tt_1.8_25 S018V3EBCDSP_X8Y4D72_PR_tt_1.8_25 S018V3EBCDSP_X8Y4D77_PR_tt_1.8_25 S018V3EBCDSP_X8Y4D128_PR_tt_1.8_25 S018V3EBCDSP_X64Y4D16_PR_tt_1.8_25 S018V3EBCDSP_X64Y4D32_PR_tt_1.8_25"

# =========================================================================
# Read SystemVerilog Files (.sv)
# =========================================================================
read_design -format sverilog ../rtl/cnn/Buffer_4x32x8.sv
read_design -format sverilog ../rtl/cnn/cnn.sv
read_design -format sverilog ../rtl/cnn/CNN_Top.sv
read_design -format sverilog ../rtl/cnn/Conv.sv
read_design -format sverilog ../rtl/cnn/Conv_BiasRom.sv
read_design -format sverilog ../rtl/cnn/Conv_MultAdd.sv
read_design -format sverilog ../rtl/cnn/Conv_MultAdd_cell.sv
read_design -format sverilog ../rtl/cnn/Conv_WeightRom.sv
read_design -format sverilog ../rtl/cnn/DWconv.sv
read_design -format sverilog ../rtl/cnn/DWconv_BiasRom.sv
read_design -format sverilog ../rtl/cnn/DWconv_MultAdd.sv
read_design -format sverilog ../rtl/cnn/DWconv_MultAdd_cell.sv
read_design -format sverilog ../rtl/cnn/DWconv_WeightRom.sv
read_design -format sverilog ../rtl/cnn/FIFO_2x4X8.sv
read_design -format sverilog ../rtl/cnn/PWconv.sv
read_design -format sverilog ../rtl/cnn/PWconv_BiasRom.sv
read_design -format sverilog ../rtl/cnn/PWconv_MultAdd.sv
read_design -format sverilog ../rtl/cnn/PWconv_MultAdd_cell.sv
read_design -format sverilog ../rtl/cnn/PWconv_WeightRom.sv

# =========================================================================
# Read Verilog Files (.v)
# =========================================================================
read_design -format verilog ../rtl/cnn/PostProcess.v
read_design -format verilog ../rtl/cnn/PostProcess_Linear.v
read_design -format verilog ../rtl/cnn/PostProcess_Linear_1group.v
read_design -format verilog ../rtl/cnn/PostProcess_Linear_BiasSelector.v
read_design -format verilog ../rtl/cnn/PostProcess_Linear_WeightROM.v
read_design -format verilog ../rtl/cnn/PostProcess_Maxpool.v
read_design -format verilog ../rtl/cnn/PostProcess_Rescale.v
read_design -format verilog ../rtl/cnn/PostProcess_Sigmoid.v
read_design -format verilog ../rtl/cnn/Rescale.v
read_design -format verilog ../rtl/cnn/RescaleReLu.v
read_design -format verilog ../rtl/cnn/RescaleRelu_Mult.v
read_design -format verilog ../rtl/cnn/RescaleRelu_ShifterReLu.v
read_design -format verilog ../rtl/cnn/Rescale_Shifter.v

# =========================================================================
# Note: SRAM simulation models (S018V3EBCDSP_*.v and asdrlspkb*.v) 
# have been intentionally excluded from read_design to prevent synthesis errors.
# =========================================================================

# Set Top Module and Link
set current_design CNN_Top

link_design
make_unique

# Source the newly generated SDC file
source CNN_Top.sdc

# Compile
optimize

# Clean-up / Report
analyze_constraint -all_violators > ../reports/violators_clk_with_driving.rpt
analyze_area > ../reports/area_report_clk_with_driving.rpt
analyze_timing > ../reports/timing_report_clk_with_driving.rpt

### Output Generation
write_design -format verilog -hierarchy -o ../outputs/CNN_Top_clk_with_driving.v
write_sdc ../outputs/CNN_Top_clk_with_driving.sdc