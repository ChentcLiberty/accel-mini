/**
 * GEMM Memory Module
 * 
 * 存储 8×8 矩阵 A, B, C
 * - A, B: 64 × 8-bit
 * - C: 64 × 32-bit
 */

module gemm_mem #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8,
    parameter MEM_DEPTH  = 64  // 8×8
)(
    input  wire                         clk,
    input  wire                         rst_n,
    
    // A 矩阵写入接口
    input  wire                         a_wr_en,
    input  wire [5:0]                   a_wr_addr,
    input  wire [DATA_WIDTH-1:0]        a_wr_data,
    
    // B 矩阵写入接口
    input  wire                         b_wr_en,
    input  wire [5:0]                   b_wr_addr,
    input  wire [DATA_WIDTH-1:0]        b_wr_data,
    
    // C 矩阵写入接口
    input  wire                         c_wr_en,
    input  wire [5:0]                   c_wr_addr,
    input  wire [ACC_WIDTH-1:0]         c_wr_data,
    
    // A 矩阵读取接口（按行读取）
    input  wire [2:0]                   a_rd_row,
    output wire [ARRAY_SIZE*DATA_WIDTH-1:0] a_rd_data,
    
    // B 矩阵读取接口（按列读取）
    input  wire [2:0]                   b_rd_col,
    output wire [ARRAY_SIZE*DATA_WIDTH-1:0] b_rd_data,
    
    // C 矩阵读取接口（按行读取）
    input  wire [2:0]                   c_rd_row,
    output wire [ARRAY_SIZE*ACC_WIDTH-1:0] c_rd_data
);

    // 内部存储器
    reg signed [DATA_WIDTH-1:0] a_mem [0:MEM_DEPTH-1];
    reg signed [DATA_WIDTH-1:0] b_mem [0:MEM_DEPTH-1];
    reg signed [ACC_WIDTH-1:0]  c_mem [0:MEM_DEPTH-1];
    
    integer i;
    
    // A 矩阵写入
    always @(posedge clk) begin
        if (a_wr_en) begin
            a_mem[a_wr_addr] <= a_wr_data;
        end
    end
    
    // B 矩阵写入
    always @(posedge clk) begin
        if (b_wr_en) begin
            b_mem[b_wr_addr] <= b_wr_data;
        end
    end
    
    // C 矩阵写入
    always @(posedge clk) begin
        if (c_wr_en) begin
            c_mem[c_wr_addr] <= c_wr_data;
        end
    end
    
    // A 矩阵按行读取
    genvar j;
    generate
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : gen_a_read
            assign a_rd_data[(j+1)*DATA_WIDTH-1 : j*DATA_WIDTH] = 
                   a_mem[a_rd_row * ARRAY_SIZE + j];
        end
    endgenerate
    
    // B 矩阵按列读取
    generate
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : gen_b_read
            assign b_rd_data[(j+1)*DATA_WIDTH-1 : j*DATA_WIDTH] = 
                   b_mem[j * ARRAY_SIZE + b_rd_col];
        end
    endgenerate
    
    // C 矩阵按行读取
    generate
        for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : gen_c_read
            assign c_rd_data[(j+1)*ACC_WIDTH-1 : j*ACC_WIDTH] = 
                   c_mem[c_rd_row * ARRAY_SIZE + j];
        end
    endgenerate

endmodule
