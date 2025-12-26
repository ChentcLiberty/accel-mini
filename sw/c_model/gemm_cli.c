#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "用法: %s <输入文件>\n", argv[0]);
        return 1;
    }
    
    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        fprintf(stderr, "无法打开文件: %s\n", argv[1]);
        return 1;
    }
    
    int M, K, N;
    if (fscanf(fp, "%d %d %d", &M, &K, &N) != 3) {
        fprintf(stderr, "读取维度失败\n");
        fclose(fp);
        return 1;
    }
    
    // 分配内存
    data_t *A = (data_t*)malloc(M * K * sizeof(data_t));
    data_t *B = (data_t*)malloc(K * N * sizeof(data_t));
    acc_t *C = (acc_t*)malloc(M * N * sizeof(acc_t));
    
    if (!A || !B || !C) {
        fprintf(stderr, "内存分配失败\n");
        fclose(fp);
        return 1;
    }
    
    // 读取矩阵 A
    for (int i = 0; i < M * K; i++) {
        int val;
        if (fscanf(fp, "%d", &val) != 1) {
            fprintf(stderr, "读取 A 失败\n");
            fclose(fp);
            return 1;
        }
        A[i] = (data_t)val;
    }
    
    // 读取矩阵 B
    for (int i = 0; i < K * N; i++) {
        int val;
        if (fscanf(fp, "%d", &val) != 1) {
            fprintf(stderr, "读取 B 失败\n");
            fclose(fp);
            return 1;
        }
        B[i] = (data_t)val;
    }
    
    fclose(fp);
    
    // 计算 GEMM
    gemm_int8(A, B, C, M, K, N);
    
    // 输出结果到标准输出
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

