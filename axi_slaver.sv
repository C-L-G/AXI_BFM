`timescale 1ns/1ps
module axi_slaver #(
    parameter ASIZE = 32,
    parameter DSIZE = 64,
    parameter LSIZE = 8,
    parameter ID    = 0
)(
    axi_inf.slaver inf
);

task automatic posedge_clk;
    @(posedge inf.axi_aclk);
    #0;
endtask:posedge_clk

string rev_info;
string trs_info;
import SimpleRandom::*;

semaphore   rev_seq;
SimpleRandom sr;
event       start_rev_event,data_rev_event,resp_trans_event;

logic[ASIZE-1:0]    rev_addr,trs_addr;
logic[DSIZE-1:0]    rev_data [bit[ASIZE-1:0]];
int                 rev_burst_len,trs_burst_len;
logic[1:0]          bresp_bits;

initial begin
    rev_seq = new(0);
    sr = new(0,100,99,2);
    // sr.randomize();
    inf.axi_awready = 0;
    inf.axi_bvalid  = 0;
    inf.axi_bid     = 0;
    inf.axi_bresp   = 2'b00;
    inf.axi_wready  = 0;
end

bit     rev_data_time;
task  random_wready_task;
bit rel;
    inf.axi_wready  = 0;
    fork
        forever begin:RAMNDOM_BLOCK
            posedge_clk;
            rel = sr.get_rand(0) % 2;
            if(rel)
                    inf.axi_wready  = 1;
            else    inf.axi_wready  = 0;
        end
        begin
            @(negedge inf.axi_wlast);
            inf.axi_wready  = 0;
        end
        begin
            @(posedge inf.axi_awvalid);
            assert(inf.axi_awvalid)
            else $warning("WRITE DATA FALSE");
        end
    join_any
    disable fork;
endtask:random_wready_task


task automatic start_recieve_task();
    // sr = new(0,100,3,4);
    // II = sr.randomize();
    rev_info = "start rev addr wr";
    while(1)begin
        @(posedge inf.axi_aclk);
        if(inf.axi_awvalid && (ID == inf.axi_awid))begin
            @(posedge inf.axi_aclk);
            break;
        end
    end
    inf.axi_awready = 1;
    rev_addr         = inf.axi_awaddr;
    rev_burst_len    = inf.axi_awlen+1;
    rev_data    = {};
    @(posedge inf.axi_aclk);
    inf.axi_awready = 0;
    rev_info = "addr wr done";
endtask:start_recieve_task

task automatic start_transmit_task;
    trs_info    = "start addr rd";
    while(1)begin
        @(posedge inf.axi_aclk);
        if(inf.axi_arvalid && (ID == inf.axi_arid))begin
            @(posedge inf.axi_aclk);
            break;
        end
    end
    inf.axi_arready = 1;
    trs_addr         = inf.axi_araddr;
    trs_burst_len    = inf.axi_arlen+1;
    @(posedge inf.axi_aclk);
    inf.axi_arready = 0;
    rev_info = "addr rd done";
endtask:start_transmit_task

task automatic rev_data_task();
int data_cnt;
    rev_info = "start rev data";
    data_cnt    = 0;
    forever begin
        @(negedge inf.axi_aclk);
        if(inf.axi_wvalid && inf.axi_wready)begin
            data_cnt++;
            rev_data[rev_addr]    = inf.axi_wdata;
            rev_addr++;
            if(inf.axi_wlast)begin
                bresp_bits  = 2'b00;
                assert(data_cnt == rev_burst_len)
                else begin
                    $warning("BURST REAL->%d EXPECT->%d LENGTH ERROR",data_cnt,rev_burst_len);
                    //$stop;
                    bresp_bits  = 2'b11;
                end
                break;
            end
        end
        @(posedge inf.axi_aclk);
    end
    @(posedge inf.axi_aclk);
    rev_info = "data wr done";
    repeat(10) @(posedge inf.axi_aclk);
endtask:rev_data_task

task automatic trans_data_task;
int data_cnt;
    trs_info = "data rd";
    data_cnt = 0;
    forever begin
        wait(inf.axi_rready);
        random_trs_data(data_cnt);
        if(data_cnt == trs_burst_len)begin
            inf.axi_rlast   = 1;
            break;
        end
        @(posedge inf.axi_aclk);
    end
    inf.axi_rlast   = 0;
    trs_info = "data rd done";
endtask:trans_data_task

task automatic random_trs_data(real prop,ref int cnt);
int     prop_key;
    prop_key = prop * 100;
    if(sr.get_rand(1) <= prop_key)begin         


task automatic trans_resp_task();
    rev_info = "resp wr";
    wait(inf.axi_bready);//@(posedge axi_aclk);
    inf.axi_bvalid  = 1'b1;
    inf.axi_bid     = ID;
    inf.axi_bresp   = bresp_bits;
    @(posedge inf.axi_aclk);
    inf.axi_bvalid  = 1'b0;
    inf.axi_bid     = ID;
    inf.axi_bresp   = 2'b00;
    rev_info = "resp wr done";
endtask:trans_resp_task

task  slaver_recieve_burst(int num);
    fork
        repeat(num) begin
            start_recieve_task;
            fork
                rev_data_task;
                random_wready_task;
            join
            trans_resp_task;
        end
    join_none
endtask:slaver_recieve_burst



endmodule
