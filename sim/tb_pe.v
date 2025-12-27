/**
 * PE 模块的 Verilog Testbench
 */

`timescale 1ns / 1ps

module tb_pe;

    // 参数
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    
    // 信号
    reg                         clk;
    reg                         rst_n;
    reg                         load;
    reg  signed [DATA_WIDTH-1:0] a;
    reg  signed [DATA_WIDTH-1:0] b;
    wire signed [ACC_WIDTH-1:0]  acc;
    
    // 实例化 PE
    pe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_pe (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .a(a),
        .b(b),
        .acc(acc)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 测试激励
    initial begin
        $display("===== PE Testbench Start =====");
        
        // 初始化
        rst_n = 0;
        load  = 0;
        a     = 0;
        b     = 0;
        
        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // 测试 1: 简单累加
        $display("\n[Test 1] Simple MAC: 1*2 + 3*4 + 5*6");
        load = 1; a = 8'd1; b = 8'd2; #CLK_PERIOD;  // acc = 1*2 = 2
        load = 0; a = 8'd3; b = 8'd4; #CLK_PERIOD;  // acc = 2 + 3*4 = 14
        a = 8'd5; b = 8'd6; #CLK_PERIOD;            // acc = 14 + 5*6 = 44
        $display("  Expected: 44, Got: %d", $signed(acc));
        if (acc !== 32'sd44) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 2: 负数
        $display("\n[Test 2] Negative numbers: (-1)*2 + 3*(-4)");
        load = 1; a = -8'd1; b = 8'd2;  #CLK_PERIOD;  // acc = -2
        load = 0; a = 8'd3;  b = -8'd4; #CLK_PERIOD;  // acc = -2 + (-12) = -14
        $display("  Expected: -14, Got: %d", $signed(acc));
        if (acc !== -32'sd14) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 3: 边界值
        $display("\n[Test 3] Boundary values: 127*127 + (-128)*(-128)");
        load = 1; a = 8'sd127;  b = 8'sd127;  #CLK_PERIOD;   // 16129
        load = 0; a = -8'sd128; b = -8'sd128; #CLK_PERIOD;   // 16129 + 16384 = 32513
        $display("  Expected: 32513, Got: %d", $signed(acc));
        if (acc !== 32'sd32513) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        // 测试 4: Load 信号
        $display("\n[Test 4] Load signal clears accumulator");
        load = 0; a = 8'd10; b = 8'd10; #CLK_PERIOD;  // acc = 32513 + 100 = 32613
        $display("  After accumulate: %d", $signed(acc));
        load = 1; a = 8'd1;  b = 8'd1;  #CLK_PERIOD;  // acc = 1 (cleared)
        $display("  After load: %d", $signed(acc));
        if (acc !== 32'sd1) $display("  ❌ FAILED");
        else $display("  ✅ PASSED");
        
        #(CLK_PERIOD * 5);
        $display("\n===== PE Testbench End =====");
        $finish;
    end
    
 //   // 波形输出
 //   initial begin
  //      $dumpfile("tb_pe.vcd");
  //      $dumpvars(0, tb_pe);
  //  end
    
    // 波形输出 (FSDB for Verdi)
    initial begin
        $fsdbDumpfile("tb_pe.fsdb");
        $fsdbDumpvars(0, tb_pe);
    end



endmodule

