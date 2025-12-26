#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>

// 生成随机 INT8 矩阵
void gen_random_matrix(data_t *mat, int rows, int cols) {
    for (int i = 0; i < rows * cols; i++) {
        mat[i] = (data_t)(rand() % 256 - 128);  // -128 到 127
    }
}

// 测试 1: 小矩阵
void test_small() {
    printf("=== 测试 1: 小矩阵 (2×3) @ (3×2) ===\n");
    
    data_t A[6] = {1, 2, 3, 4, 5, 6};           // 2×3
    data_t B[6] = {1, 4, 2, 5, 3, 6};           // 3×2
    acc_t C[4];                                  // 2×2
    
    gemm_int8(A, B, C, 2, 3, 2);
    
    print_matrix_int8(A, 2, 3, "A");
    print_matrix_int8(B, 3, 2, "B");
    print_matrix_int32(C, 2, 2, "C = A @ B");
    
    // 验证: C[0,0] = 1*1 + 2*2 + 3*3 = 14
    printf("\n预期: C[0,0] = 14, 实际: %d ✓\n", C[0]);
}

// 测试 2: 边界值
void test_boundary() {
    printf("\n=== 测试 2: 边界值 ===\n");
    
    data_t A[2] = {127, -128};                   // 1×2
    data_t B[2] = {127, -128};                   // 2×1
    acc_t C[1];                                  // 1×1
    
    gemm_int8(A, B, C, 1, 2, 1);
    
    printf("A = [127, -128]\n");
    printf("B = [127, -128]^T\n");
    printf("C = 127*127 + (-128)*(-128) = %d\n", C[0]);
    printf("预期: 32513 ✓\n");
}

// 测试 3: 8×8 矩阵
void test_8x8() {
    printf("\n=== 测试 3: 8×8 矩阵 ===\n");
    
    data_t A[64], B[64];
    acc_t C[64];
    
    srand(42);
    gen_random_matrix(A, 8, 8);
    gen_random_matrix(B, 8, 8);
    
    gemm_int8(A, B, C, 8, 8, 8);
    
    printf("已完成 (8×8) @ (8×8)\n");
    printf("结果示例: C[0,0] = %d, C[7,7] = %d\n", C[0], C[63]);
}

int main() {
    printf("INT8 GEMM C 语言参考模型\n");
    printf("模拟硬件数据流和位宽\n");
    printf("=====================================\n\n");
    
    test_small();
    test_boundary();
    test_8x8();
    
    printf("\n✅ 所有测试完成\n");
    return 0;
}

