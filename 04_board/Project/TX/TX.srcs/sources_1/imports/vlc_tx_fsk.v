`timescale 1ns / 1ps
module vlc_tx_fsk(
    input clk50,
    input reset,
    input vlc_wrsig,
    input [7:0] vlc_tx_data,
    output reg vlc_tx_finish,
    output reg vlc_data_latched,
    output reg VLC_TX_PIN
);

reg [7:0] clk_cnt;
reg [2:0] bit_cnt;
reg [7:0] vlc_tx_data_buf;

parameter dummy_data   = 8'h55;
parameter ONE_CNT      = 8'd49;
parameter HALFONE_CNT  = 8'd24;
parameter ZERO_CNT     = 8'd24;
parameter HALFZERO_CNT = 8'd12;

always @(posedge clk50 or negedge reset) begin
    if(!reset) clk_cnt <= 8'd0;
    else if(clk_cnt==ONE_CNT) clk_cnt <= 8'd0;
    else clk_cnt <= clk_cnt + 1'b1;
end

always @(posedge clk50 or negedge reset) begin
    if(!reset) bit_cnt <= 3'd0;
    else if(clk_cnt==ONE_CNT)begin
        if(bit_cnt==3'd7) bit_cnt <= 3'd0;
        else bit_cnt <= bit_cnt + 1'b1;
    end
end

always @(posedge clk50 or negedge reset) begin
    if(!reset) vlc_tx_data_buf <= dummy_data;
    else if((bit_cnt==3'd7)&&(clk_cnt==ONE_CNT))begin
        if(vlc_wrsig) vlc_tx_data_buf <= vlc_tx_data;
        else          vlc_tx_data_buf <= dummy_data;
    end
end

// 锁存完成脉冲，供 vlc_tx_ctrl 清 vlc_wrsig
always @(posedge clk50 or negedge reset) begin
    if(!reset) vlc_data_latched <= 1'b0;
    else if((bit_cnt==3'd7)&&(clk_cnt==ONE_CNT)) vlc_data_latched <= 1'b1;
    else vlc_data_latched <= 1'b0;
end

always @(posedge clk50 or negedge reset) begin
    if(!reset) vlc_tx_finish <= 1'b0;
    else if((bit_cnt==3'd7)&&(clk_cnt==ONE_CNT-3)) vlc_tx_finish <= 1'b1;
    else vlc_tx_finish <= 1'b0;
end

// bit=0：clk_cnt 12~24 高脉冲，约 12 拍
// bit=1：clk_cnt 24~49 高脉冲，约 25 拍
always @(posedge clk50 or negedge reset) begin
    if(!reset) VLC_TX_PIN <= 1'b0;
    else begin
        if(clk_cnt==ONE_CNT)
            VLC_TX_PIN <= 1'b0;
        else if(clk_cnt==HALFONE_CNT)begin
            if(vlc_tx_data_buf[bit_cnt]==1'b1) VLC_TX_PIN <= 1'b1;
            else                               VLC_TX_PIN <= 1'b0;
        end
        else if(clk_cnt==HALFZERO_CNT)begin
            if(vlc_tx_data_buf[bit_cnt]==1'b1) VLC_TX_PIN <= 1'b0;
            else                               VLC_TX_PIN <= 1'b1;
        end
        // 删除原来的 HALFZERO_CNT+HALFONE_CNT+1 补脉冲
    end
end

endmodule