/**
 * PE Testbench - FIXED VERSION
 * 修复：添加 enable 信号
 */

`timescale 1ns / 1ps

module tb_pe;

    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter CLK_PERIOD = 10;
    
    reg                         clk;
    reg                         rst_n;
    reg                         en;        // 新增
    reg                         load;
    reg  signed [DATA_WIDTH-1:0] a;
    reg  signed [DATA_WIDTH-1:0] b;
    wire signed [ACC_WIDTH-1:0]  acc;
    
    pe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),           // 新增
        .load(load),
        .a(a),
        .b(b),
        .acc(acc)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        $display("===== PE Testbench Start =====");
        
        rst_n = 0;
        en    = 0;     // 初始禁用
        load  = 0;
        a     = 0;
        b     = 0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // 测试 1: 简单累加
        $display("\n[Test 1] Simple MAC: 1*2 + 3*4 + 5*6");
        en = 1;                                       // 使能
        load = 1; a = 8'd1; b = 8'd2; #CLK_PERIOD;
        load = 0; a = 8'd3; b = 8'd4; #CLK_PERIOD;
        a = 8'd5; b = 8'd6; #CLK_PERIOD;
        en = 0;                                       // 禁用
        #CLK_PERIOD;
        $display("  Expected: 44, Got: %d", $signed(acc));
        if (acc !== 32'sd44) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 2: 负数
        $display("\n[Test 2] Negative numbers: (-1)*2 + 3*(-4)");
        en = 1;
        load = 1; a = -8'd1; b = 8'd2;  #CLK_PERIOD;
        load = 0; a = 8'd3;  b = -8'd4; #CLK_PERIOD;
        en = 0;
        #CLK_PERIOD;
        $display("  Expected: -14, Got: %d", $signed(acc));
        if (acc !== -32'sd14) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 3: 边界值
        $display("\n[Test 3] Boundary values: 127*127 + (-128)*(-128)");
        en = 1;
        load = 1; a = 8'sd127;  b = 8'sd127;  #CLK_PERIOD;
        load = 0; a = -8'sd128; b = -8'sd128; #CLK_PERIOD;
        en = 0;
        #CLK_PERIOD;
        $display("  Expected: 32513, Got: %d", $signed(acc));
        if (acc !== 32'sd32513) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 4: Enable 信号测试
        $display("\n[Test 4] Enable signal prevents accumulation");
        en = 1;
        load = 1; a = 8'd10; b = 8'd10; #CLK_PERIOD;   // acc = 100
        en = 0;                                         // 禁用
        load = 0; a = 8'd20; b = 8'd20; #CLK_PERIOD;   // 应该不累加
        #CLK_PERIOD;
        $display("  Expected: 100 (no change), Got: %d", $signed(acc));
        if (acc !== 32'sd100) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 5: Load 信号
        $display("\n[Test 5] Load signal clears accumulator");
        en = 1;
        load = 0; a = 8'd5; b = 8'd5; #CLK_PERIOD;     // acc = 100 + 25 = 125
        load = 1; a = 8'd1; b = 8'd1; #CLK_PERIOD;     // acc = 1 (cleared)
        en = 0;
        #CLK_PERIOD;
        $display("  Expected: 1, Got: %d", $signed(acc));
        if (acc !== 32'sd1) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        #(CLK_PERIOD * 5);
        $display("\n===== PE Testbench End =====");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_pe.fsdb");
        $fsdbDumpvars(0, tb_pe);
    end

endmodule
