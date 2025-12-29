/**
 * GEMM AXI Interface Testbench - Debug Version
 */

`timescale 1ns / 1ps

module tb_gemm_axi_debug;

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
    
    // Monitor 内部信号
    wire gemm_start = u_axi.start_reg;
    wire gemm_done = u_axi.done;
    wire gemm_busy = u_axi.busy;
    
    initial begin
        $monitor("Time=%0t | start=%b busy=%b done=%b | pe_en=%b k_idx=%0d", 
                 $time, gemm_start, gemm_busy, gemm_done,
                 u_axi.u_gemm.u_ctrl.pe_en, u_axi.u_gemm.u_ctrl.k_idx);
    end
    
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
        $display("===== GEMM AXI Debug Test =====");
        
        aresetn = 0;
        awaddr = 0; araddr = 0;
        awvalid = 0; wvalid = 0; arvalid = 0;
        bready = 0; rready = 0;
        wdata = 0; wstrb = 0;
        
        #(CLK_PERIOD * 3);
        aresetn = 1;
        #CLK_PERIOD;
        
        // 简单测试：只写 A[0..7] 和 B[0..7]
        $display("\n[Test] Write small matrices");
        for (i = 0; i < 8; i = i + 1) begin
            axi_write(12'h100 + i*4, (i == 0) ? 1 : 0);  // A: [1,0,0,...]
            axi_write(12'h200 + i*4, i);                  // B: [0,1,2,...]
        end
        $display("  Data written");
        
        // 启动
        $display("\n[Test] Start GEMM");
        axi_write(12'h000, 32'h1);
        
        // 等待更长时间
        repeat (100) begin
            #(CLK_PERIOD * 2);
            axi_read(12'h004, status);
            if (status[1]) begin
                $display("  DONE! STATUS=0x%h", status);
                break;
            end
        end
        
        if (!status[1]) begin
            $display("  ERROR: Timeout waiting for done");
        end
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    initial begin
        $fsdbDumpfile("tb_gemm_axi_debug.fsdb");
        $fsdbDumpvars(0, tb_gemm_axi_debug);
    end

endmodule
