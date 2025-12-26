#include "gemm.h"
#include <stdio.h>
#include <string.h>

/**
 * INT8 GEMM - 模拟硬件数据流
 * C[M,N] = A[M,K] @ B[K,N]
 * 
 * 硬件对应关系:
 * - 外层循环 i,j -> 控制器地址生成
 * - 内层循环 k  -> PE 阵列串行累加
 * - acc        -> PE 内部的 32位累加寄存器
 */
void gemm_int8(
    const data_t *A,
    const data_t *B, 
    acc_t *C,
    int M, int K, int N
) {
    // 清空输出（模拟硬件复位）
    memset(C, 0, M * N * sizeof(acc_t));
    
    // 三层循环 - 对应硬件状态机
    for (int i = 0; i < M; i++) {           // 对应控制器的行计数器
        for (int j = 0; j < N; j++) {       // 对应控制器的列计数器
            acc_t acc = 0;                  // 模拟 PE 内部累加器
            
            for (int k = 0; k < K; k++) {   // 对应数据流时序
                // 获取数据（模拟从 SRAM 读取）
                data_t a_val = A[i * K + k];  // A[i,k]
                data_t b_val = B[k * N + j];  // B[k,j]
                
                // MAC 操作（模拟 PE 逻辑）
                // INT8 × INT8 -> INT16 -> INT32
                acc += (acc_t)a_val * (acc_t)b_val;
            }
            
            // 写回结果（模拟写 SRAM）
            C[i * N + j] = acc;
        }
    }
}

void print_matrix_int8(const data_t *mat, int rows, int cols, const char *name) {
    printf("\n%s [%d×%d] (INT8):\n", name, rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            printf("%4d ", mat[i * cols + j]);
        }
        printf("\n");
    }
}

void print_matrix_int32(const acc_t *mat, int rows, int cols, const char *name) {
    printf("\n%s [%d×%d] (INT32):\n", name, rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            printf("%8d ", mat[i * cols + j]);
        }
        printf("\n");
    }
}

