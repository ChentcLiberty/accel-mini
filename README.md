# Accel-Mini: 8×8 INT8 GEMM 加速器

一个从零开始设计的 AI 加速器学习项目，实现 8×8 INT8 矩阵乘法硬件加速。

## 🎯 项目目标

C[8×8] = A[8×8] × B[8×8] (INT8 输入，INT32 输出)

## 📊 项目进度

### Level 1: 算法理解 ✅ 完成

| Step | 描述 | 状态 |
|------|------|------|
| 1.1 | Python 快速验证 | ✅ |
| 1.2 | C 语言基础实现 | ✅ |
| 1.3 | C/Python 对比验证 | ✅ |
| 1.4 | Tile 分块实现 | ✅ |
| 1.5 | 周期级仿真 | ✅ |

### Level 2: RTL 设计 ⏳ 进行中

| Step | 描述 | 状态 | 说明 |
|------|------|------|------|
| 2.1 | PE（处理单元） | ✅ | INT8 MAC，32-bit 累加 |
| 2.2 | PE Array（8×8） | ✅ | 64 个 PE 并行计算 |
| 2.3 | GEMM 控制器 | ⏳ | FSM 状态机 |
| 2.4 | 存储接口 | ⏸️ | - |
| 2.5 | 顶层集成 | ⏸️ | - |

---

## 🏗️ 架构设计

          ┌─────────────────────────────┐
          │       GEMM Accelerator      │
          │                             │
A[8×8] ────►│ ┌───────────────────────┐ │
│ │ PE Array (8×8) │ │────► C[8×8]
B[8×8] ────►│ │ 64 个 MAC 单元 │ │
│ └───────────────────────┘ │
│ ▲ │
│ en, load│ │
│ ┌─────────┴─────────────┐ │
start ────►│ │ GEMM Controller │ │────► done
│ │ (FSM) │ │
│ └───────────────────────┘ │
└─────────────────────────────┘

### PE 结构
输入: a[7:0], b[7:0] (INT8)
输出: acc[31:0] (INT32)
功能: acc = acc + a × b
控制: en（使能）, load（清零）

---

## 📂 目录结构

accel-mini/
├── README.md
├── docs/
│ └── bugfix/ # Bug 修复记录（学习材料）
├── rtl/ # Verilog 设计
│ ├── pe.v # 处理单元
│ └── pe_array.v # 8×8 阵列
├── sim/ # 仿真测试
│ ├── tb_pe.v
│ └── tb_pe_array.v
└── sw/ # 软件模型
└── c_model/

---

## 🚀 快速开始

### RTL 仿真（VCS）

```bash
cd sim

# PE 测试
vcs -full64 -sverilog -debug_access+all -timescale=1ns/1ps \
    ../rtl/pe.v tb_pe.v -o simv && ./simv

# PE Array 测试
vcs -full64 -sverilog -debug_access+all -timescale=1ns/1ps \
    ../rtl/pe.v ../rtl/pe_array.v tb_pe_array.v -o simv_array && ./simv_array
📚 学习笔记
Bug #1: PE 缺少Enable信号
项目         内容
现象
测试结果是期望值的 2 倍
原因         GEMM 完成后 PE 继续累加
修复         添加 en 信号控制更新
文件         docs/bugfix/pe_enable_fix.diff
关键代码修改:
// 修复前：每个时钟都累加
always @(posedge clk) begin
    acc_reg <= acc_reg + a * b;
end

// 修复后：只有 en=1 时累加
always @(posedge clk) begin
    if (en) begin
        acc_reg <= acc_reg + a * b;
    end
end
🔧 开发环境

Synopsys VCS T-2022.06

Synopsys Verdi T-2022.06

GCC / Python 3

📝 Git 提交规范
Add Step X.X: 简短描述

- 详细说明 1
- 详细说明 2
