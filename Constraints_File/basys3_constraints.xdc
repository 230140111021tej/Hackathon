############################
# CLOCK (100 MHz)
############################
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]


############################
# SWITCHES (sw[15:0])
############################
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2  [get_ports {sw[8]}]
set_property PACKAGE_PIN T3  [get_ports {sw[9]}]
set_property PACKAGE_PIN T2  [get_ports {sw[10]}]
set_property PACKAGE_PIN R3  [get_ports {sw[11]}]
set_property PACKAGE_PIN W2  [get_ports {sw[12]}]
set_property PACKAGE_PIN U1  [get_ports {sw[13]}]
set_property PACKAGE_PIN T1  [get_ports {sw[14]}]
set_property PACKAGE_PIN R2  [get_ports {sw[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]


############################
# BUTTONS (CORRECT BASYS3)
############################

# btnC → RESET
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# btnU → START
set_property PACKAGE_PIN T18 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

# btnL → EMERGENCY STOP
set_property PACKAGE_PIN W19 [get_ports emergency_stop]
set_property IOSTANDARD LVCMOS33 [get_ports emergency_stop]

# btnR → OVERCURRENT
set_property PACKAGE_PIN T17 [get_ports overcurrent]
set_property IOSTANDARD LVCMOS33 [get_ports overcurrent]


############################
# LED OUTPUTS (CLEAN MAPPING)
############################

# Fault (VERY IMPORTANT → visible)
set_property PACKAGE_PIN U16 [get_ports fault_flag]
set_property IOSTANDARD LVCMOS33 [get_ports fault_flag]

# Phase A
set_property PACKAGE_PIN E19 [get_ports pwm_a_high]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_a_high]

set_property PACKAGE_PIN U19 [get_ports pwm_a_low]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_a_low]

# Phase B
set_property PACKAGE_PIN V19 [get_ports pwm_b_high]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_b_high]

set_property PACKAGE_PIN W18 [get_ports pwm_b_low]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_b_low]

# Phase C
set_property PACKAGE_PIN U15 [get_ports pwm_c_high]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_c_high]

set_property PACKAGE_PIN U14 [get_ports pwm_c_low]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_c_low]
