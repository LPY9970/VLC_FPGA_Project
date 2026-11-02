`timescale 1ns / 1ps

module tb_tx_top();

    // 1. 定义输入信号 (对应 tx_top 的 input)
    reg  sys_clk_p;
    reg  sys_clk_n;
    reg  sys_reset;
    reg  UART_RX_PIN;

    // 2. 定义输出信号 (对应 tx_top 的 output)
    wire VLC_TX_PIN;
    wire VLC_TX_PIN2;
    wire locked;
    wire LED1, LED2, LED3, LED4;

    // 3. 例化顶层模块 (端口名一字不差)
    tx_top uut (
        .sys_clk_p(sys_clk_p),
        .sys_clk_n(sys_clk_n),
        .sys_reset(sys_reset),
        .UART_RX_PIN(UART_RX_PIN),
        .VLC_TX_PIN(VLC_TX_PIN),
        .VLC_TX_PIN2(VLC_TX_PIN2),
        .locked(locked),
        .LED1(LED1),
        .LED2(LED2),
        .LED3(LED3),
        .LED4(LED4)
    );

    // 4. 产生 200MHz 差分时钟
    initial begin
        sys_clk_p = 0;
        sys_clk_n = 1;
        forever begin
            #2.5 sys_clk_p = 1; sys_clk_n = 0; // 半周期 2.5ns
            #2.5 sys_clk_p = 0; sys_clk_n = 1;
        end
    end

    // 5. 产生复位信号
    initial begin
        sys_reset = 0; // 初始按下复位
        #200;
        sys_reset = 1; // 200ns 后松开复位
    end

    // 6. 模拟串口空闲状态
    initial begin
        UART_RX_PIN = 1'b1; // 串口空闲时保持高电平
    end

    // 7. 仿真运行时间 (跑 2 毫秒，足够看几包数据了，然后自动停止)
    initial begin
        #2_000_000; 
        $finish;    
    end

endmodule