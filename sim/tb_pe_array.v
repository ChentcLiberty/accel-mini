/**
 * PE Array Testbench - FIXED VERSION
 * 修复：使用 enable 信号控制累加开始和结束
 */

`timescale 1ns / 1ps

module tb_pe_array;

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter ARRAY_SIZE = 8;
    parameter CLK_PERIOD = 10;
    
    reg                                 clk;
    reg                                 rst_n;
    reg                                 en;        // 新增
    reg                                 load;
    reg  signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_row;
    reg  signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_col;
    wire signed [ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0] c_out;
    
    reg signed [DATA_WIDTH-1:0] A [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [DATA_WIDTH-1:0] B [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    reg signed [ACC_WIDTH-1:0]  C_ref [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    
    integer i, j, k;
    integer errors;
    
    pe_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE)
    ) u_pe_array (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),           // 新增
        .load(load),
        .a_row(a_row),
        .b_col(b_col),
        .c_out(c_out)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    function signed [ACC_WIDTH-1:0] get_c;
        input integer row, col;
        begin
            get_c = c_out[(row*ARRAY_SIZE+col+1)*ACC_WIDTH-1 -: ACC_WIDTH];
        end
    endfunction
    
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
    
    // 运行 GEMM 的 task（封装公共逻辑）
    task run_gemm;
        begin
            en = 1;            // 使能 PE
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
            
            en = 0;            // 禁用 PE（停止累加）
            #CLK_PERIOD;       // 等待结果稳定
        end
    endtask
    
    // 验证结果的 task
    task verify_result;
        begin
            errors = 0;
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
                $display("  ✅ PASSED");
                $display("  Sample: C[0][0]=%0d, C[7][7]=%0d", 
                         get_c(0, 0), get_c(7, 7));
            end else begin
                $display("  Total errors: %0d", errors);
            end
        end
    endtask
    
    initial begin
        $display("===== PE Array Testbench Start =====");
        $display("Array Size: %0d x %0d", ARRAY_SIZE, ARRAY_SIZE);
        
        rst_n = 0;
        en    = 0;     // 初始禁用
        load  = 0;
        a_row = 0;
        b_col = 0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // ========== 测试 1: 单位矩阵 ==========
        $display("\n[Test 1] Identity matrix * B = B");
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = (i == j) ? 8'd1 : 8'd0;
                B[i][j] = i + j;
            end
        end
        
        compute_reference();
        run_gemm();
        verify_result();
        
        // ========== 测试 2: 随机矩阵 ==========
        $display("\n[Test 2] Random matrix multiplication");
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = $random % 64 - 32;
                B[i][j] = $random % 64 - 32;
            end
        end
        
        compute_reference();
        run_gemm();
        verify_result();
        
        // ========== 测试 3: 边界值 ==========
        $display("\n[Test 3] Boundary values (127, -128)");
        
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                A[i][j] = (i + j) % 2 == 0 ? 8'sd127 : -8'sd128;
                B[i][j] = (i + j) % 2 == 0 ? 8'sd127 : -8'sd128;
            end
        end
        
        compute_reference();
        run_gemm();
        verify_result();
        
        #(CLK_PERIOD * 5);
        $display("\n===== PE Array Testbench End =====");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_pe_array.fsdb");
        $fsdbDumpvars(0, tb_pe_array);
    end

endmodule
