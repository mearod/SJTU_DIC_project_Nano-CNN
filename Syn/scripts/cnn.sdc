###################################################################
# SDC for CNN_Top (Generated based on User RTL)
# Target Frequency: 100MHz (10ns period) - 可根据需求修改
###################################################################
set sdc_version 2.1

# =========================================================================
# 1. 单位设置 (全局)
# =========================================================================
set_units -time ns -resistance kOhm -capacitance pF -power mW -voltage V -current mA
set_wire_load_mode segmented
set_max_transition 3.0 [current_design]

# =========================================================================
# 2. 时钟与复位定义 (Clock & Reset)
# =========================================================================
# 创建 10ns 周期的主时钟 (100MHz)
create_clock [get_ports clk] -name clk -period 10.0 -waveform {0 5.0}

# 时钟的非理想特性 (抖动与跳变)
set_clock_uncertainty 0.5 [get_clocks clk]
set_clock_transition -min -fall 0.2 [get_clocks clk]
set_clock_transition -min -rise 0.2 [get_clocks clk]
set_clock_transition -max -fall 0.2 [get_clocks clk]
set_clock_transition -max -rise 0.2 [get_clocks clk]

# 设置复位信号为理想网络 (综合时不插入 buffer 去优化复位树，留给后端做)
set_ideal_network [get_ports rst_b]

# =========================================================================
# 3. 输入端约束 (Input Constraints)
# =========================================================================
# 假设上游逻辑消耗了 5ns 的时间 (留给本模块 5ns 预算)
set_input_delay -clock clk -max 5.0 [get_ports rst_b]
set_input_delay -clock clk -max 5.0 [get_ports en]
set_input_delay -clock clk -max 5.0 [get_ports start]

# 使用通配符批量约束 2400 bits 的 feature_map 输入
set_input_delay -clock clk -max 5.0 [get_ports {feature_map*}]

# 设定输入引脚的驱动单元 (沿用你的 PO8W 库单元)
set_driving_cell -lib_cell PO8W -pin PAD [get_ports clk]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports rst_b]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports en]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports start]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports {feature_map*}]

# =========================================================================
# 4. 输出端约束 (Output Constraints)
# =========================================================================
# 假设下游逻辑需要 5ns 的准备时间
set_output_delay -clock clk -max 5.0 [get_ports done]

# 使用通配符批量约束 32 bits 的 FP32 输出总线
set_output_delay -clock clk -max 5.0 [get_ports {result0*}]
set_output_delay -clock clk -max 5.0 [get_ports {result1*}]

# 设定输出引脚的外部负载电容 (沿用你的 4.37 pF)
set_load -pin_load 4.37 [get_ports done]
set_load -pin_load 4.37 [get_ports {result0*}]
set_load -pin_load 4.37 [get_ports {result1*}]