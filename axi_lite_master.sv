
// `include "E:\\work\\xilinx\\AXI4\\AXI4_BFM\\axi_interface.sv"
module axi_life_master #(
    parameter ASIZE = 8,
    parameter DSIZE = 32
)(
    axi_lite_inf.master inf
);

logic[DSIZE-1:0]        read_data;

initial begin
    set_idle;
end

task set_idle;
    inf.axi_lite_awvalid    = 1'd0;
    inf.axi_lite_awaddr     = {ASIZE{1'd0}};
    inf.axi_lite_wvalid     = 1'd0;
    inf.axi_lite_wdata      = {DSIZE{1'd0}};
    inf.axi_lite_bready     = 1'd1;
    inf.axi_lite_arvalid    = 1'd0;
    inf.axi_lite_araddr     = {ASIZE{1'd0}};
    inf.axi_lite_rready     = 1'b1;
endtask:set_idle

task automatic  read (input [ASIZE-1:0]    addr,output logic [DSIZE-1:0]   data);
    wait(inf.axi_lite_resetn);
    @(posedge inf.axi_lite_aclk);
    inf.axi_lite_arvalid    = 1'b1;
    inf.axi_lite_araddr     = addr;
    inf.axi_lite_rready     = 1'b1;
    fork
        begin
            wait(inf.axi_lite_arready);
            @(posedge inf.axi_lite_aclk);
            inf.axi_lite_arvalid    = 1'b0;
        end
        begin
            wait(inf.axi_lite_rvalid)
            @(posedge inf.axi_lite_aclk);
            inf.axi_lite_rready     = 1'b0;
        end
    join

    read_data = inf.axi_lite_rdata;
    data = read_data;
    //--->> set idle <<--------
    inf.axi_lite_arvalid    = 1'b0;
    inf.axi_lite_araddr     = {ASIZE{1'b0}};
    inf.axi_lite_rready     = 1'b1;
    $display("Lite Read %h,result %h",addr,read_data);
endtask:read

task write(
    input [ASIZE-1:0]   addr ,
    input [DSIZE-1:0]   data
);
event   brs;
    wait(inf.axi_lite_resetn);
    @(posedge inf.axi_lite_aclk);

    inf.axi_lite_awvalid    = 1'b1;
    inf.axi_lite_awaddr     = addr;
    inf.axi_lite_wvalid     = 1'b1;
    inf.axi_lite_wdata      = data;
    inf.axi_lite_bready     = 1'd1;
    fork
        begin
            wait(inf.axi_lite_awready);
            @(posedge inf.axi_lite_aclk);
            inf.axi_lite_awvalid    = 1'b0;
        end
        begin
            wait(inf.axi_lite_wready);
            ->brs;
            @(posedge inf.axi_lite_aclk);
            inf.axi_lite_wvalid     = 1'b0;
        end
        begin
            wait(brs.triggered);
            wait(inf.axi_lite_bvalid);
            @(posedge inf.axi_lite_aclk);
            if(inf.axi_lite_bresp == 2'b10)begin
                $display("AXI WRITE SLAVE ERROR");
                $stop;
            end else if(inf.axi_lite_bresp == 2'b11)begin
                $display("AXI WRITE DECODE ERROR");
                $stop;
            end
        end
    join
    @(posedge inf.axi_lite_aclk);
    //--->>set idle <<------
    inf.axi_lite_bready     = 1'd1;
    inf.axi_lite_awvalid    = 1'b0;
    inf.axi_lite_awaddr     = {ASIZE{1'b0}};
    inf.axi_lite_wvalid     = 1'b0;
    inf.axi_lite_wdata      = {DSIZE{1'b0}};
endtask:write

endmodule
