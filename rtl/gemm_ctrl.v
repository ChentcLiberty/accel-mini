/**
 * GEMM Controller - FSM for 8x8 GEMM
 * 
 * 状态: IDLE -> COMPUTE -> STORE -> DONE
 */

module gemm_ctrl #(
    parameter ARRAY_SIZE = 8,
    parameter ADDR_WIDTH = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,
    
    // 控制接口
    input  wire                     start,
    output reg                      done,
    output reg                      busy,
    
    // PE Array 控制
    output reg                      pe_en,
    output reg                      pe_load,
    
    // 存储器接口
    output reg  [ADDR_WIDTH-1:0]    a_addr,
    output reg  [ADDR_WIDTH-1:0]    b_addr,
    output reg  [ADDR_WIDTH-1:0]    c_addr,
    output reg                      a_rd_en,
    output reg                      b_rd_en,
    output reg                      c_wr_en,
    
    // K 维度索引
    output reg  [3:0]               k_idx
);

    // 状态定义
    localparam S_IDLE    = 2'd0;
    localparam S_COMPUTE = 2'd1;
    localparam S_STORE   = 2'd2;
    localparam S_DONE    = 2'd3;
    
    reg [1:0] state, next_state;
    reg [3:0] k_cnt;
    reg [3:0] store_cnt;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:    if (start) next_state = S_COMPUTE;
            S_COMPUTE: if (k_cnt == ARRAY_SIZE - 1) next_state = S_STORE;
            S_STORE:   if (store_cnt == ARRAY_SIZE - 1) next_state = S_DONE;
            S_DONE:    next_state = S_IDLE;
        endcase
    end
    
    // K 计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            k_cnt <= 0;
        else if (state == S_IDLE)
            k_cnt <= 0;
        else if (state == S_COMPUTE)
            k_cnt <= k_cnt + 1;
    end
    
    // 存储计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            store_cnt <= 0;
        else if (state == S_STORE)
            store_cnt <= store_cnt + 1;
        else
            store_cnt <= 0;
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done     <= 0;
            busy     <= 0;
            pe_en    <= 0;
            pe_load  <= 0;
            a_rd_en  <= 0;
            b_rd_en  <= 0;
            c_wr_en  <= 0;
            a_addr   <= 0;
            b_addr   <= 0;
            c_addr   <= 0;
            k_idx    <= 0;
        end else begin
            // 默认值
            done    <= 0;
            pe_load <= 0;
            c_wr_en <= 0;
            
            case (state)
                S_IDLE: begin
                    busy    <= 0;
                    pe_en   <= 0;
                    a_rd_en <= 0;
                    b_rd_en <= 0;
                    if (start) busy <= 1;
                end
                
                S_COMPUTE: begin
                    busy    <= 1;
                    pe_en   <= 1;
                    a_rd_en <= 1;
                    b_rd_en <= 1;
                    k_idx   <= k_cnt;
                    a_addr  <= k_cnt;
                    b_addr  <= k_cnt;
                    if (k_cnt == 0) pe_load <= 1;
                end
                
                S_STORE: begin
                    busy    <= 1;
                    pe_en   <= 0;
                    a_rd_en <= 0;
                    b_rd_en <= 0;
                    c_wr_en <= 1;
                    c_addr  <= store_cnt;
                end
                
                S_DONE: begin
                    done <= 1;
                    busy <= 0;
                end
            endcase
        end
    end

endmodule

