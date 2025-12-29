set PDK_PATH "/home/jjt/install/pdk/nangate45"

# 创建工作区
create_workspace nangate45_ws \
    -technology ${PDK_PATH}/rtk-tech.tf

# 读取 LEF
read_lef ${PDK_PATH}/rtk-tech.lef
read_lef ${PDK_PATH}/stdcells.lef

# 检查并提交
check_workspace
commit_workspace -output ./work_icc2/nangate45_stdcells.ndm -force

puts "NDM library created: ./work_icc2/nangate45_stdcells.ndm"
exit
