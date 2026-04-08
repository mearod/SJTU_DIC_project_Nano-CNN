#Library Setup
set search_path "$search_path ../rtl/cnn ../scripts ../../../SMIC18/lib ../../../SMIC18/mem ../work"
set target_lib   "slow.lib S018V3EBCDSP_X8Y4D128_PR.lib SP018W_V1p8_max.lib"
set link_priority     "* slow S018V3EBCDSP_X8Y4D128_PR SP018W_V1p8_max"

#source read.tcl
read_design -format verilog ../rtl/cnn/PE.v
read_design -format verilog ../rtl/cnn/FC_PE.v
read_design -format verilog ../rtl/cnn/relu.v
read_design -format verilog ../rtl/cnn/SRAM_32_256.v
read_design -format verilog ../rtl/cnn/rescale_conv.v
read_design -format verilog ../rtl/cnn/rescale_dwconv.v
read_design -format verilog ../rtl/cnn/rescale_pwconv.v
read_design -format verilog ../rtl/cnn/rescale_linear.v
read_design -format verilog ../rtl/cnn/maxpool_v2.v
read_design -format verilog ../rtl/cnn/SA1_channel.v
read_design -format verilog ../rtl/cnn/SA1.v
read_design -format verilog ../rtl/cnn/SA_channel_2.v
read_design -format verilog ../rtl/cnn/SA_2.v
read_design -format verilog ../rtl/cnn/SA_channel_3.v
read_design -format verilog ../rtl/cnn/SA_3.v
read_design -format verilog ../rtl/cnn/sramBuffer1.v
read_design -format verilog ../rtl/cnn/BUFFER_2.v
#read_design -format verilog ../rtl/cnn/BUFFER_3.v
read_design -format verilog ../rtl/cnn/FC.v
read_design -format verilog ../rtl/cnn/FF_8.v
read_design -format verilog ../rtl/cnn/FF_32.v
#read_design -format verilog ../rtl/cnn/FF_256.v
read_design -format verilog ../rtl/cnn/SigLUT.v
#read_design -format verilog ../rtl/cnn/Sigmoid.v
read_design -format verilog ../rtl/cnn/CNN_top.v
read_design -format verilog ../rtl/cnn/cnn_chip.v

set current_design cnn_chip

link_design
make_unique
source cnn.sdc

#Compile
optimize

#Clean-up
#Report
analyze_constraint -all_violators > ../reports/violators_clk_with_driving.rpt
analyze_area > ../reports/area_report_clk_with_driving.rpt
analyze_timing > ../reports/timing_report_clk_with_driving.rpt

###YBR
write_design -format verilog -hierarchy -o ../outputs/cnn_chip_clk_with_driving.v
write_sdc ../outputs/cnn_chip_clk_with_driving.sdc

