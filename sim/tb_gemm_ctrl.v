/**
 * GEMM Controller Testbench
 */

`timescale 1ns / 1ps

module tb_gemm_ctrl;

    parameter CLK_PERIOD = 10;
    
    reg  clk, rst_n, start;
    wire done, busy, pe_en, pe_load;
    wire [15:0] a_addr, b_addr, c_addr;
    wire a_rd_en, b_rd_en, c_wr_en;
    wire [3:0] k_idx;
    
    gemm_ctrl u_ctrl (
        .clk(clk), .rst_n(rst_n), .start(start),
        .done(done), .busy(busy),
        .pe_en(pe_en), .pe_load(pe_load),
        .a_addr(a_addr), .b_addr(b_addr), .c_addr(c_addr),
        .a_rd_en(a_rd_en), .b_rd_en(b_rd_en), .c_wr_en(c_wr_en),
        .k_idx(k_idx)
    );
    
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end
    
    integer compute_cycles, store_cycles;
    
    initial begin
        $display("===== GEMM Controller Test =====");
        
        rst_n = 0; start = 0;
        compute_cycles = 0; store_cycles = 0;
        #(CLK_PERIOD * 3);
        rst_n = 1;
        #CLK_PERIOD;
        
        // 检查初始状态
        $display("\n[Test 1] Initial state");
        if (busy == 0 && done == 0)
            $display("  ✅ IDLE state correct");
        else
            $display("  ❌ Initial state wrong");
        
        // 启动 GEMM
        $display("\n[Test 2] GEMM execution");
        start = 1; #CLK_PERIOD; start = 0;
        
        // 等待 COMPUTE
        while (pe_en) begin
            $display("  COMPUTE: k=%0d, load=%b", k_idx, pe_load);
            compute_cycles = compute_cycles + 1;
            #CLK_PERIOD;
        end
        
        // 等待 STORE
        while (c_wr_en) begin
            $display("  STORE: c_addr=%0d", c_addr);
            store_cycles = store_cycles + 1;
            #CLK_PERIOD;
        end
        
        // 等待 DONE
        #CLK_PERIOD;
        
        // 验证
        $display("\n[Results]");
        if (compute_cycles == 8)
            $display("  ✅ Compute cycles: %0d", compute_cycles);
        else
            $display("  ❌ Compute cycles: %0d (expected 8)", compute_cycles);
            
        if (store_cycles == 8)
            $display("  ✅ Store cycles: %0d", store_cycles);
        else
            $display("  ❌ Store cycles: %0d (expected 8)", store_cycles);
        
        if (done == 1)
            $display("  ✅ Done signal received");
        else
            $display("  ❌ Done signal missing");
        
        #(CLK_PERIOD * 5);
        $display("\n===== Test Complete =====");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_gemm_ctrl.fsdb");
        $fsdbDumpvars(0, tb_gemm_ctrl);
    end

endmodule

