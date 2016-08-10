module axi_slaver #(
    parameter ASIZE = 32,
    parameter DSIZE = 64,
    parameter LSIZE = 8,
    parameter ID    = 0
)(
    axi_inf.slaver inf
);
import SimpleRandom::*;

semaphore rev_seq;
event       start_rev_event,data_rev_event,resp_trans_event;

logic[ASIZE-1:0]    address;
logic[DSIZE-1:0]    rev_data [$];
int                 burst_lenght;
logic[1:0]          bresp_bits;

initial begin
    rev_seq = new(0);
end

automatic task start_recieve_task ;
integer II;
    // sr = new(0,100,3,4);
    // II = sr.randomize();
    while(1)begin
        @(posedge inf.axi_aclk);
        if(inf.axi_awvalid && (ID == inf.axi_awid))begin
            @(posedge inf.axi_aclk);
            break;
        end
    end
    inf.axi_awready = 1;@(posedge inf.axi_aclk);
    address = inf.axi_awaddr;
    burst_lenght     = inf.axi_awlen;
    rev_data    = {};
    -> start_rev_event;
endtask:start_recieve_task

automatic task rev_data_task;
int data_cnt = 0;
    wait(start_rev_event.triggered())
    while(1)begin
        @(posedge inf.axi_aclk);
        if(inf.axi_wvalid && inf.axi_wready)begin
            data_cnt++;
            rev_data    << inf.axi_wdata;
            address++;

            if(inf.axi_wlast)begin
                if(data_cnt == burst_lenght)begin
                    $warning("BURST LENGTH ERROR");
                    //$stop;
                    bresp_bits  = 2'b00;
                end else begin
                    bresp_bits  = 2'b11;
                end
            end
        end
    end
    -> data_rev_event;
endtask:rev_data_task

automatic task trans_resp_task;
    wait(data_rev_event.triggered());
    wait(inf.axi_bready);//@(posedge axi_aclk);
    inf.axi_bvalid  = 1'b1;
    inf.axi_bid     = ID;
    inf.axi_bresp   = bresp_bits;
    @(posedge axi_aclk);
    inf.axi_bvalid  = 1'b0;
    inf.axi_bid     = ID;
    inf.axi_bresp   = 2'b00;
endtask:trans_resp_task
