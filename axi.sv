module axi_master #(
    parameter ASIZE = 32,
    parameter DSIZE = 64,
    parameter LSIZE = 8
)(
    axi_inf.master inf
);

function void  initial_master_info(
    input int  id
);
    inf.axi_awid = id ;
    inf.axi_arid = id ;
endfunction:initial_master_info

task reset_status;
    inf.axi_awid     = 0;
    inf.axi_awaddr   = 0;
    inf.axi_awlen    = 0;
    inf.axi_awsize   = 0;
    inf.axi_awburst  = 0;
    inf.axi_awlock   = 0;
    inf.axi_awcache  = 0;
    inf.axi_awprot   = 0;
    inf.axi_awqos    = 0;
    inf.axi_awvalid  = 0;

    inf.axi_wdata    = 0;
    inf.axi_wstrb    = 0;
    inf.axi_wlast    = 0;
    inf.axi_wvalid   = 0;

    inf.axi_bready   = 0;

    inf.axi_arid     = 0;
    inf.axi_araddr   = 0;
    inf.axi_arlen    = 0;
    inf.axi_arsize   = 0;
    inf.axi_arburst  = 0;
    inf.axi_arlock   = 0;
    inf.axi_arcache  = 0;
    inf.axi_arprot   = 0;
    inf.axi_arqos    = 0;
    inf.axi_arvalid  = 0;
    inf.axi_rready   = 0;
endtask:reset_status

task assert_resp;
    @(posedge inf.axi_aclk);
    inf.axi_bready  = 1;
    wait(inf.axi_bvalid);@(posedge inf.axi_aclk);
    assert(inf.axi_bresp == 2'b00)
    else $warning("AXI RESPONSE ERROR");
    reset_status;
endtask:assert_resp

task write_addr(
    input [ASIZE-1:0]   addr,
    input int           length,
    input [1:0]         burst_type
);
event get_resp;
    wait(inf.axi_resetn);
    @(posedge inf.axi_aclk);

    inf.axi_awaddr  = addr;
    if(length != 0)
        inf.axi_awlen   = length-1;
    inf.axi_awburst = burst_type;
    inf.axi_awsize  = 5;
    @(posedge inf.axi_aclk);
    inf.axi_awvalid = 1'b1;
    @(negedge  inf.axi_aclk);
    fork
        begin
            wait(inf.axi_awready);@(posedge inf.axi_aclk);
            inf.axi_awvalid = 1'b0;
        end
    join
    reset_status;
endtask:write_addr

task automatic write_data(
    input int length,
    ref logic[DSIZE-1:0] data [$]
);
int     kk;
int     dlen;
    wait(inf.axi_resetn);
    @(posedge inf.axi_aclk);
    dlen = data.size();
    inf.axi_wstrb   = {(DSIZE/8){1'b1}};
    for(kk=1;kk<=length;kk++)begin
        inf.axi_wvalid  = 1'b1;
        if(kk<=dlen)
            inf.axi_wdata   = data[kk-1];
        else
            inf.axi_wdata   = data[kk%dlen];

        if(kk==length)
            inf.axi_wlast   = 1'b1;
        @(negedge inf.axi_aclk);wait(inf.axi_wready);@(posedge inf.axi_aclk);
    end
    reset_status;
endtask:write_data

task read_addr(
    input [ASIZE-1:0]   addr,
    input int           length,
    input [1:0]         burst_type
);
    wait(inf.axi_resetn);
    @(posedge inf.axi_aclk);

    inf.axi_araddr  = addr;
    if(length != 0)
            inf.axi_arlen   = length-1;
    else    inf.axi_arlen   = 0;
    inf.axi_arburst = burst_type;
    inf.axi_arvalid = 1'b1;
    fork
        begin
            wait(inf.axi_arready);@(posedge inf.axi_aclk);
            inf.axi_arvalid = 1'b0;
        end
        // begin
        //     wait(get_resp.triggered());
        //     wait(inf.axi_bvalid);@(posedge inf.axi_aclk);
        //     inf.axi_bready  = 1'b0;
        // end
    join
    reset_status;
endtask:read_addr

task automatic read_data(
    ref logic [DSIZE-1:0]   data [$]
);
int     kk = 0;
    wait(inf.axi_resetn);
    @(posedge inf.axi_aclk);

    inf.axi_rready  = 1'b1;
    while(1)begin
        wait(inf.axi_rvalid);@(posedge inf.axi_aclk);
        data[kk]    = inf.axi_rdata;
        kk++;
        if(inf.axi_rlast)begin
            break;
        end
    end
    reset_status;
endtask:read_data


task automatic burst_write(
    input [ASIZE-1:0]       addr,
    ref logic [DSIZE-1:0]   data[$],
    input int               length = 0
);
int     dlen;
    if(length == 0)
            dlen = data.size();
    else    dlen = length;
    write_addr(addr,dlen,2'b01);
    write_data(dlen,data);
    assert_resp;
endtask:burst_write

task automatic burst_read(
    input [ASIZE-1:0]   addr,
    ref logic[DSIZE-1:0]data[$],
    input int           length = 0
);
    read_addr(addr,length,2'b01);
    read_data(data);
endtask:burst_read



initial begin
    reset_status;
end

endmodule
