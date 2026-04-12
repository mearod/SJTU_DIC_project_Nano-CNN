###################################################################
# SDC Constraints for CNN_Top Module
# Target Process: SMIC 180nm (Assumed based on PO8W library cell)
###################################################################
set sdc_version 2.1

# =========================================================================
# 1. Global Units and Design Rules
# =========================================================================
set_units -time ns -resistance kOhm -capacitance pF -power mW -voltage V -current mA
set_wire_load_mode segmented
set_max_transition 3.0 [current_design]

# =========================================================================
# 2. Environmental Attributes (Driving Cells & Loads)
# =========================================================================
# Clock & Control Pins
set_driving_cell -lib_cell PO8W -pin PAD [get_ports clk]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports rst_b]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports en]
set_driving_cell -lib_cell PO8W -pin PAD [get_ports start]

# Data Input Array (960 bits) - Using wildcard * to constrain all bits simultaneously
set_driving_cell -lib_cell PO8W -pin PAD [get_ports {feature_window*}]

# Output Loads
set_load -pin_load 4.37 [get_ports done]
set_load -pin_load 4.37 [get_ports {result0*}]
set_load -pin_load 4.37 [get_ports {result1*}]

# Set reset as an ideal network (disable timing/DRC checks on the reset tree)
set_ideal_network [get_ports rst_b]

# =========================================================================
# 3. Clock Definitions
# =========================================================================
# Target: 100 MHz (10ns period)
create_clock [get_ports clk] -period 10.0 -waveform {0 5.0}

# Clock Network Modeling (Latency and Jitter/Skew)
set_clock_latency 0.3 [get_clocks clk]
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock Transition Times
set_clock_transition -min -fall 0.2 [get_clocks clk]
set_clock_transition -min -rise 0.2 [get_clocks clk]
set_clock_transition -max -fall 0.2 [get_clocks clk]
set_clock_transition -max -rise 0.2 [get_clocks clk]

# =========================================================================
# 4. I/O Timing Constraints
# =========================================================================
# Input Delays: Assuming upstream logic consumes 4.0ns
set_input_delay -clock clk -max 4.0 [get_ports rst_b]
set_input_delay -clock clk -max 4.0 [get_ports en]
set_input_delay -clock clk -max 4.0 [get_ports start]
set_input_delay -clock clk -max 4.0 [get_ports {feature_window*}]

# Output Delays: Assuming downstream logic requires 4.0ns
set_output_delay -clock clk -max 4.0 [get_ports done]
set_output_delay -clock clk -max 4.0 [get_ports {result0*}]
set_output_delay -clock clk -max 4.0 [get_ports {result1*}]

###################################################################
# End of SDC
###################################################################