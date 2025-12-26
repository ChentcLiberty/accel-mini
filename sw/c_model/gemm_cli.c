#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>

int main() {
    int M, K, N;
    
    // 从标准输入读取维度
    if (scanf("%d %d %d", &M, &K, &N) != 3) {
        fprintf(stderr, "输入格式错误\n");
        return 1;
    }
    
    // 分配内存
    data_t *A = (data_t*)malloc(M * K * sizeof(data_t));
    data_t *B = (data_t*)malloc(K * N * sizeof(data_t));
    acc_t *C = (acc_t*)malloc(M * N * sizeof(acc_t));
    
    if (!A || !B || !C) {
        fprintf(stderr, "内存分配失败\n");
        return 1;
    }
    
    // 读取矩阵 A
    for (int i = 0; i < M * K; i++) {
        int val;
        if (scanf("%d", &val) != 1) {
            fprintf(stderr, "读取 A 失败\n");
            return 1;
        }
        A[i] = (data_t)val;
    }
    
    // 读取矩阵 B
    for (int i = 0; i < K * N; i++) {
        int val;
        if (scanf("%d", &val) != 1) {
            fprintf(stderr, "读取 B 失败\n");
            return 1;
        }
        B[i] = (data_t)val;
    }
    
    // 计算 GEMM
    gemm_int8(A, B, C, M, K, N);
    
    // 输出结果（只输出数值，便于 Python 解析）
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            printf("%d", C[i * N + j]);
            if (j < N - 1) printf(" ");
        }
        printf("\n");
    }
    
    // 清理
    free(A);
    free(B);
    free(C);
    
    return 0;
}

