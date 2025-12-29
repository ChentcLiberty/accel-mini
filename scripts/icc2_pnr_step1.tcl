# ========================================
# ICC2 Place & Route - Step 1: 设计导入
# ========================================

set PDK_PATH "/home/jjt/install/pdk/nangate45"
set DESIGN_NAME "gemm_axi"

# 1. 创建设计库并关联 NDM 参考库
puts "Creating design library..."
create_lib ${DESIGN_NAME}.ndm \
    -technology ${PDK_PATH}/rtk-tech.tf \
    -ref_libs {./work_icc2/nangate45_stdcells.ndm}

# 2. 验证参考库是否正确加载
puts "\nVerifying reference library..."
set cells [get_lib_cells nangate45_stdcells/* -quiet]
puts "Standard cells found: [sizeof_collection $cells]"

if {[sizeof_collection $cells] < 100} {
    puts "ERROR: Reference library not loaded correctly!"
    exit 1
}

# 3. 读取综合后的网表
puts "\nReading netlist..."
read_verilog ../results/${DESIGN_NAME}_netlist.v

# 4. 链接设计
puts "\nLinking design..."
current_design ${DESIGN_NAME}
link_block

# 5. 读取时序约束
puts "\nReading constraints..."
read_sdc ../results/${DESIGN_NAME}.sdc

# 6. 保存设计
puts "\nSaving design..."
save_lib

# 7. 生成初步报告
puts "\nGenerating reports..."
report_lib nangate45_stdcells > ../reports/icc2/step1_lib_check.rpt
report_references -nosplit > ../reports/icc2/step1_ref_check.rpt
report_design > ../reports/icc2/step1_design.rpt

puts "\n========================================="
puts "Step 1 completed successfully!"
puts "Design: ${DESIGN_NAME}"
puts "Cells: [sizeof_collection $cells] standard cells"
puts "========================================="

close_lib
exit
