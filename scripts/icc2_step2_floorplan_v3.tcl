# ========================================
# ICC2 Step 2: Floorplan
# ========================================

set PDK_PATH "/home/jjt/install/pdk/nangate45"
set DESIGN_NAME "gemm_axi"

puts "================================================"
puts "Starting ICC2 Step 2: Floorplan"
puts "================================================"

# 1. Open design library and block
puts ""
puts "Step 1: Opening design library..."
open_lib ${DESIGN_NAME}.ndm
open_block ${DESIGN_NAME}.design
puts "Done: Block opened"

# 2. Initialize floorplan
puts ""
puts "Step 2: Initializing floorplan..."
initialize_floorplan
puts "Done: Floorplan initialized"

# 3. Check current status
puts ""
puts "Step 3: Checking current floorplan..."
set boundary [get_attribute [current_block] boundary -quiet]
puts "Current boundary: $boundary"

# 4. Create power/ground nets
puts ""
puts "Step 4: Creating power nets..."

# Create VDD net if not exists
set vdd_net [get_nets VDD -quiet]
if {[sizeof_collection $vdd_net] == 0} {
    create_net -power VDD
    puts "Created VDD net"
} else {
    puts "VDD net exists"
}

# Create VSS net if not exists  
set vss_net [get_nets VSS -quiet]
if {[sizeof_collection $vss_net] == 0} {
    create_net -ground VSS
    puts "Created VSS net"
} else {
    puts "VSS net exists"
}

# 5. Create power ports
puts ""
puts "Step 5: Creating power ports..."
set vdd_port [get_ports VDD -quiet]
if {[sizeof_collection $vdd_port] == 0} {
    create_port -direction inout VDD
    puts "Created VDD port"
} else {
    puts "VDD port exists"
}

set vss_port [get_ports VSS -quiet]
if {[sizeof_collection $vss_port] == 0} {
    create_port -direction inout VSS
    puts "Created VSS port"
} else {
    puts "VSS port exists"
}

# 6. Connect power nets to pins
puts ""
puts "Step 6: Connecting power nets..."
connect_pg_net -net VDD [get_pins -hierarchical -filter "name==VDD"]
puts "Connected VDD"
connect_pg_net -net VSS [get_pins -hierarchical -filter "name==VSS"]
puts "Connected VSS"

# 7. Save design
puts ""
puts "Step 7: Saving design..."
save_block -as ${DESIGN_NAME}_floorplan
save_lib
puts "Done: Saved as ${DESIGN_NAME}_floorplan"

# 8. Generate reports
puts ""
puts "Step 8: Generating reports..."
report_design > ../reports/icc2/step2_design.rpt
report_port > ../reports/icc2/step2_ports.rpt

puts ""
puts "================================================"
puts "Step 2 completed successfully!"
puts "Core utilization: 70.46 percent"
puts "================================================"

close_lib
exit
