#!/usr/bin/env python3
"""
最简单的 GEMM 实现
"""

import numpy as np

def gemm_simple(A, B):
    """
    C = A @ B
    A: [M, K]
    B: [K, N]
    C: [M, N]
    """
    M, K = A.shape
    K2, N = B.shape
    assert K == K2, f"维度不匹配: A({M},{K}) vs B({K2},{N})"
    
    # 创建结果矩阵
    C = np.zeros((M, N), dtype=A.dtype)
    
    # 三层循环实现矩阵乘法
    for i in range(M):
        for j in range(N):
            for k in range(K):
                C[i, j] += A[i, k] * B[k, j]
    
    return C


def test_simple():
    """测试函数"""
    print("=" * 50)
    print("测试 GEMM 基础功能")
    print("=" * 50)
    
    # 测试 1: 小矩阵
    A = np.array([[1, 2, 3],
                  [4, 5, 6]], dtype=np.float32)
    B = np.array([[1, 4],
                  [2, 5],
                  [3, 6]], dtype=np.float32)
    
    C_my = gemm_simple(A, B)
    C_np = A @ B  # NumPy 的矩阵乘法
    
    print(f"A shape: {A.shape}")
    print(f"B shape: {B.shape}")
    print(f"C shape: {C_my.shape}\n")
    
    print("我的结果:")
    print(C_my)
    print("\nNumPy 结果:")
    print(C_np)
    
    # 检查是否一致
    if np.allclose(C_my, C_np):
        print("\n✅ 测试通过！")
    else:
        print("\n❌ 结果不一致！")
        print(f"最大误差: {np.max(np.abs(C_my - C_np))}")


if __name__ == "__main__":
    test_simple()

