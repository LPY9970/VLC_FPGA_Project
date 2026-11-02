`timescale 1ns / 1ps
module tb_prbs_top();
    reg sys_clk_p;
    reg sys_clk_n;
    reg sys_reset;

    wire VLC_TX_PIN;
    wire SYNC_PIN;
    wire locked;

    // 例化顶层
    prbs_top uut (
        .sys_clk_p(sys_clk_p),
        .sys_clk_n(sys_clk_n),
        .sys_reset(sys_reset),
        .VLC_TX_PIN(VLC_TX_PIN),
        .SYNC_PIN(SYNC_PIN),
        .locked(locked)
    );

    // 200MHz 差分时钟
    initial begin
        sys_clk_p = 0; sys_clk_n = 1;
        forever begin
            #2.5 sys_clk_p = 1; sys_clk_n = 0;
            #2.5 sys_clk_p = 0; sys_clk_n = 1;
        end
    end

    // 复位
    initial begin
        sys_reset = 0;
        #200;
        sys_reset = 1;
    end

    // 运行时间 (跑 10us 看几个周期的 PRBS 即可)
    initial begin
        #2_000_000;
        $finish;
    end
endmodule