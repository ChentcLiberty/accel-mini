/**
 * GEMM AXI Interface Testbench
 */

`timescale 1ns / 1ps

module tb_gemm_axi;

    parameter CLK_PERIOD = 10;
    
    reg         aclk, aresetn;
    reg  [11:0] awaddr, araddr;
    reg         awvalid, wvalid, arvalid, bready, rready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;
    
    gemm_axi u_axi (
        .aclk(aclk), .aresetn(aresetn),
        .awaddr(awaddr), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wvalid(wvalid), .wready(wready),
        .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid), .arready(arready),
        .rdata(rdata), .rresp(rresp), .rvalid(rvalid), .rready(rready)
    );
    
    initial begin aclk = 0; forever #(CLK_PERIOD/2) aclk = ~aclk; end
    
    // AXI 写任务
    task axi_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            @(posedge aclk);
            awaddr = addr;
            awvalid = 1'b1;
            wdata = data;
            wstrb = 4'hF;
            wvalid = 1'b1;
            bready = 1'b1;
            
            wait(awready);
            @(posedge aclk);
            awvalid = 1'b0;
            
            wait(wready);
            @(posedge aclk);
            wvalid = 1'b0;
            
            wait(bvalid);
            @(posedge aclk);
            bready = 1'b0;
        end
    endtask
    
    // AXI 读任务
    task axi_read;
        input  [11:0] addr;
        output [31:0] data;
        begin
            @(posedge aclk);
            araddr = addr;
            arvalid = 1'b1;
            rready = 1'b1;
            
            wait(arready);
            @(posedge aclk);
            arvalid = 1'b0;
            
            wait(rvalid);
            data = rdata;
            @(posedge aclk);
            rready = 1'b0;
        end
    endtask
    
    integer i, j;
    reg [31:0] status;
    
    initial begin
        $display("===== GEMM AXI Interface Test =====");
        
        aresetn = 0;
        awaddr = 0; araddr = 0;
        awvalid = 0; wvalid = 0; arvalid = 0;
        bready = 0; rready = 0;
        wdata = 0; wstrb = 0;
        
        #(CLK_PERIOD * 3);
        aresetn = 1;
        #CLK_PERIOD;
        
        // 写入 A 矩阵（单位矩阵）
        $display("\n[Test 1] Write A matrix via AXI");
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                axi_write(12'h100 + (i*8+j)*4, (i == j) ? 1 : 0);
            end
        end
        $display("  A matrix written");
        
        // 写入 B 矩阵
        $display("\n[Test 2] Write B matrix via AXI");
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                axi_write(12'h200 + (i*8+j)*4, i + j);
            end
        end
        $display("  B matrix written");
        
        // 启动 GEMM
        $display("\n[Test 3] Start GEMM");
        axi_write(12'h000, 32'h1);
        $display("  GEMM started");
        
        // 轮询状态
        repeat (20) begin
            axi_read(12'h004, status);
            $display("  STATUS = 0x%h (busy=%b, done=%b)", 
                     status, status[0], status[1]);
            if (status[1]) break;
            #(CLK_PERIOD * 5);
        end
        
        // 读取结果
        if (status[1]) begin
            $display("\n[Test 4] Read C[0][0..7]");
            for (j = 0; j < 8; j = j + 1) begin
                axi_read(12'h300 + j*4, status);
                $display("  C[0][%0d] = %0d", j, status);
            end
        end
        
        #(CLK_PERIOD * 10);
        $display("\n===== Test Complete =====");
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_gemm_axi.fsdb");
        $fsdbDumpvars(0, tb_gemm_axi);
    end

endmodule
