/**
 * GEMM Top Module - 顶层集成（修复版）
 */

module gemm_top #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    output wire                     done,
    output wire                     busy,
    
    input  wire                     a_wr_en,
    input  wire [5:0]               a_wr_addr,
    input  wire [DATA_WIDTH-1:0]    a_wr_data,
    
    input  wire                     b_wr_en,
    input  wire [5:0]               b_wr_addr,
    input  wire [DATA_WIDTH-1:0]    b_wr_data,
    
    input  wire [2:0]               c_rd_row,
    output wire [ARRAY_SIZE*ACC_WIDTH-1:0] c_rd_data
);

    wire pe_en, pe_load, c_wr_en;
    wire [3:0] k_idx;
    wire [15:0] c_addr;
    wire [ARRAY_SIZE*DATA_WIDTH-1:0] a_row, b_col;
    wire [ARRAY_SIZE*ARRAY_SIZE*ACC_WIDTH-1:0] c_out;
    
    // Memory 模块
    gemm_mem u_mem (
        .clk(clk), .rst_n(rst_n),
        .a_wr_en(a_wr_en), .a_wr_addr(a_wr_addr), .a_wr_data(a_wr_data),
        .b_wr_en(b_wr_en), .b_wr_addr(b_wr_addr), .b_wr_data(b_wr_data),
        .c_wr_en(c_wr_en), 
        .c_wr_addr(c_addr[5:0]), 
        .c_wr_data(c_out[c_addr[2:0]*ACC_WIDTH +: ACC_WIDTH]),
        .a_rd_row(k_idx[2:0]), .a_rd_data(a_row),
        .b_rd_col(k_idx[2:0]), .b_rd_data(b_col),
        .c_rd_row(c_rd_row), .c_rd_data(c_rd_data)
    );
    
    // PE Array
    pe_array u_pe_array (
        .clk(clk), .rst_n(rst_n),
        .en(pe_en), .load(pe_load),
        .a_row(a_row), .b_col(b_col), .c_out(c_out)
    );
    
    // 控制器
    gemm_ctrl u_ctrl (
        .clk(clk), .rst_n(rst_n),
        .start(start), .done(done), .busy(busy),
        .pe_en(pe_en), .pe_load(pe_load),
        .k_idx(k_idx),
        .a_addr(), .b_addr(),
        .c_addr(c_addr),
        .a_rd_en(), .b_rd_en(),
        .c_wr_en(c_wr_en)
    );

endmodule
