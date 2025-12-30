# GEMM 矩阵乘法加速器

基于 NanGate45 工艺的 4x4 GEMM 矩阵乘法硬件加速器。

## 项目进度

| 阶段 | 状态 | 说明 |
|------|:----:|------|
| RTL 设计 | ✅ | 6个模块完成 |
| RTL 仿真 | ✅ | 所有模块验证通过 |
| 逻辑综合 (DC) | ✅ | 门级网表生成 |
| NDM 库准备 | ✅ | 135个标准单元 |
| P&R Step1: 设计导入 | ✅ | 网表和约束导入成功 |
| P&R Step2: Floorplan | 🔄 | 进行中 |
| P&R Step3: Placement | ❌ | 待完成 |
| P&R Step4: CTS | ❌ | 待完成 |
| P&R Step5: Routing | ❌ | 待完成 |
| 时序签核 (PT) | ❌ | 待完成 |
| 物理验证 | ❌ | 待完成 |

## 目录结构

accel-mini/
├── rtl/ # RTL 源代码
│ ├── pe.v # 处理单元
│ ├── pe_array.v # 4x4 PE阵列
│ ├── gemm_mem.v # 双端口SRAM
│ ├── gemm_ctrl.v # 控制状态机
│ ├── gemm_axi.v # AXI4接口
│ └── gemm_top.v # 顶层模块
├── sim/ # 仿真文件
├── scripts/ # 综合和P&R脚本
│ ├── syn_gemm.tcl # DC综合脚本
│ ├── step1_create_ndm.tcl # NDM库创建
│ ├── icc2_pnr_step1.tcl # ICC2 Step1脚本
│ ├── work_icc2/ # NDM参考库
│ └── gemm_axi.ndm/ # 设计库
├── results/ # 综合结果
│ ├── gemm_axi_netlist.v # 门级网表
│ ├── gemm_axi.sdc # 时序约束
│ └── syn_*.rpt # 综合报告
└── reports/ # P&R报告
└── icc2/ # ICC2报告

## 设计规格

- **工艺**: NanGate45 (45nm FreePDK)
- **时钟频率**: 100 MHz (目标)
- **矩阵大小**: 4x4
- **数据位宽**: 8-bit
- **接口**: AXI4-Lite

## 综合结果

- **网表实例数**: 6523
- **端口数**: 108
- **标准单元库**: 135 个单元

## 运行说明

### 1. NDM 库创建
```bash
cd scripts
icc2_lm_shell -f step1_create_ndm.tcl
2. ICC2 P&R Step1
cd scripts
icc2_shell -f icc2_pnr_step1.tcl

工具版本

Design Compiler: T-2022.03

IC Compiler II: T-2022.03

Library Manager: T-2022.03

PDK: NanGate45 FreePDK

## 项目进度更新 (2025-12-30)


### 完成进度
- ✅ Level 1: 算法验证 (100%)
- 🔄 Level 2: RTL 设计 (71%)
  - ✅ 2.1-2.5: 基础模块完成
  - 🔄 2.6: 完整系统验证（进行中）
  - ⏸️ 2.7: Waveform 分析
- 🔄 Level 3: 系统集成 (60%)
- ⏸️ Level 4-6: 待开始

### P&R 状态（低优先级）
- ✅ Step 1-3: 设计导入/Floorplan/Placement 已完成
- ⏸️ Step 4-7: 暂时搁置

### 当前任务
- Level 2.6: 完善 tb_gemm_top.v 测试场景

### 已知问题
- ⚠️ 缺少时序约束文件 (.sdc)
- ⚠️ 测试覆盖不足

### UVM 验证计划
- 📋 Level 3 引入 UVM（混合模式：传统 + UVM 并存）
- 🎯 第一个 UVM 目标：gemm_axi 模块
