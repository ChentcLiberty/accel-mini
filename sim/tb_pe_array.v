/**
 * PE Array Testbench
 * 
 * 测试 8×8 GEMM 计算
 */

`timescale 1ns / 1ps

module tb_pe_array;

    // 参数
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter ARRAY_SIZE = 8;
    parameter CLK_PERIOD = 10;
    
    // 信号
    reg                                 clk;
    reg                                 rst_n;
    reg                                 load;
    reg  signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_row;
    reg  signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_col;
    wire signed [ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0] c_out;
    
    // 用于测试的临时变量
    reg signed [DATA_WIDTH-1:0] A [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [DATA_WIDTH-1:0] B [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [ACC_WIDTH-1:0]  C_ref [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    integer i, j, k;
    integer errors;
    
    // 实例化 PE Array
    pe_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE)
    ) u_pe_array (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .a_row(a_row),
        .b_col(b_col),
        .c_out(c_out)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 从 c_out 提取 C[i][j]
    function signed [ACC_WIDTH-1:0] get_c;
        input integer row, col;
        begin
            get_c = c_out[(row*ARRAY_SIZE+col+1)*ACC_WIDTH-1 -: ACC_WIDTH];
        end
    endfunction
    
    // 打包 A 行
    task pack_a_row;
        input integer k_idx;
        integer idx;
        begin
            a_row = 0;
            for (idx = 0; idx < ARRAY_SIZE; idx = idx + 1) begin
                a_row[(idx+1)*DATA_WIDTH-1 -: DATA_WIDTH] = A[idx][k_idx];
            end
        end
    endtask
    
    // 打包 B 列
    task pack_b_col;
        input integer k_idx;
        integer idx;
        begin
            b_col = 0;
            for (idx = 0; idx < ARRAY_SIZE; idx = idx + 1) begin
                b_col[(idx+1)*DATA_WIDTH-1 -: DATA_WIDTH] = B[k_idx][idx];
            end
        end
    endtask
    
    // 计算参考结果
    task compute_reference;
        integer ii, jj, kk;
        begin
            for (ii = 0; ii < ARRAY_SIZE; ii = ii + 1) begin
                for (jj = 0; jj < ARRAY_SIZE; jj = jj + 1) begin
                    C_ref[ii][jj] = 0;
                    for (kk = 0; kk < ARRAY_SIZE; kk = kk + 1) begin
                        C_ref[ii][jj] = C_ref[ii][jj] + 
                            $signed(A[ii][kk]) * $signed(B[kk][jj]);
                    end
                end
            end
        end
    endtask
    
    // 测试激励
    initial begin
        $display("===== PE Array Testbench Start =====");
        $display("Array Size: %0d x %0d", ARRAY_SIZE, ARRAY_SIZE);
        
        // 初始化
        rst_n = 0;
        load  = 0;
        a_row = 0;
        b_col = 0;
        errors = 0;
        
        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // ========== 测试 1: 简单矩阵 ==========
        $display("\n[Test 1] Simple 8x8 matrix multiplication");
        
        // 初始化 A = 单位矩阵
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = (i == j) ? 8'd1 : 8'd0;
                B[i][j] = i + j;  // B[i][j] = i + j
            end
        end
        
        // 计算参考结果
        compute_reference();
        
        // 运行 GEMM
        load = 1;
        pack_a_row(0);
        pack_b_col(0);
        #CLK_PERIOD;
        
        load = 0;
        for (k = 1; k < ARRAY_SIZE; k = k + 1) begin
            pack_a_row(k);
            pack_b_col(k);
            #CLK_PERIOD;
        end
        
        // 等待结果稳定
        #CLK_PERIOD;
        
        // 验证结果
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (get_c(i, j) !== C_ref[i][j]) begin
                    $display("  ❌ C[%0d][%0d]: Expected %0d, Got %0d",
                             i, j, C_ref[i][j], get_c(i, j));
                    errors = errors + 1;
                end
            end
        end
        
        if (errors == 0) begin
            $display("  ✅ Test 1 PASSED");
            $display("  Sample: C[0][0]=%0d, C[7][7]=%0d", 
                     get_c(0, 0), get_c(7, 7));
        end
        
        // ========== 测试 2: 随机矩阵 ==========
        $display("\n[Test 2] Random matrix multiplication");
        errors = 0;
        
        // 随机初始化
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = $random % 64 - 32;  // -32 to 31
                B[i][j] = $random % 64 - 32;
            end
        end
        
        // 计算参考结果
        compute_reference();
        
        // 运行 GEMM
        load = 1;
        pack_a_row(0);
        pack_b_col(0);
        #CLK_PERIOD;
        
        load = 0;
        for (k = 1; k < ARRAY_SIZE; k = k + 1) begin
            pack_a_row(k);
            pack_b_col(k);
            #CLK_PERIOD;
        end
        
        #CLK_PERIOD;
        
        // 验证
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (get_c(i, j) !== C_ref[i][j]) begin
                    $display("  ❌ C[%0d][%0d]: Expected %0d, Got %0d",
                             i, j, C_ref[i][j], get_c(i, j));
                    errors = errors + 1;
                end
            end
        end
        
        if (errors == 0) begin
            $display("  ✅ Test 2 PASSED");
            $display("  Sample: C[0][0]=%0d, C[7][7]=%0d", 
                     get_c(0, 0), get_c(7, 7));
        end
        
        // ========== 测试 3: 边界值 ==========
        $display("\n[Test 3] Boundary values");
        errors = 0;
        
        // 最大/最小值
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = (i + j) % 2 == 0 ? 8'sd127 : -8'sd128;
                B[i][j] = (i + j) % 2 == 0 ? 8'sd127 : -8'sd128;
            end
        end
        
        compute_reference();
        
        load = 1;
        pack_a_row(0);
        pack_b_col(0);
        #CLK_PERIOD;
        
        load = 0;
        for (k = 1; k < ARRAY_SIZE; k = k + 1) begin
            pack_a_row(k);
            pack_b_col(k);
            #CLK_PERIOD;
        end
        
        #CLK_PERIOD;
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (get_c(i, j) !== C_ref[i][j]) begin
                    $display("  ❌ C[%0d][%0d]: Expected %0d, Got %0d",
                             i, j, C_ref[i][j], get_c(i, j));
                    errors = errors + 1;
                end
            end
        end
        
        if (errors == 0) begin
            $display("  ✅ Test 3 PASSED");
            $display("  Sample: C[0][0]=%0d, C[7][7]=%0d", 
                     get_c(0, 0), get_c(7, 7));
        end
        
        // ========== 完成 ==========
        #(CLK_PERIOD * 5);
        $display("\n===== PE Array Testbench End =====");
        $finish;
    end
    
    // 波形输出
    initial begin
        $fsdbDumpfile("tb_pe_array.fsdb");
        $fsdbDumpvars(0, tb_pe_array);
    end

endmodule

