# Create corners and P/G pads
create_cell {CornerLL CornerLR CornerTR CornerTL} PCORNERW
create_cell {vss1_l vss1_r vss1_t vss1_b} PVSS1W
create_cell {vdd1_l vdd1_r vdd1_t vdd1_b} PVDD1W
create_cell {vss2_l vss2_r vss2_t vss2_b} PVSS2W
create_cell {vdd2_l vdd2_r vdd2_t vdd2_b} PVDD2W

# Define corner pad locations
set_pad_physical_constraints -pad_name "CornerTL" -side 1
set_pad_physical_constraints -pad_name "CornerTR" -side 2
set_pad_physical_constraints -pad_name "CornerLR" -side 3
set_pad_physical_constraints -pad_name "CornerLL" -side 4

# Define signal and PG pad locations

# Left side
set_pad_physical_constraints -pad_name "PIW_clk" -side 1 -order 1
set_pad_physical_constraints -pad_name "PIW_rstn" -side 1 -order 2
set_pad_physical_constraints -pad_name "PIW_enable" -side 1 -order 3
set_pad_physical_constraints -pad_name "PIW_din0" -side 1 -order 4
set_pad_physical_constraints -pad_name "PIW_din1" -side 1 -order 5
set_pad_physical_constraints -pad_name "PIW_din2" -side 1 -order 6
set_pad_physical_constraints -pad_name "PIW_din3" -side 1 -order 7
set_pad_physical_constraints -pad_name "vdd2_l" -side 1 -order 8
set_pad_physical_constraints -pad_name "vdd1_l" -side 1 -order 9
set_pad_physical_constraints -pad_name "vss1_l" -side 1 -order 10
set_pad_physical_constraints -pad_name "vss2_l" -side 1 -order 11
set_pad_physical_constraints -pad_name "PIW_din4" -side 1 -order 12
set_pad_physical_constraints -pad_name "PIW_din5" -side 1 -order 13
set_pad_physical_constraints -pad_name "PIW_din6" -side 1 -order 14
set_pad_physical_constraints -pad_name "PIW_din7" -side 1 -order 15
set_pad_physical_constraints -pad_name "PIW_din8" -side 1 -order 16
set_pad_physical_constraints -pad_name "PIW_din9" -side 1 -order 17
set_pad_physical_constraints -pad_name "PIW_din10" -side 1 -order 18
set_pad_physical_constraints -pad_name "PIW_din11" -side 1 -order 19
set_pad_physical_constraints -pad_name "PIW_din12" -side 1 -order 20
set_pad_physical_constraints -pad_name "PIW_din13" -side 1 -order 21
set_pad_physical_constraints -pad_name "PIW_din14" -side 1 -order 22
set_pad_physical_constraints -pad_name "PIW_din15" -side 1 -order 23
set_pad_physical_constraints -pad_name "PIW_din16" -side 1 -order 24
set_pad_physical_constraints -pad_name "PIW_din17" -side 1 -order 25
set_pad_physical_constraints -pad_name "PIW_din18" -side 1 -order 26
set_pad_physical_constraints -pad_name "PIW_din19" -side 1 -order 27
set_pad_physical_constraints -pad_name "PIW_din20" -side 1 -order 28
set_pad_physical_constraints -pad_name "PIW_din21" -side 1 -order 29
set_pad_physical_constraints -pad_name "PIW_din22" -side 1 -order 30
set_pad_physical_constraints -pad_name "PIW_din23" -side 1 -order 31
set_pad_physical_constraints -pad_name "PIW_din24" -side 1 -order 32
set_pad_physical_constraints -pad_name "PIW_din25" -side 1 -order 33
set_pad_physical_constraints -pad_name "PIW_din26" -side 1 -order 34
set_pad_physical_constraints -pad_name "PIW_din27" -side 1 -order 35

# Top side
set_pad_physical_constraints -pad_name "PIW_din28" -side 2 -order 1
set_pad_physical_constraints -pad_name "PIW_din29" -side 2 -order 2
set_pad_physical_constraints -pad_name "PIW_din30" -side 2 -order 3
set_pad_physical_constraints -pad_name "PIW_din31" -side 2 -order 4
set_pad_physical_constraints -pad_name "PIW_din32" -side 2 -order 5
set_pad_physical_constraints -pad_name "PIW_din33" -side 2 -order 6
set_pad_physical_constraints -pad_name "vdd2_t" -side 2 -order 7
set_pad_physical_constraints -pad_name "vdd1_t" -side 2 -order 8
set_pad_physical_constraints -pad_name "vss1_t" -side 2 -order 9
set_pad_physical_constraints -pad_name "vss2_t" -side 2 -order 10
set_pad_physical_constraints -pad_name "PIW_din34" -side 2 -order 11
set_pad_physical_constraints -pad_name "PIW_din35" -side 2 -order 12
set_pad_physical_constraints -pad_name "PIW_din36" -side 2 -order 13
set_pad_physical_constraints -pad_name "PIW_din37" -side 2 -order 14
set_pad_physical_constraints -pad_name "PIW_din38" -side 2 -order 15
set_pad_physical_constraints -pad_name "PIW_din39" -side 2 -order 16
set_pad_physical_constraints -pad_name "PIW_din40" -side 2 -order 17
set_pad_physical_constraints -pad_name "PIW_din41" -side 2 -order 18
set_pad_physical_constraints -pad_name "PIW_din42" -side 2 -order 19
set_pad_physical_constraints -pad_name "PIW_din43" -side 2 -order 20
set_pad_physical_constraints -pad_name "PIW_din44" -side 2 -order 21
set_pad_physical_constraints -pad_name "PIW_din45" -side 2 -order 22
set_pad_physical_constraints -pad_name "PIW_din46" -side 2 -order 23
set_pad_physical_constraints -pad_name "PIW_din47" -side 2 -order 24
set_pad_physical_constraints -pad_name "PIW_din48" -side 2 -order 25
set_pad_physical_constraints -pad_name "PIW_din49" -side 2 -order 26
set_pad_physical_constraints -pad_name "PIW_din50" -side 2 -order 27
set_pad_physical_constraints -pad_name "PIW_din51" -side 2 -order 28
set_pad_physical_constraints -pad_name "PIW_din52" -side 2 -order 29
set_pad_physical_constraints -pad_name "PIW_din53" -side 2 -order 30
set_pad_physical_constraints -pad_name "PIW_din54" -side 2 -order 31
set_pad_physical_constraints -pad_name "PIW_din55" -side 2 -order 32
set_pad_physical_constraints -pad_name "PO8W_enable_out" -side 2 -order 33
set_pad_physical_constraints -pad_name "PO8W_dout0" -side 2 -order 34
set_pad_physical_constraints -pad_name "PO8W_dout1" -side 2 -order 35

# Right side
set_pad_physical_constraints -pad_name "PO8W_dout2" -side 3 -order 1
set_pad_physical_constraints -pad_name "PO8W_dout3" -side 3 -order 2
set_pad_physical_constraints -pad_name "PO8W_dout4" -side 3 -order 3
set_pad_physical_constraints -pad_name "PO8W_dout5" -side 3 -order 4
set_pad_physical_constraints -pad_name "PO8W_dout6" -side 3 -order 5
set_pad_physical_constraints -pad_name "vdd2_r" -side 3 -order 6
set_pad_physical_constraints -pad_name "vdd1_r" -side 3 -order 7
set_pad_physical_constraints -pad_name "vss1_r" -side 3 -order 8
set_pad_physical_constraints -pad_name "vss2_r" -side 3 -order 9
set_pad_physical_constraints -pad_name "PO8W_dout7" -side 3 -order 10
set_pad_physical_constraints -pad_name "PO8W_dout8" -side 3 -order 11
set_pad_physical_constraints -pad_name "PO8W_dout9" -side 3 -order 12
set_pad_physical_constraints -pad_name "PO8W_dout10" -side 3 -order 13
set_pad_physical_constraints -pad_name "PO8W_dout11" -side 3 -order 14
set_pad_physical_constraints -pad_name "PO8W_dout12" -side 3 -order 15
set_pad_physical_constraints -pad_name "PO8W_dout13" -side 3 -order 16
set_pad_physical_constraints -pad_name "PO8W_dout14" -side 3 -order 17
set_pad_physical_constraints -pad_name "PO8W_dout15" -side 3 -order 18
set_pad_physical_constraints -pad_name "PO8W_dout16" -side 3 -order 19
set_pad_physical_constraints -pad_name "PO8W_dout17" -side 3 -order 20
set_pad_physical_constraints -pad_name "PO8W_dout18" -side 3 -order 21
set_pad_physical_constraints -pad_name "PO8W_dout19" -side 3 -order 22
set_pad_physical_constraints -pad_name "PO8W_dout20" -side 3 -order 23
set_pad_physical_constraints -pad_name "PO8W_dout21" -side 3 -order 24
set_pad_physical_constraints -pad_name "PO8W_dout22" -side 3 -order 25
set_pad_physical_constraints -pad_name "PO8W_dout23" -side 3 -order 26
set_pad_physical_constraints -pad_name "PO8W_dout24" -side 3 -order 27
set_pad_physical_constraints -pad_name "PO8W_dout25" -side 3 -order 28
set_pad_physical_constraints -pad_name "PO8W_dout26" -side 3 -order 29
set_pad_physical_constraints -pad_name "PO8W_dout27" -side 3 -order 30
set_pad_physical_constraints -pad_name "PO8W_dout28" -side 3 -order 31
set_pad_physical_constraints -pad_name "PO8W_dout29" -side 3 -order 32
set_pad_physical_constraints -pad_name "PO8W_dout30" -side 3 -order 33
set_pad_physical_constraints -pad_name "PO8W_dout31" -side 3 -order 34
set_pad_physical_constraints -pad_name "PO8W_dout32" -side 3 -order 35

# Bottom side
set_pad_physical_constraints -pad_name "PO8W_dout33" -side 4 -order 1
set_pad_physical_constraints -pad_name "PO8W_dout34" -side 4 -order 2
set_pad_physical_constraints -pad_name "vdd2_b" -side 4 -order 3
set_pad_physical_constraints -pad_name "vdd1_b" -side 4 -order 4
set_pad_physical_constraints -pad_name "vss1_b" -side 4 -order 5
set_pad_physical_constraints -pad_name "vss2_b" -side 4 -order 6
set_pad_physical_constraints -pad_name "PO8W_dout35" -side 4 -order 7
set_pad_physical_constraints -pad_name "PO8W_dout36" -side 4 -order 8
set_pad_physical_constraints -pad_name "PO8W_dout37" -side 4 -order 9
set_pad_physical_constraints -pad_name "PO8W_dout38" -side 4 -order 10
set_pad_physical_constraints -pad_name "PO8W_dout39" -side 4 -order 11
set_pad_physical_constraints -pad_name "PO8W_dout40" -side 4 -order 12
set_pad_physical_constraints -pad_name "PO8W_dout41" -side 4 -order 13
set_pad_physical_constraints -pad_name "PO8W_dout42" -side 4 -order 14
set_pad_physical_constraints -pad_name "PO8W_dout43" -side 4 -order 15
set_pad_physical_constraints -pad_name "PO8W_dout44" -side 4 -order 16
set_pad_physical_constraints -pad_name "PO8W_dout45" -side 4 -order 17
set_pad_physical_constraints -pad_name "PO8W_dout46" -side 4 -order 18
set_pad_physical_constraints -pad_name "PO8W_dout47" -side 4 -order 19
set_pad_physical_constraints -pad_name "PO8W_dout48" -side 4 -order 20
set_pad_physical_constraints -pad_name "PO8W_dout49" -side 4 -order 21
set_pad_physical_constraints -pad_name "PO8W_dout50" -side 4 -order 22
set_pad_physical_constraints -pad_name "PO8W_dout51" -side 4 -order 23
set_pad_physical_constraints -pad_name "PO8W_dout52" -side 4 -order 24
set_pad_physical_constraints -pad_name "PO8W_dout53" -side 4 -order 25
set_pad_physical_constraints -pad_name "PO8W_dout54" -side 4 -order 26
set_pad_physical_constraints -pad_name "PO8W_dout55" -side 4 -order 27
set_pad_physical_constraints -pad_name "PO8W_dout56" -side 4 -order 28
set_pad_physical_constraints -pad_name "PO8W_dout57" -side 4 -order 29
set_pad_physical_constraints -pad_name "PO8W_dout58" -side 4 -order 30
set_pad_physical_constraints -pad_name "PO8W_dout59" -side 4 -order 31
set_pad_physical_constraints -pad_name "PO8W_dout60" -side 4 -order 32
set_pad_physical_constraints -pad_name "PO8W_dout61" -side 4 -order 33
set_pad_physical_constraints -pad_name "PO8W_dout62" -side 4 -order 34
set_pad_physical_constraints -pad_name "PO8W_dout63" -side 4 -order 35

