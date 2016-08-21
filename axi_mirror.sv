/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/8/21 上午7:52:06
madified:
***********************************************/
`timescale 1ns / 1ps
module axi_mirror #(
    parameter ASIZE = 32,
    parameter DSIZE = 64,
    parameter LSIZE = 8,
    parameter ID    = 0,
    parameter ADDR_STEP = 1
)(
    axi_inf.mirror inf
);

string rev_info;
string trs_info;

event       enough_data_event,enough_trs_data_event;
int         enough_data_threshold = 1024;

logic[ASIZE-1:0]    rev_addr,trs_addr;
logic[DSIZE-1:0]    rev_data [bit[ASIZE-1:0]];
logic[DSIZE-1:0]    trs_data [bit[ASIZE-1:0]];
int                 rev_burst_len,trs_burst_len;

integer     wdata_array [DSIZE/32-1:0];
integer     rdata_array [DSIZE/32-1:0];

assign wdata_array = {>>{inf.axi_wdata}};
assign rdata_array = {>>{inf.axi_rdata}};

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
    rev_addr         = inf.axi_awaddr;
    rev_burst_len    = inf.axi_awlen+1;
    @(posedge inf.axi_aclk);
    rev_info = "addr wr done";
    $display("AXI WRITE: ADDR=%h LENGTH=%d",rev_addr,rev_burst_len);
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
    trs_addr         = inf.axi_araddr;
    trs_burst_len    = inf.axi_arlen+1;
    @(posedge inf.axi_aclk);
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
            if(enough_data_threshold <= rev_data.size)begin
                -> enough_data_event;
            end
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
        @(negedge inf.axi_aclk);
        if(inf.axi_rvalid && inf.axi_rready)begin
            data_cnt++;
            trs_data[trs_addr]    = inf.axi_rdata;
            trs_addr = trs_addr + ADDR_STEP;
            if(enough_data_threshold <= trs_data.size)begin
                -> enough_trs_data_event;
            end
            if(inf.axi_rlast)begin
                assert(data_cnt == trs_burst_len)
                else begin
                    $warning("BURST REAL->%d EXPECT->%d LENGTH ERROR",data_cnt,rev_burst_len);
                    //$stop;
                end
                break;
            end
        end
        @(posedge inf.axi_aclk);
    end
    trs_info = "data rd done";
endtask:trans_data_task

task automatic trans_resp_task();
    rev_info = "resp wr";
    wait(inf.axi_bready);//@(posedge axi_aclk);
    @(posedge inf.axi_aclk);
    rev_info = "resp wr done";
endtask:trans_resp_task

task  slaver_recieve_burst(int num);
    fork
        repeat(num) begin
            start_recieve_task;
            fork
                rev_data_task;
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

task automatic save_cache_data(string filename,ref logic[DSIZE-1:0]  rev_data [bit[ASIZE-1:0]],int split_bits=32);
longint data [];
logic[31:0] data_32 [];
logic[23:0] data_24 [];
logic[15:0] data_16 [];
logic[7:0]  data_8 [];
string  str;
int     index;
int     KK;
int     compact_index;
int     start_index,end_index;
logic[DSIZE-1:0]    tmp_data;
    sf = new(filename);
    sf.head_mark = "AXI slaver cache data";
    index = 0;
    foreach(rev_data[i])begin
        start_index = index*(DSIZE/split_bits + (DSIZE%split_bits!=0? 1 : 0));
        end_index   = start_index+(DSIZE/split_bits + (DSIZE%split_bits!=0? 1 : 0))-1;
        str = $sformatf(">>%d->%d<< ADDR %h : ",start_index,end_index,i);
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

task automatic save_rev_cache_data(int split_bits=32);
    save_cache_data("mirror_rev_data.txt",rev_data,split_bits);
endtask:save_rev_cache_data

task automatic save_trs_cache_data(int split_bits=32);
    save_cache_data("mirror_trs_data.txt",rev_data,split_bits);
endtask:save_trs_cache_data

task automatic wait_rev_enough_data(int num);
    enough_data_threshold = num;
    wait(enough_data_event.triggered);
endtask:wait_rev_enough_data

endmodule
