/**
 * GEMM AXI4-Lite Slave Interface
 */

module gemm_axi #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter ARRAY_SIZE = 8,
    parameter AXI_ADDR_WIDTH = 12,
    parameter AXI_DATA_WIDTH = 32
)(
    input  wire                         aclk,
    input  wire                         aresetn,
    
    // Write Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0]   awaddr,
    input  wire                         awvalid,
    output reg                          awready,
    
    // Write Data Channel
    input  wire [AXI_DATA_WIDTH-1:0]   wdata,
    input  wire [3:0]                   wstrb,
    input  wire                         wvalid,
    output reg                          wready,
    
    // Write Response Channel
    output reg  [1:0]                   bresp,
    output reg                          bvalid,
    input  wire                         bready,
    
    // Read Address Channel
    input  wire [AXI_ADDR_WIDTH-1:0]   araddr,
    input  wire                         arvalid,
    output reg                          arready,
    
    // Read Data Channel
    output reg  [AXI_DATA_WIDTH-1:0]   rdata,
    output reg  [1:0]                   rresp,
    output reg                          rvalid,
    input  wire                         rready
);

    localparam ADDR_CTRL   = 12'h000;
    localparam ADDR_STATUS = 12'h004;
    localparam ADDR_A_BASE = 12'h100;
    localparam ADDR_B_BASE = 12'h200;
    localparam ADDR_C_BASE = 12'h300;
    
    reg  start_reg;
    wire done, busy;
    reg  a_wr_en, b_wr_en;
    reg  [5:0] a_wr_addr, b_wr_addr;
    reg  [7:0] a_wr_data, b_wr_data;
    reg  [2:0] c_rd_row;
    wire [255:0] c_rd_data;
    
    gemm_top u_gemm (
        .clk(aclk), .rst_n(aresetn),
        .start(start_reg), .done(done), .busy(busy),
        .a_wr_en(a_wr_en), .a_wr_addr(a_wr_addr), .a_wr_data(a_wr_data),
        .b_wr_en(b_wr_en), .b_wr_addr(b_wr_addr), .b_wr_data(b_wr_data),
        .c_rd_row(c_rd_row), .c_rd_data(c_rd_data)
    );
    
    reg [AXI_ADDR_WIDTH-1:0] aw_addr_reg;
    reg [AXI_DATA_WIDTH-1:0] w_data_reg;
    reg write_done;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready <= 1'b0;
            aw_addr_reg <= 0;
        end else begin
            if (awvalid && !awready) begin
                awready <= 1'b1;
                aw_addr_reg <= awaddr;
            end else begin
                awready <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wready <= 1'b0;
            w_data_reg <= 0;
        end else begin
            if (wvalid && !wready) begin
                wready <= 1'b1;
                w_data_reg <= wdata;
            end else begin
                wready <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            write_done <= 1'b0;
        else
            write_done <= awready && wready;
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end else begin
            if (write_done && !bvalid) begin
                bvalid <= 1'b1;
                bresp <= 2'b00;
            end else if (bvalid && bready) begin
                bvalid <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            start_reg <= 1'b0;
            a_wr_en <= 1'b0;
            b_wr_en <= 1'b0;
            a_wr_addr <= 0;
            b_wr_addr <= 0;
            a_wr_data <= 0;
            b_wr_data <= 0;
        end else begin
            start_reg <= 1'b0;
            a_wr_en <= 1'b0;
            b_wr_en <= 1'b0;
            
            if (write_done) begin
                if (aw_addr_reg == ADDR_CTRL) begin
                    start_reg <= w_data_reg[0];
                end else if (aw_addr_reg >= ADDR_A_BASE && aw_addr_reg < ADDR_B_BASE) begin
 
                    a_wr_addr <= aw_addr_reg[7:2];
                    a_wr_data <= w_data_reg[7:0];
                end else if (aw_addr_reg >= ADDR_B_BASE && aw_addr_reg < ADDR_C_BASE) begin
                    b_wr_en <= 1'b1;
                    b_wr_addr <= aw_addr_reg[7:2];
                    b_wr_data <= w_data_reg[7:0];
                end
            end
        end
    end
    
    reg [AXI_ADDR_WIDTH-1:0] ar_addr_reg;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            arready <= 1'b0;
            ar_addr_reg <= 0;
        end else begin
            if (arvalid && !arready) begin
                arready <= 1'b1;
                ar_addr_reg <= araddr;
            end else begin
                arready <= 1'b0;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rvalid <= 1'b0;
            rdata <= 0;
            rresp <= 2'b00;
            c_rd_row <= 0;
        end else begin
            if (arready && !rvalid) begin
                rvalid <= 1'b1;
                rresp <= 2'b00;
                
                if (ar_addr_reg == ADDR_STATUS) begin
                    rdata <= {30'b0, done, busy};
                end else if (ar_addr_reg >= ADDR_C_BASE) begin
                    c_rd_row <= ar_addr_reg[5:3];
                    rdata <= c_rd_data[(ar_addr_reg[2:0]*32) +: 32];
                end else begin
                    rdata <= 32'h0;
                end
            end else if (rvalid && rready) begin
                rvalid <= 1'b0;
            end
        end
    end

endmodule
