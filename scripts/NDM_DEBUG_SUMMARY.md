# NDM 库创建与使用 Debug 总结

## 问题描述
在使用 Synopsys ICC2 进行 Place & Route 时，发现 NDM 参考库虽然创建成功，但在 ICC2 中查询单元时返回 0 个结果。

## 根本原因
**NDM 库本身是正确的**，问题在于 ICC2 中查询参考库单元的方式不对：
- ❌ 错误方式：`get_lib_cells *` （返回 0 个单元）
- ✅ 正确方式：`get_lib_cells nangate45_stdcells/*` （返回 135 个单元）

## 解决方案

### 步骤 1：创建 NDM 参考库（已完成 ✅）
在 Library Manager 中运行：
```tcl
set PDK_PATH "/home/jjt/install/pdk/nangate45"
create_workspace nangate45_ws -technology ${PDK_PATH}/rtk-tech.tf
read_lef ${PDK_PATH}/rtk-tech.lef
read_lef ${PDK_PATH}/stdcells.lef
check_workspace
commit_workspace -output ./work_icc2/nangate45_stdcells.ndm -force
exit
步骤 2：在 ICC2 中正确使用 NDM 库
set PDK_PATH "/home/jjt/install/pdk/nangate45"

# 创建设计库并关联参考库
create_lib my_design.ndm \
    -technology ${PDK_PATH}/rtk-tech.tf \
    -ref_libs {./work_icc2/nangate45_stdcells.ndm}

# ✅ 正确查询方法（必须指定库名）
set cells [get_lib_cells nangate45_stdcells/* -quiet]
puts "标准单元数：[sizeof_collection $cells]"
验证结果

✅ NDM 库包含 135 个标准单元

✅ 包含完整的单元类型：AND、OR、NAND、NOR、INV、BUF、DFF、MUX 等

✅ 可在 ICC2 中正常使用

关键文件

NDM 参考库：./work_icc2/nangate45_stdcells.ndm

创建脚本：step1_create_ndm.tcl

验证脚本：verify_final_solution.tcl

工具版本

Library Manager：T-2022.03

ICC2：T-2022.03

PDK：NanGate45

经验教训

NDM 参考库的查询必须指定库名，不能用通配符 *

Library Manager 和 ICC2 的命令集不同

使用 -ref_libs 关联参考库是关键

调试时要区分"库创建"和"库使用"两个层面
