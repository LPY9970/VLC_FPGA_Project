`timescale 1ns / 1ps
module vlc_rx_fsk(
    input  wire clk50,
    input  wire reset,
    input  wire VLC_RX_PIN,
    input  wire rx_sync_retry,
    output reg  rx_bit,
    output reg  rx_bit_syncclk,
    output reg  rx_bit_error
);

    // bit=0 高脉冲约 12 拍，bit=1 高脉冲约 25 拍
    parameter GLITCH_CNT  = 7'd4;   // 小于 12
    parameter ONE_THRESH  = 7'd18;  // 介于 12 和 25 之间
    parameter DEAD_CNT    = 6'd8;   // 单脉冲方案：必须小于 1->0 的最小低电平间隔

    reg [2:0] sig_sync;
    always @(posedge clk50 or negedge reset) begin
        if (!reset) sig_sync <= 3'b000;
        else        sig_sync <= {sig_sync[1:0], VLC_RX_PIN};
    end
    wire sig = sig_sync[2];

    reg sig_d;
    always @(posedge clk50 or negedge reset) begin
        if (!reset) sig_d <= 1'b0;
        else        sig_d <= sig;
    end
    wire L2H_sig = sig & ~sig_d;
    wire H2L_sig = ~sig & sig_d;

    reg [1:0] rx_arbit_state;
    reg [6:0] rx_high_cnt;
    reg [5:0] dead_cnt;

    always @(negedge clk50 or negedge reset) begin
        if (!reset) begin
            rx_arbit_state <= 2'd0;
            rx_high_cnt    <= 7'd0;
            rx_bit         <= 1'b0;
            rx_bit_syncclk <= 1'b0;
            rx_bit_error   <= 1'b0;
            dead_cnt       <= 6'd0;
        end else begin
            case (rx_arbit_state)
            0: begin
                rx_high_cnt    <= 7'd0;
                rx_bit_syncclk <= 1'b0;
                rx_arbit_state <= 2'd1;
            end
            1: begin
                if (L2H_sig) begin
                    rx_arbit_state <= 2'd2;
                    rx_high_cnt    <= 7'd1;
                end
            end
            2: begin
                if (H2L_sig) begin
                    if (rx_high_cnt > GLITCH_CNT) begin
                        rx_bit_syncclk <= 1'b1;
                        rx_bit_error   <= 1'b0;
                        if (rx_high_cnt > ONE_THRESH)
                            rx_bit <= 1'b1;
                        else
                            rx_bit <= 1'b0;
                        rx_arbit_state <= 2'd3;
                        dead_cnt       <= DEAD_CNT;
                    end else begin
                        rx_arbit_state <= 2'd0;
                    end
                end else begin
                    rx_high_cnt <= rx_high_cnt + 1'b1;
                end
            end
            3: begin
                if (dead_cnt > 0) begin
                    dead_cnt       <= dead_cnt - 1'b1;
                    rx_bit_syncclk <= 1'b0;
                end else begin
                    rx_arbit_state <= 2'd0;
                end
            end
            endcase
        end
    end

endmodule