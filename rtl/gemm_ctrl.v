/**
 * GEMM Controller (Fixed: done signal holds until next start)
 */

module gemm_ctrl #(
    parameter ARRAY_SIZE = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         done,
    output reg         busy,
    output reg         pe_en,
    output reg         pe_load,
    output reg  [3:0]  k_idx,
    output reg  [15:0] a_addr,
    output reg  [15:0] b_addr,
    output reg  [15:0] c_addr,
    output reg         a_rd_en,
    output reg         b_rd_en,
    output reg         c_wr_en
);

    localparam S_IDLE    = 3'd0;
    localparam S_LOAD    = 3'd1;
    localparam S_COMPUTE = 3'd2;
    localparam S_STORE   = 3'd3;
    localparam S_DONE    = 3'd4;
    
    reg [2:0] state, next_state;
    reg [3:0] cnt;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end
    
    // 次态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_LOAD;
            end
            S_LOAD: begin
                next_state = S_COMPUTE;
            end
            S_COMPUTE: begin
                if (k_idx == ARRAY_SIZE - 1)
                    next_state = S_STORE;
            end
            S_STORE: begin
                if (cnt == ARRAY_SIZE - 1)
                    next_state = S_DONE;
            end
            S_DONE: begin
                if (start)  // 等待下一次 start
                    next_state = S_LOAD;
            end
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
            busy <= 1'b0;
            pe_en <= 1'b0;
            pe_load <= 1'b0;
            k_idx <= 0;
            cnt <= 0;
            a_addr <= 0;
            b_addr <= 0;
            c_addr <= 0;
            a_rd_en <= 1'b0;
            b_rd_en <= 1'b0;
            c_wr_en <= 1'b0;
        end else begin
            // 默认值
            pe_load <= 1'b0;
            c_wr_en <= 1'b0;
            
            case (state)
                S_IDLE: begin
                    done <= 1'b0;  // 只有 IDLE 时清除 done
                    busy <= 1'b0;
                    pe_en <= 1'b0;
                    k_idx <= 0;
                    cnt <= 0;
                    if (start) begin
                        busy <= 1'b1;
                        pe_load <= 1'b1;
                    end
                end
                
                S_LOAD: begin
                    pe_en <= 1'b1;
                    a_rd_en <= 1'b1;
                    b_rd_en <= 1'b1;
                end
                
                S_COMPUTE: begin
                    pe_en <= 1'b1;
                    if (k_idx < ARRAY_SIZE - 1)
                        k_idx <= k_idx + 1;
                end
                
                S_STORE: begin
                    pe_en <= 1'b0;
                    c_wr_en <= 1'b1;
                    c_addr <= {12'b0, cnt};
                    cnt <= cnt + 1;
                end
                
                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;  // done 保持为 1
                    if (start) begin
                        done <= 1'b0;
                        busy <= 1'b1;
                        pe_load <= 1'b1;
                        k_idx <= 0;
                        cnt <= 0;
                    end
                end
            endcase
        end
    end

endmodule
