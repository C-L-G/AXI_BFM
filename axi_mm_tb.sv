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

logic[31:0]     wdata [$]   = {0,1,2,3,4,5,100,101,901};

initial begin
    repeat(100) @(posedge sys_clk);
    axi_master_inst.initial_master_info(0);
    axi_slaver_inst.slaver_recieve_burst(3);
    repeat(3)
    axi_master_inst.burst_write(100,wdata,50);
end

endmodule
