interface axi_lite_inf #(
    parameter ASIZE = 32,
    parameter DSIZE = 32
)(input bit axi_lite_aclk,input bit axi_lite_resetn);
logic               axi_lite_awvalid    ;
logic               axi_lite_awready    ;
logic[ASIZE-1:0]    axi_lite_awaddr     ;
logic               axi_lite_wvalid     ;
logic               axi_lite_wready     ;
logic[DSIZE-1:0]    axi_lite_wdata      ;
logic [1:0]         axi_lite_bresp      ;
logic               axi_lite_bvalid     ;
logic               axi_lite_bready     ;
logic               axi_lite_arvalid    ;
logic               axi_lite_arready    ;
logic[ASIZE-1:0]    axi_lite_araddr     ;
logic               axi_lite_rvalid     ;
logic               axi_lite_rready     ;
logic [DSIZE-1:0]   axi_lite_rdata      ;
logic [1:0]         axi_lite_rresp      ;


modport master(
input                axi_lite_aclk       ,
input                axi_lite_resetn     ,
output               axi_lite_awvalid    ,
input                axi_lite_awready    ,
output               axi_lite_awaddr     ,
output               axi_lite_wvalid     ,
input                axi_lite_wready     ,
output               axi_lite_wdata      ,
input                axi_lite_bresp      ,
input                axi_lite_bvalid     ,
output               axi_lite_bready     ,
output               axi_lite_arvalid    ,
input                axi_lite_arready    ,
output               axi_lite_araddr     ,
input                axi_lite_rvalid     ,
output               axi_lite_rready     ,
input                axi_lite_rdata      ,
input                axi_lite_rresp
);


modport slaver(
input               axi_lite_awvalid    ,
output              axi_lite_awready    ,
input               axi_lite_awaddr     ,
input               axi_lite_wvalid     ,
output              axi_lite_wready     ,
input               axi_lite_wdata      ,
output              axi_lite_bresp      ,
output              axi_lite_bvalid     ,
input               axi_lite_bready     ,
input               axi_lite_arvalid    ,
output              axi_lite_arready    ,
input               axi_lite_araddr     ,
output              axi_lite_rvalid     ,
input               axi_lite_rready     ,
output              axi_lite_rdata      ,
output              axi_lite_rresp
);

endinterface

interface axi_inf #(
    parameter IDSIZE    = 4,
    parameter ASIZE     = 32,
    parameter LSIZE     = 8,
    parameter DSIZE     = 32
)(
    input bit axi_aclk      ,
    input bit axi_resetn
);

parameter STSIZE = DSIZE/8+(DSIZE%8 != 0);
//--->> addr write <<-------
logic[IDSIZE-1:0] axi_awid      ;
logic[ASIZE-1:0]  axi_awaddr    ;
logic[LSIZE-1:0]  axi_awlen     ;
logic[2:0]        axi_awsize    ;
logic[1:0]        axi_awburst   ;
logic[0:0]        axi_awlock    ;
logic[3:0]        axi_awcache   ;
logic[2:0]        axi_awprot    ;
logic[3:0]        axi_awqos     ;
logic             axi_awvalid   ;
logic             axi_awready   ;
//---<< addr write >>-------
//--->> addr read <<--------
logic[IDSIZE-1:0] axi_arid        ;
logic[ASIZE-1:0]  axi_araddr      ;
logic[LSIZE-1:0]  axi_arlen       ;
logic[2:0]        axi_arsize      ;
logic[1:0]        axi_arburst     ;
logic[0:0]        axi_arlock      ;
logic[3:0]        axi_arcache     ;
logic[2:0]        axi_arprot      ;
logic[3:0]        axi_arqos       ;
logic             axi_arvalid     ;
logic             axi_arready     ;
//---<< addr read >>--------
//--->> Response <<---------
logic             axi_bready    ;
logic[IDSIZE-1:0] axi_bid       ;
logic[1:0]        axi_bresp     ;
logic             axi_bvalid    ;
//---<< Response >>---------
//--->> data write <<-------
logic[DSIZE-1:0]  axi_wdata     ;
logic[STSIZE-1:0] axi_wstrb     ;
logic             axi_wlast     ;
logic             axi_wvalid    ;
logic             axi_wready    ;
//---<< data write >>-------
//--->> data read >>--------
logic             axi_rready    ;
logic[IDSIZE-1:0] axi_rid       ;
logic[DSIZE-1:0]  axi_rdata     ;
logic[1:0]        axi_rresp     ;
logic             axi_rlast     ;
logic             axi_rvalid    ;
//---<< data read >>--------

modport slaver (
input    axi_aclk     ,
input    axi_resetn   ,
input    axi_awid     ,
input    axi_awaddr   ,
input    axi_awlen    ,
input    axi_awsize   ,
input    axi_awburst  ,
input    axi_awlock   ,
input    axi_awcache  ,
input    axi_awprot   ,
input    axi_awqos    ,
input    axi_awvalid  ,
output   axi_awready  ,
input    axi_wdata    ,
input    axi_wstrb    ,
input    axi_wlast    ,
input    axi_wvalid   ,
output   axi_wready   ,
input    axi_bready   ,
output   axi_bid      ,
output   axi_bresp    ,
output   axi_bvalid   ,
input    axi_arid     ,
input    axi_araddr   ,
input    axi_arlen    ,
input    axi_arsize   ,
input    axi_arburst  ,
input    axi_arlock   ,
input    axi_arcache  ,
input    axi_arprot   ,
input    axi_arqos    ,
input    axi_arvalid  ,
output   axi_arready  ,
input    axi_rready   ,
output   axi_rid      ,
output   axi_rdata    ,
output   axi_rresp    ,
output   axi_rlast    ,
output   axi_rvalid
);

modport master (
input     axi_aclk     ,
input     axi_resetn   ,
output    axi_awid     ,
output    axi_awaddr   ,
output    axi_awlen    ,
output    axi_awsize   ,
output    axi_awburst  ,
output    axi_awlock   ,
output    axi_awcache  ,
output    axi_awprot   ,
output    axi_awqos    ,
output    axi_awvalid  ,
input     axi_awready  ,
output    axi_wdata    ,
output    axi_wstrb    ,
output    axi_wlast    ,
output    axi_wvalid   ,
input     axi_wready   ,
output    axi_bready   ,
input     axi_bid      ,
input     axi_bresp    ,
input     axi_bvalid   ,
output    axi_arid     ,
output    axi_araddr   ,
output    axi_arlen    ,
output    axi_arsize   ,
output    axi_arburst  ,
output    axi_arlock   ,
output    axi_arcache  ,
output    axi_arprot   ,
output    axi_arqos    ,
output    axi_arvalid  ,
input     axi_arready  ,
output    axi_rready   ,
input     axi_rid      ,
input     axi_rdata    ,
input     axi_rresp    ,
input     axi_rlast    ,
input     axi_rvalid
);

endinterface:axi_inf
