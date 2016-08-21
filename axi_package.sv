/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/8/21 上午10:28:01
madified:
***********************************************/
package AXI_PKG;

string rev_info;
string trs_info;
import SimpleRandom::*;
import StreamFilePkg::*;

semaphore   rev_seq;
SimpleRandom sr;
event       enough_data_event;
int         enough_data_threshold = 1024;

logic[ASIZE-1:0]    rev_addr,trs_addr;
logic[DSIZE-1:0]    rev_data [bit[ASIZE-1:0]];
int                 rev_burst_len,trs_burst_len;
logic[1:0]          bresp_bits;

axi_slaver #(
    .ASIZE  (32         ),
    .DSIZE  (32         ),
    .LSIZE  (8          ),
    .ID     (0          )
)axi_slaver_inst(
    .inf        (axi_mm_inf)
);
