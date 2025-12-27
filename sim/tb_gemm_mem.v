/**
 * GEMM Memory Testbench
 */

`timescale 1ns / 1ps

module tb_gemm_mem;

    parameter CLK_PERIOD = 10;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter ARRAY_SIZE = 8;
    
    reg         clk, rst_n;
    reg         a_wr_en, b_wr_en, c_wr_en;
    reg  [5:0]  a_wr_addr, b_wr_addr, c_wr_addr;
    reg  [7:0]  a_wr_data, b_wr_data;
    reg  [31:0] c_wr_data;
    reg  [2:0]  a_rd_row, b_rd_col, c_rd_row;
    wire [63:0] a_rd_data, b_rd_data;
    wire [255:0] c_rd_data;
    
    gemm_mem u_mem (
        .clk(clk), .rst_n(rst_n),
        .a_wr_en(a_wr_en), .a_wr_addr(a_wr_addr), .a_wr_data(a_wr_data),
        .b_wr_en(b_wr_en), .b_wr_addr(b_wr_addr), .b_wr_data(b_wr_data),
        .c_wr_en(c_wr_en), .c_wr_addr(c_wr_addr), .c_wr_data(c_wr_data),
        .a_rd_row(a_rd_row), .a_rd_data(a_rd_data),
        .b_rd_col(b_rd_col), .b_rd_data(b_rd_data),
        .c_rd_row(c_rd_row), .c_rd_data(c_rd_data)
    );
    
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end
    
    integer i, j, errors;
    reg [7:0] expected_a, expected_b;
    reg [31:0] expected_c;
    
    initial begin
        $display("===== GEMM Memory Test =====");
        
        rst_n = 0; 
        a_wr_en = 0; b_wr_en = 0; c_wr_en = 0;
        a_wr_addr = 0; b_wr_addr = 0; c_wr_addr = 0;
        a_wr_data = 0; b_wr_data = 0; c_wr_data = 0;
        a_rd_row = 0; b_rd_col = 0; c_rd_row = 0;
        errors = 0;
        
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #CLK_PERIOD;
        
        // 测试 1: 写入 A 矩阵
        $display("\n[Test 1] Write A matrix");
        a_wr_en = 1;
        for (i = 0; i < 64; i = i + 1) begin
            a_wr_addr = i;
            a_wr_data = i;
            #CLK_PERIOD;
        end
        a_wr_en = 0;
        $display("  Done writing A");
        
        // 测试 2: 读取 A 矩阵第 0 行
        $display("\n[Test 2] Read A matrix row 0");
        a_rd_row = 0;
        #CLK_PERIOD;
        for (j = 0; j < 8; j = j + 1) begin
            expected_a = j;
            if (a_rd_data[j*8 +: 8] !== expected_a) begin
                $display("  ERROR A[0][%0d]: Expected %0d, Got %0d", j, expected_a, a_rd_data[j*8 +: 8]);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("  PASS: A row 0 correct");
        
        // 测试 3: 写入 B 矩阵
        $display("\n[Test 3] Write B matrix");
        b_wr_en = 1;
        for (i = 0; i < 64; i = i + 1) begin
            b_wr_addr = i;
            b_wr_data = 100 + i;
            #CLK_PERIOD;
        end
        b_wr_en = 0;
        $display("  Done writing B");
        
        // 测试 4: 读取 B 矩阵第 0 列
        $display("\n[Test 4] Read B matrix col 0");
        b_rd_col = 0;
        #CLK_PERIOD;
        errors = 0;
        for (j = 0; j < 8; j = j + 1) begin
            expected_b = 100 + j * 8;
            if (b_rd_data[j*8 +: 8] !== expected_b) begin
                $display("  ERROR B[%0d][0]: Expected %0d, Got %0d", j, expected_b, b_rd_data[j*8 +: 8]);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("  PASS: B col 0 correct");
        
        // 测试 5: 写入和读取 C 矩阵
        $display("\n[Test 5] Write and read C matrix");
        c_wr_en = 1;
        for (i = 0; i < 64; i = i + 1) begin
            c_wr_addr = i;
            c_wr_data = 1000 + i;
            #CLK_PERIOD;
        end
        c_wr_en = 0;
        
        c_rd_row = 0;
        #CLK_PERIOD;
        errors = 0;
        for (j = 0; j < 8; j = j + 1) begin
            expected_c = 1000 + j;
            if (c_rd_data[j*32 +: 32] !== expected_c) begin
                $display("  ERROR C[0][%0d]: Expected %0d, Got %0d", j, expected_c, c_rd_data[j*32 +: 32]);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("  PASS: C row 0 correct");
        
        #(CLK_PERIOD * 5);
        $display("\n===== Test Complete =====");
        $finish;
    end
    
    initial begin

        $fsdbDumpvars(0, tb_gemm_mem);
    end

endmodule
