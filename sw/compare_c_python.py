#!/usr/bin/env python3
"""
对比 C 语言和 Python 的 GEMM 结果
"""

import numpy as np
import subprocess
import sys

def gemm_python(A, B):
    """Python 参考实现"""
    return np.matmul(A.astype(np.int32), B.astype(np.int32))

def gemm_c_wrapper(A, B):
    """
    调用 C 程序计算 GEMM
    通过临时文件传递数据
    """
    M, K = A.shape
    K2, N = B.shape
    assert K == K2
    
    # 写入输入文件
    input_file = '/tmp/gemm_input.txt'
    with open(input_file, 'w') as f:
        f.write(f"{M} {K} {N}\n")
        for i in range(M):
            for j in range(K):
                f.write(f"{A[i,j]} ")
            f.write('\n')
        for i in range(K):
            for j in range(N):
                f.write(f"{B[i,j]} ")
            f.write('\n')
    
    # 调用 C 程序
    result = subprocess.run(
        ['./c_model/gemm_cli', input_file],
        capture_output=True,
        text=True,
        cwd='.',
        timeout=5  # 添加超时保护
    )
    
    if result.returncode != 0:
        print("C 程序错误:", result.stderr)
        return None
    
    # 解析输出
    lines = result.stdout.strip().split('\n')
    C = []
    for line in lines:
        if line.strip():
            C.append(list(map(int, line.split())))
    
    return np.array(C, dtype=np.int32)

def test_compare(M, K, N, test_name):
    """对比测试"""
    print(f"\n{'='*60}")
    print(f"{test_name}: ({M}×{K}) @ ({K}×{N})")
    print('='*60)
    
    # 生成随机输入
    np.random.seed(42)
    A = np.random.randint(-128, 127, size=(M, K), dtype=np.int8)
    B = np.random.randint(-128, 127, size=(K, N), dtype=np.int8)
    
    # Python 计算
    C_py = gemm_python(A, B)
    
    # C 计算
    C_c = gemm_c_wrapper(A, B)
    
    if C_c is None:
        print("❌ C 程序调用失败")
        return False
    
    # 对比
    match = np.array_equal(C_py, C_c)
    max_diff = np.max(np.abs(C_py.astype(np.int64) - C_c.astype(np.int64)))
    
    print(f"Python 结果: C[0,0]={C_py[0,0]}, C[-1,-1]={C_py[-1,-1]}")
    print(f"C 语言结果: C[0,0]={C_c[0,0]}, C[-1,-1]={C_c[-1,-1]}")
    print(f"结果匹配: {match}")
    print(f"最大误差: {max_diff}")
    
    if match:
        print("✅ 测试通过")
        return True
    else:
        print("❌ 结果不一致")
        # 显示前几个不匹配的元素
        diff = C_py != C_c
        indices = np.argwhere(diff)[:5]
        for idx in indices:
            i, j = idx
            print(f"  C[{i},{j}]: Python={C_py[i,j]}, C={C_c[i,j]}")
        return False

def main():
    print("C 语言与 Python GEMM 对比验证")
    print("="*60)
    
    tests = [
        (2, 3, 2, "测试 1: 小矩阵"),
        (8, 8, 8, "测试 2: 8×8 方阵"),
        (16, 16, 16, "测试 3: 16×16 方阵"),
        (8, 16, 4, "测试 4: 非方阵"),
    ]
    
    passed = 0
    for M, K, N, name in tests:
        if test_compare(M, K, N, name):
            passed += 1
    
    print(f"\n{'='*60}")
    print(f"总结: {passed}/{len(tests)} 测试通过")
    print('='*60)
    
    return 0 if passed == len(tests) else 1

if __name__ == "__main__":
    sys.exit(main())

