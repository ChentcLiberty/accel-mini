# ========================================
# ICC2 Step 1: Design Import
# ========================================

set PDK_PATH "/home/jjt/install/pdk/nangate45"
set DESIGN_NAME "gemm_axi"

puts "================================================"
puts "Starting ICC2 Step 1: Design Import"
puts "================================================"

# 1. Create design library
puts ""
puts "Step 1: Creating design library..."
create_lib ${DESIGN_NAME}.ndm \
    -technology ${PDK_PATH}/rtk-tech.tf \
    -ref_libs {./work_icc2/nangate45_stdcells.ndm}

puts "Done: Library created"

# 2. Verify reference library
puts ""
puts "Step 2: Verifying reference library..."
set cells [get_lib_cells nangate45_stdcells/* -quiet]
puts "Found [sizeof_collection $cells] standard cells"

if {[sizeof_collection $cells] < 100} {
    puts "ERROR: Reference library incomplete!"
    exit 1
}

# 3. Read netlist
puts ""
puts "Step 3: Reading netlist..."
read_verilog ../results/${DESIGN_NAME}_netlist.v
puts "Done: Netlist read"

# 4. Link design
puts ""
puts "Step 4: Linking design..."
current_design ${DESIGN_NAME}
link_block
puts "Done: Design linked"

# 5. Read constraints
puts ""
puts "Step 5: Reading SDC constraints..."
read_sdc ../results/${DESIGN_NAME}.sdc
puts "Done: Constraints loaded"

# 6. Save design
puts ""
puts "Step 6: Saving design to library..."
save_block
save_lib
puts "Done: Design and library saved"

# 7. Verify saved design
puts ""
puts "Step 7: Verifying saved design..."
set saved_blocks [get_blocks * -quiet]
if {[sizeof_collection $saved_blocks] == 0} {
    puts "ERROR: No blocks found after save!"
    exit 1
}

puts "Saved blocks:"
foreach_in_collection blk $saved_blocks {
    set blk_name [get_object_name $blk]
    puts "  - $blk_name"
}

# 8. Generate reports
puts ""
puts "Step 8: Generating reports..."
report_lib nangate45_stdcells > ../reports/icc2/step1_lib.rpt
report_design > ../reports/icc2/step1_design.rpt
report_references -nosplit > ../reports/icc2/step1_ref.rpt

puts ""
puts "================================================"
puts "Step 1 completed successfully!"
puts "Design: ${DESIGN_NAME}"
puts "Standard cells: [sizeof_collection $cells]"
puts "Saved blocks: [sizeof_collection $saved_blocks]"
puts "================================================"

close_lib
exit
