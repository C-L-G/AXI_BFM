module axi_lite_tb;
bit sys_clk = 0;
bit sys_rstn = 1;

always #5 sys_clk = ~sys_clk;

axi_lite_inf lite_inf(sys_clk,sys_rstn);

axi_life_master #(
    .ASIZE      (9      ),
    .DSIZE      (32     )
)axi_life_master_inst(
    .inf (lite_inf)
);

initial begin
    repeat(100)
        @(posedge sys_clk);
    axi_life_master_inst.write(1,100);
end


endmodule
