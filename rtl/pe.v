/**
 * Processing Element (PE)
 * 
 * 功能：INT8 MAC (Multiply-Accumulate)
 * acc = acc + a * b
 * 
 * 参数：
 * - DATA_WIDTH: 输入数据位宽 (8-bit)
 * - ACC_WIDTH:  累加器位宽 (32-bit)
 */

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     load,      // 加载新数据并清零累加器
    input  wire signed [DATA_WIDTH-1:0] a,     // 输入 A (INT8)
    input  wire signed [DATA_WIDTH-1:0] b,     // 输入 B (INT8)
    output wire signed [ACC_WIDTH-1:0]  acc    // 累加器输出 (INT32)
);

    // 内部寄存器
    reg signed [ACC_WIDTH-1:0] acc_reg;
    
    // 组合逻辑：乘法
    wire signed [2*DATA_WIDTH-1:0] mult;
    assign mult = a * b;  // INT8 × INT8 = INT16
    
    // 时序逻辑：累加
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg <= {ACC_WIDTH{1'b0}};
        end else if (load) begin
            // 加载模式：清零并加载第一个乘积
            acc_reg <= {{(ACC_WIDTH-2*DATA_WIDTH){mult[2*DATA_WIDTH-1]}}, mult};
        end else begin
            // 累加模式：acc += a * b
            acc_reg <= acc_reg + {{(ACC_WIDTH-2*DATA_WIDTH){mult[2*DATA_WIDTH-1]}}, mult};
        end
    end
    
    // 输出
    assign acc = acc_reg;

endmodule

