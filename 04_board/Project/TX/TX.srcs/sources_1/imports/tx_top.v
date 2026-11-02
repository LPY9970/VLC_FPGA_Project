`timescale 1ns / 1ps
module tx_top(
    input  wire sys_clk_p,
    input  wire sys_clk_n,
    input  wire sys_reset,
    input  wire UART_RX_PIN,

    output wire VLC_TX_PIN,
    output wire VLC_TX_PIN2,
    output wire locked,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4
);

    wire sys_clk;
    wire clk50;
    wire reset;

    IBUFDS sys_clk_ibufgds(.O(sys_clk), .I(sys_clk_p), .IB(sys_clk_n));

    clk_wiz_0 pll(
        .clk_out1(clk50),
        .reset(~sys_reset),
        .locked(locked),
        .clk_in1(sys_clk)
    );

    reg [7:0] rst_cnt = 8'd0;
    always @(posedge clk50) begin
        if (!locked)
            rst_cnt <= 8'd0;
        else if (rst_cnt != 8'd255)
            rst_cnt <= rst_cnt + 1'b1;
    end
    assign reset = (rst_cnt == 8'd255);

    assign LED3 = 1'b0;
    assign LED4 = 1'b0;

    wire [7:0]  rx_dout;
    wire [10:0] rx_data_count;
    wire        rx_rd_en;
    wire        vlc_wrsig;
    wire [7:0]  vlc_tx_data;
    wire        vlc_tx_finish;
    wire        vlc_data_latched;
    wire        Rx_Done;
    wire [7:0]  uart_rx_data;
    wire        rx_fifo_wen;

    // 1. 串口接收电脑数据（9600）
    uart_rx ur(
        .Clk(clk50),
        .Rst_n(reset),
        .Rs232_Rx(UART_RX_PIN),
        .data_byte(uart_rx_data),
        .LED2(LED2),
        .Rx_Done(Rx_Done)
    );

    // 2. 接收 FIFO
    assign rx_fifo_wen = Rx_Done;
    fifo_generator_0 fifo_rx (
        .clk(clk50),
        .srst(!reset),
        .din(uart_rx_data),
        .wr_en(rx_fifo_wen),
        .rd_en(rx_rd_en),
        .dout(rx_dout),
        .full(),
        .empty(),
        .data_count(rx_data_count)
    );

    // 2.5 UART 活动标志 + 超时
    // 收到任意字节后置位；持续 50ms 无新字节则清零，切换到文字模式
    // 50ms @ 50MHz = 2,500,000
    reg        uart_active;
    reg [21:0] uart_idle_cnt;
    always @(posedge clk50) begin
        if (!reset) begin
            uart_active   <= 1'b0;
            uart_idle_cnt <= 22'd0;
        end else if (rx_fifo_wen) begin
            uart_active   <= 1'b1;
            uart_idle_cnt <= 22'd0;
        end else if (uart_active) begin
            if (uart_idle_cnt >= 22'd2_499_999) begin
                uart_active   <= 1'b0;
                uart_idle_cnt <= 22'd0;
            end else begin
                uart_idle_cnt <= uart_idle_cnt + 1'b1;
            end
        end
    end

    // 3. 发送控制
    vlc_tx_ctrl u1(
        .clk50(clk50),
        .reset(reset),
        .uart_active(uart_active),          // 新增
        .vlc_tx_finish(vlc_tx_finish),
        .vlc_data_latched(vlc_data_latched),
        .rx_dout(rx_dout),
        .rx_data_count(rx_data_count),
        .rx_rd_en(rx_rd_en),
        .vlc_wrsig(vlc_wrsig),
        .vlc_tx_data(vlc_tx_data),
        .LED1(LED1)
    );

    // 4. FSK 调制
    vlc_tx_fsk u2(
        .clk50(clk50),
        .reset(reset),
        .vlc_wrsig(vlc_wrsig),
        .vlc_tx_data(vlc_tx_data),
        .vlc_tx_finish(vlc_tx_finish),
        .vlc_data_latched(vlc_data_latched),
        .VLC_TX_PIN(VLC_TX_PIN)
    );

    assign VLC_TX_PIN2 = VLC_TX_PIN;

endmodule