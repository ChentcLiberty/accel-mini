/**
 * PE Array - 8×8 Systolic Array for GEMM
 * 
 * 功能：计算 C[8×8] = A[8×8] × B[8×8]
 * 
 * 数据流：
 * - A: 每行广播到对应行的 8 个 PE
 * - B: 每列广播到对应列的 8 个 PE
 * - C: 每个 PE 输出一个累加结果
 */

module pe_array #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     load,          // 清零所有累加器
    
    // A 输入：8 个 INT8（每行一个）
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_row,
    
    // B 输入：8 个 INT8（每列一个）
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_col,
    
    // C 输出：64 个 INT32（8×8 矩阵）
    output wire signed [ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0] c_out
);

    // 生成 8×8 PE 阵列
    genvar i, j;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : row
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : col
                
                // 提取 A[i] 和 B[j]
                wire signed [DATA_WIDTH-1:0] a_val;
                wire signed [DATA_WIDTH-1:0] b_val;
                wire signed [ACC_WIDTH-1:0]  c_val;
                
                assign a_val = a_row[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                assign b_val = b_col[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                
                // 实例化 PE
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .load(load),
                    .a(a_val),
                    .b(b_val),
                    .acc(c_val)
                );
                
                // 连接到输出
                // C[i][j] 的位置：(i * ARRAY_SIZE + j) * ACC_WIDTH
                assign c_out[(i*ARRAY_SIZE+j+1)*ACC_WIDTH-1 -: ACC_WIDTH] = c_val;
                
            end
        end
    endgenerate

endmodule

