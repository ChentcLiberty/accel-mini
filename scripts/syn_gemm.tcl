#======================================================
# GEMM Accelerator Synthesis Script
# Technology: Nangate 45nm Open Cell Library
# Target: 100MHz (10ns period)
#======================================================

puts "========================================"
puts "Starting Synthesis..."
puts "========================================"

# 库路径
set PDK_PATH /home/jjt/install/pdk/nangate45

# 设置库
set target_library  "$PDK_PATH/stdcells.db"
set link_library    "* $target_library"

# 搜索路径
set search_path [concat $search_path ../rtl $PDK_PATH]

# 读取 RTL
puts "Reading RTL files..."
analyze -format verilog {pe.v pe_array.v gemm_ctrl.v gemm_mem.v gemm_top.v gemm_axi.v}
elaborate gemm_axi

# 设置顶层
current_design gemm_axi
link
check_design

# 时序约束
puts "Applying constraints..."
create_clock -period 10 -name clk [get_ports aclk]
set_clock_uncertainty 0.1 [get_clocks clk]

set_input_delay  2 -clock clk [remove_from_collection [all_inputs] [get_ports aclk]]
set_output_delay 2 -clock clk [all_outputs]

# 面积优化
set_max_area 0

# 综合
puts "Running synthesis..."
compile_ultra

# 生成报告
puts "Generating reports..."
report_area -hierarchy > ../results/syn_area.rpt
report_timing -max_paths 10 > ../results/syn_timing.rpt
report_power -analysis_effort high > ../results/syn_power.rpt
report_qor > ../results/syn_qor.rpt
report_cell > ../results/syn_cells.rpt

# 输出网表
write -format verilog -hierarchy -output ../results/gemm_axi_netlist.v
write -format ddc -hierarchy -output ../results/gemm_axi.ddc
write_sdc ../results/gemm_axi.sdc

# 打印摘要
puts "========================================"
puts "Synthesis Complete!"
puts "========================================"
puts ""
puts "=== Area Summary ==="
report_area

puts ""
puts "=== Timing Summary ==="
report_timing -max_paths 3

puts ""
puts "=== Power Summary ==="
report_power

exit
