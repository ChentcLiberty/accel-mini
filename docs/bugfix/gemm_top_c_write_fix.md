# Bug #3: GEMM Top Module - C Matrix 写入问题

## 🐛 问题描述

**现象：**
- 测试结果：C[0][0] ✅ 正确
- 其他元素：C[0][1..7] ❌ 都是 `x`（未定义）

**原因：**
顶层模块只写入了 `c_out[31:0]`（第一个元素），没有写入完整的 8 个元素。

---

## 🔧 修复方案

### 错误代码（第一版）：
```verilog
// 只写入了第一个元素
.c_wr_en(c_wr_en),
.c_wr_addr({c_wr_row, 3'b0}),
.c_wr_data(c_out[ACC_WIDTH-1:0]),  // ❌ 固定写 [31:0]

// 根据 c_addr 动态选择要写入的元素
.c_wr_en(c_wr_en),
.c_wr_addr(c_addr[5:0]),
.c_wr_data(c_out[c_addr[2:0]*ACC_WIDTH +: ACC_WIDTH]),  // ✅ 动态选择
关键修改：

使用控制器输出的 c_addr 而不是固定地址

根据 c_addr[2:0] 动态选择 c_out 中的元素

这样就能依次写入 C[0][0], C[0][1], ..., C[0][7]

✅ 测试结果

修复后：

C[0][0] = 0 (correct)
C[0][1] = 1 (correct)
C[0][2] = 2 (correct)
...
C[0][7] = 7 (correct)
✅ PASS: All results correct!

📚 学习要点

理解信号流：从控制器 → Memory，需要正确使用地址信号

向量切片：c_out[addr*width +: width] 动态选择向量中的字段

测试覆盖：第一次测试暴露了只写第一个元素的问题
