`timescale 1ns / 1ps
module rx_top(
    input sys_clk_p, input sys_clk_n, input sys_reset,
    input VLC_RX_PIN,   // 绑 H14，接收光信号
    output UART_TX_PIN, // 绑 Y11，发给电脑
    output locked,
    output LED3,        // 解包指示灯 (V20)
    output LED4         // 串口发送指示灯 (U20)
);
    wire reset;
    wire sys_clk, clk50;

    // 时钟与复位
    IBUFDS sys_clk_ibufgds(.O(sys_clk), .I(sys_clk_p), .IB(sys_clk_n));
    clk_wiz_0 pll(.clk_out1(clk50), .reset(~sys_reset), .locked(locked), .clk_in1(sys_clk));
    Reset_Ctrl u0(.clk50(clk50), .sys_reset(locked), .reset(reset));

    // 内部连线
    wire rx_bit, rx_bit_syncclk, rx_bit_error;
    wire tx_wr_en;
    wire [7:0] tx_data;
    wire tx_empty, tx_rd_en, uart_state, send_en;
    wire [7:0] tx_dout;

    // 1. FSK 解调
    vlc_rx_fsk u4(
        .clk50(clk50), .reset(reset), .VLC_RX_PIN(VLC_RX_PIN),
        .rx_sync_retry(1'b0), .rx_bit_error(rx_bit_error),
        .rx_bit(rx_bit), .rx_bit_syncclk(rx_bit_syncclk)
    );

    // 2. 协议解包 (A6 CE D5)
    vlc_rx_ctrl u3(
        .clk50(clk50), .reset(reset),
        .rx_bit(rx_bit), .rx_bit_syncclk(rx_bit_syncclk), .rx_bit_error(rx_bit_error),
        .data_valid(), .tx_wr_en(tx_wr_en), .tx_data(tx_data), .LED3(LED3)
    );

    // 3. 发送 FIFO
    fifo_generator_0 fifo_tx (
        .clk(clk50), .srst(!reset),
        .din(tx_data), .wr_en(tx_wr_en), .rd_en(tx_rd_en),
        .dout(tx_dout), .full(), .empty(tx_empty), .data_count()
    );

    // 4. 串口发送
    assign tx_rd_en = (!tx_empty) && (!uart_state);
    assign send_en = tx_rd_en;
    uart_tx ut(
        .Clk(clk50), .Rst_n(reset), .data_byte(tx_dout), .send_en(send_en),
        .Rs232_Tx(UART_TX_PIN), .Tx_Done(), .LED4(LED4), .uart_state(uart_state)
    );
endmodule