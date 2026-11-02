`timescale 1ns / 1ps
module tb_rx_top();
    reg sys_clk_p;
    reg sys_clk_n;
    reg sys_reset;
    reg VLC_RX_PIN;

    wire UART_TX_PIN;
    wire locked;
    wire LED3;
    wire LED4;
    
    integer i; 

    rx_top uut (
        .sys_clk_p(sys_clk_p),
        .sys_clk_n(sys_clk_n),
        .sys_reset(sys_reset),
        .VLC_RX_PIN(VLC_RX_PIN),
        .UART_TX_PIN(UART_TX_PIN),
        .locked(locked),
        .LED3(LED3),
        .LED4(LED4)
    );

    initial begin
        sys_clk_p = 0; sys_clk_n = 1;
        forever begin
            #2.5 sys_clk_p = 1; sys_clk_n = 0;
            #2.5 sys_clk_p = 0; sys_clk_n = 1;
        end
    end

    task send_fsk_bit(input bit_val);
        begin
            if (bit_val == 0) begin
                VLC_RX_PIN = 1; #250; // 12.5 个时钟
                VLC_RX_PIN = 0; #750; 
            end else begin
                VLC_RX_PIN = 1; #500; // 25 个时钟
                VLC_RX_PIN = 0; #500;
            end
        end
    endtask

    task send_byte(input [7:0] data);
        begin
            send_fsk_bit(1'b0); // 起始位
            for (i = 0; i < 8; i = i + 1) begin
                send_fsk_bit(data[i]); 
            end
            send_fsk_bit(1'b1); // 停止位
            #5000; // 字节间多等一下
        end
    endtask

    initial begin
        sys_reset = 0;
        VLC_RX_PIN = 1;
        #200;
        sys_reset = 1;
        
        #100_000; 
        
        // 1. 发帧头
        send_byte(8'hA6);
        send_byte(8'hCE);
        send_byte(8'hD5);
        
        // 2. 发数据 (必须发满 10 个，你代码里才会亮灯)
        send_byte(8'h11); // 1
        send_byte(8'h22); // 2
        send_byte(8'h33); // 3
        send_byte(8'h44); // 4
        send_byte(8'h55); // 5
        send_byte(8'h66); // 6
        send_byte(8'h77); // 7
        send_byte(8'h77); // 8
        send_byte(8'h77); // 9
        send_byte(8'h88); // 10 (触发LED3翻转！)
        
        #50_000;
        $finish;
    end
endmodule