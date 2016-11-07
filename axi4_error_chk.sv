/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/3 下午4:44:59
madified:
***********************************************/
`timescale 1ns/1ps
module axi4_error_chk #(
    parameter   DELAY = 24'hFFF_000
)(
    axi_inf.mirror inf
);

typedef enum {WIDLE,WS_CMD,WW_DATA,WB_RESP,W_ERROR,W_JUDGE} W_STATUS;
W_STATUS wcstate,wnstate;

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wcstate <= WIDLE;
    else    wcstate <= wnstate;

logic       wtimeout,wrong_wnum;
always@(*)
    case(wcstate)
    WIDLE:
        if(inf.axi_awvalid && inf.axi_awready)
                wnstate = WS_CMD;
        else    wnstate = WIDLE;
    WS_CMD:
        if(wtimeout)
                wnstate = W_ERROR;
        else if(inf.axi_awvalid && inf.axi_awready)
                wnstate = W_ERROR;
        else if(inf.axi_wvalid)begin
            if(inf.axi_wready && inf.axi_wlast)
                    wnstate = WB_RESP;
            else    wnstate = WW_DATA;
        end else
                wnstate = WS_CMD;
    WW_DATA:
        if(wtimeout)
                wnstate = W_ERROR;
        else if(inf.axi_wlast && inf.axi_wready && inf.axi_wvalid)
                wnstate = WB_RESP;
        else    wnstate = WW_DATA;
    WB_RESP:
        if(wtimeout || wrong_wnum)
                wnstate = W_ERROR;
        else if(inf.axi_bready && inf.axi_bvalid)
                wnstate = WIDLE;
        else    wnstate = WB_RESP;
    W_JUDGE:    wnstate = WIDLE;
    default:    wnstate = WIDLE;
    endcase

// logic       enable_wcnt;
//
// always@(posedge inf.axi_aclk)
//     if(~inf.axi_resetn)
//             enable_wcnt <= 1'b0;
//     else
//         case(wnstate)
//         WIDLE:   enable_wcnt <= 1'b0;
//         default:enable_wcnt <= 1'b1;
//         endcase
//--->> write timeout <<---------------
logic [23:0]        wdcnt;
// logic               wtimeout
always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wdcnt    <= 24'd0;
    else
        case(wnstate)
        WIDLE:  wdcnt    <= 24'd0;
        default:begin
            if(inf.axi_wvalid && inf.axi_wready)
                    wdcnt   <= wdcnt;
            else    wdcnt   <= wdcnt + 1'b1;
        end
        endcase

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wtimeout    <= 1'b0;
    else
        case(wnstate)
        WIDLE:
            wtimeout    <= 1'b0;
        default:begin
            if(wdcnt > DELAY)
                    wtimeout    <= 1'b1;
            else    wtimeout    <= 1'b0;
        end
        endcase
//---<< write timeout >>---------------
//---<< write chk >>---------------
always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            inf.axi_weresp  <= 4'd0;
    else begin
        case(wnstate)
        WS_CMD:     inf.axi_weresp  <= 4'd1;
        WW_DATA:    inf.axi_weresp  <= 4'd2;
        WB_RESP,W_ERROR:begin
            if(wtimeout)
                    inf.axi_weresp  <= 4'd3;
            else    inf.axi_weresp  <= 4'd4;
        end
        default:;
        endcase
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            inf.axi_wevld   <= 1'b0;
    else
        case(wnstate)
        W_ERROR:
            inf.axi_wevld   <= 1'b1;
        default:
            inf.axi_wevld   <= 1'b0;
        endcase
//---<< write chk >>---------------
//--->> WRITE DATA CNT <<----------
logic [9:0]         wcnt;
// logic               wrong_wnum;
logic [9:0]         wr_need;

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wr_need <= 10'd0;
    else begin
        if(inf.axi_awvalid && inf.axi_awready)
                wr_need <= inf.axi_awlen;
        else    wr_need <= wr_need;
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wcnt    <= 10'd0;
    else begin
        if(inf.axi_awvalid && inf.axi_awready)
            wcnt    <= 10'd0;
        else if(inf.axi_wvalid && inf.axi_wready)
            wcnt    <= wcnt + 1'b1;
        else
            wcnt    <= wcnt;
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wrong_wnum  <= 1'b0;
    else begin
        if(inf.axi_awvalid && inf.axi_awready)
                wrong_wnum  <= 1'b0;
        else if(inf.axi_wvalid && inf.axi_wready && inf.axi_wlast)
                wrong_wnum  <= wcnt != wr_need;
        else    wrong_wnum  <= wrong_wnum;
    end
//---<< WRITE DATA CNT >>----------

typedef enum {RIDLE,RS_CMD,RR_DATA,R_LAST,R_ERROR} R_STATUS;
R_STATUS rcstate,rnstate;

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            rcstate = RIDLE;
    else    rcstate = rnstate;

logic   rtimeout,wrong_rnum;

always@(*)
    case(rcstate)
    RIDLE:
        if(inf.axi_arvalid && inf.axi_arready)
                rnstate = RS_CMD;
        else    rnstate = RIDLE;
    RS_CMD:
        if(rtimeout)
                rnstate = R_ERROR;
        else if(inf.axi_arvalid && inf.axi_arready)
                rnstate = R_ERROR;
        else if(inf.axi_rvalid)begin
            if(inf.axi_rready && inf.axi_rlast)
                    rnstate = R_LAST;
            else    rnstate = RR_DATA;
        end else    rnstate = RS_CMD;
    RR_DATA:
        if(rtimeout)
                rnstate = R_ERROR;
        else if(inf.axi_rready && inf.axi_rlast && inf.axi_rvalid)
                rnstate = R_LAST;
        else    rnstate = RR_DATA;
    R_LAST:
        if(wrong_rnum)
                rnstate = R_ERROR;
        else    rnstate = RIDLE;
    default:    rnstate = RIDLE;
    endcase

//--->> read timeout <<---------------
logic [23:0]        rdcnt;
// logic               wtimeout
always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            rdcnt    <= 24'd0;
    else
        case(rnstate)
        RIDLE:  rdcnt    <= 24'd0;
        default:begin
            if(inf.axi_rvalid && inf.axi_rready)
                    rdcnt   <= rdcnt;
            else    rdcnt   <= rdcnt + 1'b1;
        end
        endcase

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            rtimeout    <= 1'b0;
    else
        case(rnstate)
        RIDLE,R_ERROR:
            rtimeout    <= 1'b0;
        default:begin
            if(rdcnt > DELAY)
                    rtimeout    <= 1'b1;
            else    rtimeout    <= 1'b0;
        end
        endcase
//---<< read timeout >>---------------
//--->> READ DATA CNT <<----------
logic [9:0]         rcnt;
// logic               wrong_rnum;
logic [9:0]         rd_need;

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            rd_need <= 10'd0;
    else begin
        if(inf.axi_arvalid && inf.axi_arready)
                rd_need <= inf.axi_arlen;
        else    rd_need <= rd_need;
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            rcnt    <= 10'd0;
    else begin
        if(inf.axi_arvalid && inf.axi_arready)
            rcnt    <= 10'd0;
        else if(inf.axi_rvalid && inf.axi_rready)
            rcnt    <= rcnt + 1'b1;
        else
            rcnt    <= rcnt;
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            wrong_rnum  <= 1'b0;
    else begin
        if(inf.axi_rvalid && inf.axi_rready && inf.axi_rlast)
                wrong_rnum  <= rcnt != rd_need;
        else    wrong_rnum  <= 1'b0;
    end
//---<< READ DATA CNT >>----------
//---<< read chk >>---------------
always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            inf.axi_reresp  <= 4'd0;
    else begin
        case(rnstate)
        RS_CMD:     inf.axi_reresp  <= 4'd1;
        RR_DATA:    inf.axi_reresp  <= 4'd2;
        R_LAST:begin
            if(rtimeout)
                    inf.axi_reresp  <= 4'd3;
            else    inf.axi_reresp  <= 4'd4;
        end
        default:;
        endcase
    end

always@(posedge inf.axi_aclk)
    if(~inf.axi_resetn)
            inf.axi_revld   <= 1'b0;
    else
        case(rnstate)
        R_ERROR:
            inf.axi_revld   <= 1'b1;
        default:
            inf.axi_revld   <= 1'b0;
        endcase
//---<< read chk >>---------------
endmodule
