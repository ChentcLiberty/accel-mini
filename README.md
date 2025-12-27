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
| 2.3 | GEMM 控制器 | ✅ | FSM 状态机 |
| 2.4 | 存储接口 | ⏸️ | - |
| 2.5 | 顶层集成 | ⏸️ | - |

---

## 🏗️ 架构设计

markdown
复制代码
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

yaml
复制代码

---

## 📚 学习笔记

### Bug #1: PE 缺少 Enable 信号

| 项目 | 内容 |
|------|------|
| 现象 | 测试结果是期望值的 2 倍 |
| 原因 | GEMM 完成后 PE 继续累加 |
| 修复 | 添加 `en` 信号控制更新 |
| 文件 | `docs/bugfix/pe_enable_fix.diff` |

**关键代码：**
```verilog
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
Bug #2: FSM Testbench 时序问题
项目内容
现象测试检测不到 FSM 输出
原因使用固定延迟而非等待信号变化
修复用 while (!signal) 等待信号转换
文件docs/bugfix/gemm_ctrl_timing_fix.diff

关键修改：

verilog
复制代码
// 错误方式：固定延迟
#CLK_PERIOD;  // 可能错过信号变化

// 正确方式：等待信号
while (!pe_en) #CLK_PERIOD;  // 等到信号变化
while (pe_en) begin
    // 计数
    #CLK_PERIOD;
end
🔧 开发环境
Synopsys VCS T-2022.06

Synopsys Verdi T-2022.06

GCC / Python 3

