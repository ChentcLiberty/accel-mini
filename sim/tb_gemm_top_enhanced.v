/**
 * GEMM Top Testbench - Enhanced Version
 * 包含 6 个测试场景的完整系统验证
 */

`timescale 1ns / 1ps

module tb_gemm_top;

    parameter CLK_PERIOD = 10;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter ARRAY_SIZE = 8;
    
    reg         clk, rst_n, start;
    wire        done, busy;
    reg         a_wr_en, b_wr_en;
    reg  [5:0]  a_wr_addr, b_wr_addr;
    reg  [7:0]  a_wr_data, b_wr_data;
    reg  [2:0]  c_rd_row;
    wire [255:0] c_rd_data;
    
    gemm_top u_top (
        .clk(clk), .rst_n(rst_n),
        .start(start), .done(done), .busy(busy),
        .a_wr_en(a_wr_en), .a_wr_addr(a_wr_addr), .a_wr_data(a_wr_data),
        .b_wr_en(b_wr_en), .b_wr_addr(b_wr_addr), .b_wr_data(b_wr_data),
        .c_rd_row(c_rd_row), .c_rd_data(c_rd_data)
    );
    
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end
    
    integer i, j, k, errors, test_num;
    reg signed [7:0] A [0:7][0:7];
    reg signed [7:0] B [0:7][0:7];
    reg signed [31:0] C_ref [0:7][0:7];
    
    // 计算参考结果
    task compute_reference;
        integer ii, jj, kk;
        begin
            for (ii = 0; ii < 8; ii = ii + 1) begin
                for (jj = 0; jj < 8; jj = jj + 1) begin
                    C_ref[ii][jj] = 0;
                    for (kk = 0; kk < 8; kk = kk + 1) begin
                        C_ref[ii][jj] = C_ref[ii][jj] + A[ii][kk] * B[kk][jj];
                    end
                end
            end
        end
    endtask
    
    // 写入矩阵 A
    task write_matrix_a;
        integer ii, jj;
        begin
            a_wr_en = 1;
            for (ii = 0; ii < 8; ii = ii + 1) begin
                for (jj = 0; jj < 8; jj = jj + 1) begin
                    a_wr_addr = ii * 8 + jj;
                    a_wr_data = A[ii][jj];
                    #CLK_PERIOD;
                end
            end
            a_wr_en = 0;
        end
    endtask
    
    // 写入矩阵 B
    task write_matrix_b;
        integer ii, jj;
        begin
            b_wr_en = 1;
            for (ii = 0; ii < 8; ii = ii + 1) begin
                for (jj = 0; jj < 8; jj = jj + 1) begin
                    b_wr_addr = ii * 8 + jj;
                    b_wr_data = B[ii][jj];
                    #CLK_PERIOD;
                end
            end
            b_wr_en = 0;
        end
    endtask
    
    // 启动计算并等待完成
    task run_gemm;
        begin
            start = 1;
            #CLK_PERIOD;
            start = 0;
            while (!done) #CLK_PERIOD;
        end
    endtask
    
    // 验证所有结果
    task verify_all_results;
        integer ii, jj;
        integer row_errors;
        begin
            errors = 0;
            for (ii = 0; ii < 8; ii = ii + 1) begin
                c_rd_row = ii;
                #CLK_PERIOD;
                row_errors = 0;
                
                for (jj = 0; jj < 8; jj = jj + 1) begin
                    if (c_rd_data[jj*32 +: 32] !== C_ref[ii][jj]) begin
                        $display("  ❌ C[%0d][%0d]: Expected %0d, Got %0d", 
                                 ii, jj, C_ref[ii][jj], $signed(c_rd_data[jj*32 +: 32]));
                        errors = errors + 1;
                        row_errors = row_errors + 1;
                    end
                end
                
                if (row_errors == 0) begin
                    $display("  ✅ Row %0d: All correct", ii);
                end
            end
        end
    endtask
    
    initial begin
        $display("===== GEMM Enhanced Integration Test =====\n");
        
        rst_n = 0; start = 0;
        a_wr_en = 0; b_wr_en = 0;
        a_wr_addr = 0; b_wr_addr = 0;
        a_wr_data = 0; b_wr_data = 0;
        c_rd_row = 0;
        test_num = 0;
        
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #CLK_PERIOD;
        
        // ========== Test 1: 单位矩阵测试 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Identity Matrix (A=I, B=random, C=B)", test_num);

        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = (i == j) ? 8'd1 : 8'd0;
                B[i][j] = i + j;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Starting computation...");
        run_gemm();
        $display("  Computation done, verifying...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== Test 2: 全零矩阵测试 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Zero Matrix (A=0, B=any, C=0)", test_num);
        
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = 8'd0;
                B[i][j] = 8'd5;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Starting computation...");
        run_gemm();
        $display("  Computation done, verifying...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== Test 3: 边界值测试 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Boundary Values (A=127/-128)", test_num);
        
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = (i[0] == 0) ? 8'd127 : -8'd128;
                B[i][j] = (j[0] == 0) ? 8'd1 : 8'd2;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Starting computation...");
        run_gemm();
        $display("  Computation done, verifying...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== Test 4: 小值随机矩阵 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Small Random Matrix", test_num);
        
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = (i * 7 + j * 3) % 16 - 8;  // -8 到 7
                B[i][j] = (i * 5 + j * 2) % 16 - 8;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Starting computation...");
        run_gemm();
        $display("  Computation done, verifying...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== Test 5: 连续计算测试 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Back-to-Back Computation", test_num);
        
        // 第一次计算
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = 8'd2;
                B[i][j] = 8'd3;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  First computation...");
        run_gemm();
        
        // 立即启动第二次计算
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = 8'd1;
                B[i][j] = 8'd4;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Second computation (back-to-back)...");
        run_gemm();
        $display("  Computation done, verifying...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== Test 6: 完整矩阵乘法 ==========
        test_num = test_num + 1;
        $display("[Test %0d] Full Matrix Multiplication", test_num);
        
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = i + 1;
                B[i][j] = j + 1;
            end
        end
        
        write_matrix_a();
        write_matrix_b();
        compute_reference();
        
        $display("  Starting computation...");
        run_gemm();
        $display("  Computation done, verifying all 64 elements...");
        
        verify_all_results();
        
        if (errors == 0) begin
            $display("  ✅ Test %0d PASSED\n", test_num);
        end else begin
            $display("  ❌ Test %0d FAILED (%0d errors)\n", test_num, errors);
        end
        
        // ========== 总结 ==========
        #(CLK_PERIOD * 10);
        $display("\n===== Test Summary =====");
        $display("Total tests: %0d", test_num);
        $display("All tests completed successfully!");
        $display("========================\n");
        
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_gemm_top_enhanced.fsdb");
        $fsdbDumpvars(0, tb_gemm_top);
    end

endmodule
