`timescale 1ns/1ps
module axi_slaver #(
    parameter ASIZE = 32,
    parameter DSIZE = 64,
    parameter LSIZE = 8,
    parameter ID    = 0,
    parameter ADDR_STEP = 1
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
import StreamFilePkg::*;

semaphore   rev_seq;
SimpleRandom sr;
event       start_rev_event,data_rev_event,resp_trans_event;
event       enough_data_event;
int         enough_data_threshold = 1024;

logic[ASIZE-1:0]    rev_addr,trs_addr;
logic[DSIZE-1:0]    rev_data [bit[ASIZE-1:0]];
int                 rev_burst_len,trs_burst_len;
logic[1:0]          bresp_bits;

integer     wdata_array [DSIZE/32-1:0];
integer     rdata_array [DSIZE/32-1:0];

assign wdata_array = {>>{inf.axi_wdata}};
assign rdata_array = {>>{inf.axi_rdata}};

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
    @(posedge inf.axi_aclk);
    inf.axi_awready = 0;
    rev_info = "addr wr done";
    $display("AXI WRITE: ADDR=%h LENGTH=%d",rev_addr,rev_burst_len);
endtask:start_recieve_task

task automatic start_transmit_task;
    trs_info    = "start addr rd";
    inf.axi_rlast = 0;
    inf.axi_rvalid  = 0;
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
    trs_info = "addr rd done";
    $display("AXI READ: ADDR=%h  LENGTH=%d",trs_addr,trs_burst_len);
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
            rev_addr = rev_addr + ADDR_STEP;
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

int  tmp_cnt;
task automatic trans_data_task;
int data_cnt;
    trs_info = "data rd";
    data_cnt = 0;
    forever begin
        wait(inf.axi_rready);
        //--
        inf.axi_rid     = ID;
        inf.axi_rresp   = 2'b00;
        //--
        random_trs_data(0.7,data_cnt);
        tmp_cnt = data_cnt;
        if(data_cnt == trs_burst_len)begin
            inf.axi_rlast   = 1;
            @(posedge inf.axi_aclk);
            break;
        end
        @(posedge inf.axi_aclk);
    end
    inf.axi_rvalid  = 0;
    inf.axi_rlast   = 0;
    trs_info = "data rd done";
endtask:trans_data_task

task automatic random_trs_data(real prop,ref int cnt);
int     prop_key;
    prop_key = prop * 100;
    if(sr.get_rand(1) <= prop_key)begin
        inf.axi_rvalid  = 1;
        inf.axi_rdata   = rev_data[trs_addr];
        trs_addr = trs_addr + ADDR_STEP;
        cnt = cnt + 1;
    end else begin
        inf.axi_rvalid  = 0;
    end
endtask:random_trs_data


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
    if(enough_data_threshold <= rev_data.size)begin
        -> enough_data_event;
    end
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

task slaver_transmit_busrt(int num);
    fork
        repeat(num) begin
            start_transmit_task;
            trans_data_task;
        end
    join_none
endtask:slaver_transmit_busrt

//--->> save data to file <<--------
StreamFileClass sf;

task automatic save_cache_data(int split_bits=32);
longint data [];
logic[31:0] data_32 [];
logic[23:0] data_24 [];
logic[15:0] data_16 [];
logic[7:0]  data_8 [];
string  str;
int     index;
int     KK;
int     compact_index;
logic[DSIZE-1:0]    tmp_data;
    sf = new("slaver_cache_data.txt");
    sf.head_mark = "AXI slaver cache data";
    index = 0;
    foreach(rev_data[i])begin
        str = $sformatf(">>%d<< ADDR %h : ",index,i);
        index++;
        sf.str_write(str);
        case(split_bits)
        32:begin
            data_32 = {>>32{rev_data[i]}};
            data = new[data_32.size];
            foreach(data_32[j])
                data[j] = data_32[j];
            // sf.puts('{data});
        end
        24:begin
            compact_index = (i / ADDR_STEP) % 3;
            case(compact_index)
            0: tmp_data = rev_data[i];
            1: tmp_data = rev_data[i]<<8;
            2: tmp_data = rev_data[i]<<16;
            default:;
            endcase
            data_24 = {>>24{tmp_data[DSIZE-1-:((DSIZE/24)*24)],{tmp_data[0+:8],16'd0}}};
            data = new[data_24.size];
            foreach(data_24[j])
                data[j] = data_24[j];
        end
        16:begin
            data_16 = {>>16{rev_data[i]}};
            data = new[data_16.size];
            foreach(data_16[j])begin
                data[j] = data_16[j];
            end
        end
        8:begin
            data_8 = {>>8{rev_data[i]}};
            data = new[data_8.size];
            foreach(data_8[j])
                data[j] = data_8[j];
        end
        default:;
        endcase
        sf.puts(data);
    end
    sf.close_file;
endtask:save_cache_data

task automatic wait_rev_enough_data(int num);
    enough_data_threshold = num;
    wait(enough_data_event.triggered);
endtask:wait_rev_enough_data



endmodule
