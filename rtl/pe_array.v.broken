/**
 * PE Array - 8x8 Systolic Array for GEMM - FIXED VERSION
 * 
 * 修复：添加 enable 信号传递到每个 PE
 */

module pe_array #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     en,            // 使能信号（修复点）
    input  wire                     load,
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] a_row,
    input  wire signed [ARRAY_SIZE*DATA_WIDTH-1:0] b_col,
    output wire signed [ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0] c_out
);

    genvar i, j;
    generate
        for (i = 0; i < ARRAY_SIZE; i = i + 1) begin : row
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin : col
                
                wire signed [DATA_WIDTH-1:0] a_val;
                wire signed [DATA_WIDTH-1:0] b_val;
                wire signed [ACC_WIDTH-1:0]  c_val;
                
                assign a_val = a_row[(i+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                assign b_val = b_col[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .en(en),           // 连接使能信号（修复点）
                    .load(load),
                    .a(a_val),
                    .b(b_val),
                    .acc(c_val)
                );
                
                assign c_out[(i*ARRAY_SIZE+j+1)*ACC_WIDTH-1 -: ACC_WIDTH] = c_val;
                
            end
        end
    endgenerate

endmodule
