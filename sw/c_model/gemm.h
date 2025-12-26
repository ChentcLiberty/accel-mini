#ifndef GEMM_H
#define GEMM_H

#include <stdint.h>

// 硬件参数定义
#define DATA_WIDTH 8      // INT8
#define ACC_WIDTH  32     // INT32 累加器

// 数据类型（模拟硬件位宽）
typedef int8_t  data_t;   // 对应 Verilog 的 signed [7:0]
typedef int32_t acc_t;    // 对应 Verilog 的 signed [31:0]

// GEMM 函数声明
void gemm_int8(
    const data_t *A,  // 输入矩阵 A [M×K]
    const data_t *B,  // 输入矩阵 B [K×N]
    acc_t *C,         // 输出矩阵 C [M×N]
    int M, int K, int N
);

// 打印矩阵（调试用）
void print_matrix_int8(const data_t *mat, int rows, int cols, const char *name);
void print_matrix_int32(const acc_t *mat, int rows, int cols, const char *name);

#endif

