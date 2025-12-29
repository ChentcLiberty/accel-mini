# ========================================
# ICC2 Step 3: Placement
# ========================================

set DESIGN_NAME "gemm_axi"

puts "================================================"
puts "Starting ICC2 Step 3: Placement"
puts "================================================"

# 1. Open floorplanned design
puts ""
puts "Step 1: Opening floorplanned design..."
open_lib ${DESIGN_NAME}.ndm
open_block ${DESIGN_NAME}_floorplan.design
puts "Done: Block opened"

# 2. Set placement options
puts ""
puts "Step 2: Setting placement options..."
set_app_options -name place.coarse.continue_on_missing_scandef -value true
puts "Done: Options set"

# 3. Run placement
puts ""
puts "Step 3: Running placement..."
create_placement -floorplan
puts "Done: Placement completed"

# 4. Legalize placement
puts ""
puts "Step 4: Legalizing placement..."
legalize_placement
puts "Done: Placement legalized"

# 5. Check placement
puts ""
puts "Step 5: Checking placement..."
set unplaced [get_cells -filter "is_placed==false" -quiet]
puts "Unplaced cells: [sizeof_collection $unplaced]"

# 6. Save design
puts ""
puts "Step 6: Saving design..."
save_block -as ${DESIGN_NAME}_placed
save_lib
puts "Done: Saved as ${DESIGN_NAME}_placed"

# 7. Generate reports
puts ""
puts "Step 7: Generating reports..."
report_design > ../reports/icc2/step3_design.rpt
report_placement > ../reports/icc2/step3_placement.rpt

puts ""
puts "================================================"
puts "Step 3 completed successfully!"
puts "================================================"

close_lib
exit
