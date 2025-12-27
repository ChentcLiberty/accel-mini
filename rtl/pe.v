/**
 * Processing Element (PE) - FIXED VERSION
 * 
 * 功能：INT8 MAC (Multiply-Accumulate)
 * 修复：添加 enable 信号控制累加
 */

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,        // 使能信号（修复点）
    input  wire                     load,
    input  wire signed [DATA_WIDTH-1:0] a,
    input  wire signed [DATA_WIDTH-1:0] b,
    output wire signed [ACC_WIDTH-1:0]  acc
);

    reg signed [ACC_WIDTH-1:0] acc_reg;
    
    wire signed [2*DATA_WIDTH-1:0] mult;
    assign mult = a * b;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg <= {ACC_WIDTH{1'b0}};
        end else if (en) begin      // 只有 en=1 时才更新（修复点）
            if (load) begin
                acc_reg <= {{(ACC_WIDTH-2*DATA_WIDTH){mult[2*DATA_WIDTH-1]}}, mult};
            end else begin
                acc_reg <= acc_reg + {{(ACC_WIDTH-2*DATA_WIDTH){mult[2*DATA_WIDTH-1]}}, mult};
            end
        end
        // en=0 时保持当前值，不再累加
    end
    
    assign acc = acc_reg;

endmodule
