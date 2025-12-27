/**
 * GEMM Top Testbench - 顶层集成测试
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
    
    integer i, j, k, errors;
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
    
    initial begin
        $display("===== GEMM Top Integration Test =====");
        
        rst_n = 0; start = 0;
        a_wr_en = 0; b_wr_en = 0;
        a_wr_addr = 0; b_wr_addr = 0;
        a_wr_data = 0; b_wr_data = 0;
        c_rd_row = 0;
        errors = 0;
        
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #CLK_PERIOD;
        
        // 初始化矩阵 A（单位矩阵）和 B
        $display("\n[Setup] Initialize matrices");
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                A[i][j] = (i == j) ? 8'd1 : 8'd0;
                B[i][j] = i + j;
            end
        end
        
        // 写入 A 矩阵
        a_wr_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                a_wr_addr = i * 8 + j;
                a_wr_data = A[i][j];
                #CLK_PERIOD;
            end
        end
        a_wr_en = 0;
        
        // 写入 B 矩阵
        b_wr_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                b_wr_addr = i * 8 + j;
                b_wr_data = B[i][j];
                #CLK_PERIOD;
            end
        end
        b_wr_en = 0;
        $display("  Matrices written: A=I, B[i][j]=i+j");
        
        // 计算参考结果
        compute_reference();
        $display("  Reference computed: C=A*B=B (since A=I)");
        
        // 启动 GEMM
        $display("\n[Test] Run GEMM");
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // 等待完成
        while (!done) #CLK_PERIOD;
        $display("  GEMM completed");
        
        // 读取并验证结果（第 0 行）
        $display("\n[Verify] Check C[0][j] (expected: 0,1,2,3,4,5,6,7)");
        c_rd_row = 0;
        #CLK_PERIOD;
        
        for (j = 0; j < 8; j = j + 1) begin
            if (c_rd_data[j*32 +: 32] !== C_ref[0][j]) begin
                $display("  ERROR C[0][%0d]: Expected %0d, Got %0d", 
                         j, C_ref[0][j], $signed(c_rd_data[j*32 +: 32]));
                errors = errors + 1;
            end else begin
                $display("  C[0][%0d] = %0d (correct)", j, $signed(c_rd_data[j*32 +: 32]));
            end
        end
        
        if (errors == 0) begin
            $display("\n  ✅ PASS: All results correct!");
        end else begin
            $display("\n  ❌ FAILED: %0d errors", errors);
        end
        
        #(CLK_PERIOD * 10);
        $display("\n===== Test Complete =====");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_gemm_top.fsdb");
        $fsdbDumpvars(0, tb_gemm_top);
    end

endmodule
