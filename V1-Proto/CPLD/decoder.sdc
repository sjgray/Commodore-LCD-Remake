# Commodore LCD MMU/Decoder Timing Constraints
# Target: EPM7128SLC84-15 (15ns speed grade)

# Main CPU clock - 65C102 can run up to 8 MHz (125ns period)
create_clock -name phi2 -period 125.0 [get_ports phi2]

# Input delays (signals from CPU, relative to phi2)
# Address and data are valid before phi2 rises
set_input_delay -clock phi2 -max 20.0 [get_ports {a[*]}]
set_input_delay -clock phi2 -min 0.0 [get_ports {a[*]}]
set_input_delay -clock phi2 -max 20.0 [get_ports {d[*]}]
set_input_delay -clock phi2 -min 0.0 [get_ports {d[*]}]
set_input_delay -clock phi2 -max 20.0 [get_ports rwb]
set_input_delay -clock phi2 -min 0.0 [get_ports rwb]

# Output delays (chip selects and memory address to external devices)
# Need to be stable during phi2 high
set_output_delay -clock phi2 -max 15.0 [get_ports {ma[*]}]
set_output_delay -clock phi2 -min 0.0 [get_ports {ma[*]}]
set_output_delay -clock phi2 -max 15.0 [get_ports {cs_*}]
set_output_delay -clock phi2 -min 0.0 [get_ports {cs_*}]

# Unused clocks - set as false paths or constrain loosely
set_false_path -from [get_ports osc]
set_false_path -from [get_ports cpu_clk]
set_false_path -from [get_ports vdc_dclk]
set_false_path -from [get_ports vdc_romram]
set_false_path -from [get_ports vdc_fontopt]
set_false_path -from [get_ports resetb]

# Unused outputs
set_false_path -to [get_ports {j2[*]}]
