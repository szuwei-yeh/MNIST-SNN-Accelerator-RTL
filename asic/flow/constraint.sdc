# =============================================================
# constraint.sdc — Timing constraints for SNN Conv Core
# =============================================================

# Main clock — period matches config.mk CLOCK_PERIOD
create_clock [get_ports clk] -name clk -period 20.0

# Conservative IO timing (10% of clock period)
set_input_delay  -clock clk 2.0 [all_inputs]
set_output_delay -clock clk 2.0 [all_outputs]

# Async resets: no timing check needed
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports frame_rst_n]
