`timescale 1ns / 1ps
module vlc_tx_ctrl(
    input  wire        clk50,
    input  wire        reset,
    input  wire        uart_active,      // 新增：串口活动标志（超时产生）
    input  wire        vlc_tx_finish,
    input  wire        vlc_data_latched,
    input  wire [7:0]  rx_dout,
    input  wire [10:0] rx_data_count,

    output wire        rx_rd_en,
    output reg         vlc_wrsig,
    output reg  [7:0]  vlc_tx_data,
    output reg         LED1
);

    // “2017至2026 FPGA创新设计竞赛国赛十周年\r\n” + 空格，共 40 字节
    reg [7:0] text_rom [0:39];
    initial begin
        text_rom[0]  = 8'h32; text_rom[1]  = 8'h30;
        text_rom[2]  = 8'h31; text_rom[3]  = 8'h37;
        text_rom[4]  = 8'hD6; text_rom[5]  = 8'hC1;
        text_rom[6]  = 8'h32; text_rom[7]  = 8'h30;
        text_rom[8]  = 8'h32; text_rom[9]  = 8'h36;
        text_rom[10] = 8'h20;
        text_rom[11] = 8'h46; text_rom[12] = 8'h50;
        text_rom[13] = 8'h47; text_rom[14] = 8'h41;
        text_rom[15] = 8'hB4; text_rom[16] = 8'hB4;
        text_rom[17] = 8'hD0; text_rom[18] = 8'hC2;
        text_rom[19] = 8'hC9; text_rom[20] = 8'hE8;
        text_rom[21] = 8'hBC; text_rom[22] = 8'hC6;
        text_rom[23] = 8'hBE; text_rom[24] = 8'hBA;
        text_rom[25] = 8'hC8; text_rom[26] = 8'hFC;
        text_rom[27] = 8'hB9; text_rom[28] = 8'hFA;
        text_rom[29] = 8'hC8; text_rom[30] = 8'hFC;
        text_rom[31] = 8'hCA; text_rom[32] = 8'hAE;
        text_rom[33] = 8'hD6; text_rom[34] = 8'hDC;
        text_rom[35] = 8'hC4; text_rom[36] = 8'hEA;
        text_rom[37] = 8'h0D; text_rom[38] = 8'h0A;
        text_rom[39] = 8'h20;
    end

    reg [2:0]  mx_state;
    reg [25:0] timewait;
    reg [5:0]  auto_offset;
    reg [3:0]  tx_cnt;
    reg        is_uart_mode;
    reg        rd_fifo_pending;

    // 只有确实要读 FIFO 时才拉高 rx_rd_en（避免读空 FIFO）
    assign rx_rd_en = (mx_state == 3) && is_uart_mode &&
                      vlc_tx_finish && (tx_cnt >= 1) && (tx_cnt <= 10) &&
                      (rx_data_count != 0);

    always @(posedge clk50 or negedge reset) begin
        if (!reset) begin
            mx_state        <= 3'd0;
            LED1            <= 1'b0;
            timewait        <= 26'd0;
            tx_cnt          <= 4'd0;
            vlc_tx_data     <= 8'd0;
            vlc_wrsig       <= 1'b0;
            auto_offset     <= 6'd0;
            is_uart_mode    <= 1'b0;
            rd_fifo_pending <= 1'b0;
        end else begin
            // 锁存完成后统一清 vlc_wrsig
            if (vlc_data_latched)
                vlc_wrsig <= 1'b0;

            case (mx_state)

            0: begin // 空闲：根据 uart_active 决定本帧类型
                vlc_wrsig       <= 1'b0;
                vlc_tx_data     <= 8'd0;
                rd_fifo_pending <= 1'b0;
                is_uart_mode    <= uart_active;   // 关键修改：用活动标志而非瞬时计数
                mx_state        <= 3'd1;
            end

            1: begin // 发 A6
                if (vlc_tx_finish) begin
                    vlc_wrsig   <= 1'b1;
                    vlc_tx_data <= 8'hA6;
                    mx_state    <= 3'd2;
                end
            end

            2: begin // 发 CE
                if (vlc_tx_finish) begin
                    vlc_wrsig   <= 1'b1;
                    vlc_tx_data <= 8'hCE;
                    mx_state    <= 3'd3;
                    tx_cnt      <= 4'd0;
                end
            end

            3: begin // 发 D5 + 10 字节
                if (vlc_tx_finish) begin
                    if (tx_cnt == 4'd0) begin
                        vlc_wrsig   <= 1'b1;
                        vlc_tx_data <= 8'hD5;
                        tx_cnt      <= 4'd1;
                    end else if (tx_cnt <= 4'd10) begin
                        if (is_uart_mode && (rx_data_count != 0)) begin
                            // 读 FIFO，下一拍用 rd_fifo_pending 发出
                            rd_fifo_pending <= 1'b1;
                        end else if (is_uart_mode) begin
                            // UART 模式但 FIFO 空：补空格，保证对端收满 10 字节
                            vlc_wrsig   <= 1'b1;
                            vlc_tx_data <= 8'h20;
                            tx_cnt      <= tx_cnt + 1'b1;
                        end else begin
                            // 文字模式
                            vlc_wrsig   <= 1'b1;
                            vlc_tx_data <= text_rom[auto_offset + tx_cnt - 1];
                            tx_cnt      <= tx_cnt + 1'b1;
                        end
                    end else begin
                        vlc_wrsig <= 1'b0;
                        mx_state  <= 3'd4;
                        LED1      <= ~LED1;
                    end
                end else if (rd_fifo_pending) begin
                    vlc_wrsig       <= 1'b1;
                    vlc_tx_data     <= rx_dout;
                    tx_cnt          <= tx_cnt + 1'b1;
                    rd_fifo_pending <= 1'b0;
                end
            end

            4: begin // 停顿，匹配 9600 吞吐
                vlc_wrsig <= 1'b0;
                if (timewait == 26'd515_000) begin
                    timewait <= 26'd0;
                    mx_state <= 3'd0;
                    if (!is_uart_mode) begin
                        if (auto_offset >= 6'd30) auto_offset <= 6'd0;
                        else                      auto_offset <= auto_offset + 6'd10;
                    end
                end else begin
                    timewait <= timewait + 1'b1;
                end
            end

            default: mx_state <= 3'd0;
            endcase
        end
    end

endmodule