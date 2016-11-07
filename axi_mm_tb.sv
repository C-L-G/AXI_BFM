/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/8/11 上午9:47:04
madified:
***********************************************/
`timescale 1ns/1ps
module axi_mm_tb;
bit sys_clk = 0;
bit sys_rstn = 1;

always #5 sys_clk = ~sys_clk;

axi_inf axi_mm_inf(sys_clk,sys_rstn);

axi_master #(
    .ASIZE  (32         ),
    .DSIZE  (32         ),
    .LSIZE  (8          )
)axi_master_inst(
    .inf        (axi_mm_inf)
);

axi_slaver #(
    .ASIZE  (32         ),
    .DSIZE  (32         ),
    .LSIZE  (8          ),
    .ID     (0          )
)axi_slaver_inst(
    .inf        (axi_mm_inf)
);

axi4_error_chk #(
    .DELAY      (100)
)axi4_error_chk_inst(
    .inf        (axi_mm_inf)
);

logic[31:0]     wdata [$]   = {0,1,2,3,4,5,100,101,901};

initial begin
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_recieve_burst(3);
    repeat(3)
    axi_master_inst.burst_write(100,wdata,50);
end

// initial begin
//     // wr_busrt_err_no_data;
//     rd_busrt_err_long_data;
// end

task wr_busrt_err_no_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_recieve_burst(1);
    axi_master_inst.write_addr(1,10);
endtask

task wr_busrt_err_short_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_recieve_burst(1);
    axi_master_inst.write_addr(0,10);
    axi_master_inst.write_data(5,wdata);
    axi_master_inst.assert_resp;
endtask

task wr_busrt_err_long_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_recieve_burst(1);
    axi_master_inst.write_addr(0,10);
    axi_master_inst.write_data(20,wdata);
    axi_master_inst.assert_resp;
endtask

task wr_busrt_err_no_resp;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    // axi_slaver_inst.slaver_recieve_burst(1);
    fork
        begin
            axi_master_inst.write_addr(0,10);
            axi_master_inst.write_data(10,wdata);
            axi_master_inst.assert_resp;
        end
        begin
            axi_slaver_inst.start_recieve_task;
            fork
                axi_slaver_inst.rev_data_task;
                axi_slaver_inst.random_wready_task;
            join
        end
    join
endtask

task rd_busrt_err_no_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_transmit_busrt(1);
    axi_master_inst.read_addr(1,10);
endtask

task rd_busrt_err_short_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    fork
        axi_master_inst.burst_read(0,wdata,10);
        begin
            axi_slaver_inst.start_transmit_task;
            axi_slaver_inst.trans_data_task(5);
        end
    join
endtask

task rd_busrt_err_long_data;
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    fork
        axi_master_inst.burst_read(0,wdata,100);
        begin
            axi_slaver_inst.start_transmit_task;
            axi_slaver_inst.trans_data_task(120);
        end
    join
endtask

endmodule
