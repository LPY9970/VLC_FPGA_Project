`timescale 1ns / 1ps
module vlc_rx_ctrl(
    input clk50,
    input reset,
    input rx_bit,
    input rx_bit_syncclk,
    input rx_bit_error,
    output reg data_valid,
    output tx_wr_en,
    output [7:0] tx_data,
    output reg LED3
);

reg rx_bit_sync_buf;
reg [7:0] rx_data_buf;
reg [2:0] vlc_rx_state;
parameter vr_idle=0, vr_synchead=1, vr_framehead=2, vr_data=4;

reg [2:0] rx_bit_cnt;
wire [7:0] datanum;
assign datanum = 8'd10;

reg [7:0] data_cnt;
reg data_rx_sync;
reg [7:0] data_rx;
reg [15:0] timeout_cnt;

assign tx_wr_en = data_rx_sync;
assign tx_data  = data_rx;

// rx_bit_syncclk 同步一拍，产生 rx_bit_sync_buf；
// rx_data_buf 在 rx_bit_syncclk 时移入 rx_bit。
always@(posedge clk50 or negedge reset)begin
    if(!reset)begin
        rx_data_buf     <= 8'd0;
        rx_bit_sync_buf <= 1'b0;
    end
    else begin
        rx_bit_sync_buf <= rx_bit_syncclk;
        if(rx_bit_syncclk)
            rx_data_buf <= {rx_bit, rx_data_buf[7:1]};
    end
end

always@(posedge clk50 or negedge reset)begin
    if(!reset)begin
        vlc_rx_state <= vr_idle;
        rx_bit_cnt   <= 3'd0;
        data_cnt     <= 8'd0;
        data_rx      <= 8'd0;
        data_rx_sync <= 1'b0;
        LED3         <= 1'b1;
        timeout_cnt  <= 16'd0;
        data_valid   <= 1'b0;
    end else begin
        case(vlc_rx_state)
        vr_idle: begin
            data_rx_sync <= 1'b0;
            timeout_cnt  <= 16'd0;
            rx_bit_cnt   <= 3'd0;
            if(rx_bit_sync_buf && rx_data_buf==8'ha6) begin
                vlc_rx_state <= vr_synchead;
                rx_bit_cnt   <= 3'd0;
            end
        end
        vr_synchead: begin
            if(rx_bit_sync_buf && rx_bit_cnt==3'd7)begin
                if(rx_data_buf==8'hce) vlc_rx_state <= vr_framehead;
                else                   vlc_rx_state <= vr_idle;
                rx_bit_cnt <= 3'd0;
            end else if(rx_bit_sync_buf) begin
                rx_bit_cnt <= rx_bit_cnt + 1'b1;
            end
        end
        vr_framehead: begin
            if(rx_bit_sync_buf && rx_bit_cnt==3'd7)begin
                if(rx_data_buf==8'hd5) vlc_rx_state <= vr_data;
                else                   vlc_rx_state <= vr_idle;
                rx_bit_cnt <= 3'd0;
            end else if(rx_bit_sync_buf) begin
                rx_bit_cnt <= rx_bit_cnt + 1'b1;
            end
        end
        vr_data: begin
            // 关键修改：统一使用 rx_bit_sync_buf 采样 rx_data_buf，
            // 此时 rx_data_buf 已经是本 bit 移入后的值。
            if(rx_bit_sync_buf)begin
                timeout_cnt <= 16'd0;
                if(rx_bit_cnt==3'd7)begin
                    data_rx      <= rx_data_buf;
                    data_rx_sync <= 1'b1;
                    rx_bit_cnt   <= 3'd0;
                    if(data_cnt==8'd9)begin
                        LED3         <= ~LED3;
                        vlc_rx_state <= vr_idle;
                        data_cnt     <= 8'd0;
                    end
                    else begin
                        data_cnt <= data_cnt + 1'b1;
                    end
                end else begin
                    rx_bit_cnt   <= rx_bit_cnt + 1'b1;
                    data_rx_sync <= 1'b0;
                end
            end else begin
                data_rx_sync <= 1'b0;
                // 超时保护：约 100us 无 syncclk 回 idle
                if(timeout_cnt >= 16'd5000)begin
                    timeout_cnt  <= 16'd0;
                    vlc_rx_state <= vr_idle;
                    data_cnt     <= 8'd0;
                    rx_bit_cnt   <= 3'd0;
                end else begin
                    timeout_cnt <= timeout_cnt + 1'b1;
                end
            end
        end
        default: vlc_rx_state <= vr_idle;
        endcase
    end
end

endmodule