`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 模块功能：产生 1Mbps 的 PRBS-7 伪随机序列，从 K14 引脚输出
// 新增 SYNC_PIN 同步脉冲输出（接 K13），用于示波器稳定触发
//////////////////////////////////////////////////////////////////////////////////
module prbs_top(
    input  wire sys_clk_p,   // 板载 200MHz 差分时钟 P
    input  wire sys_clk_n,   // 板载 200MHz 差分时钟 N
    input  wire sys_reset,   // 复位按键

    output wire VLC_TX_PIN,  // K14 输出 PRBS 信号
    output wire SYNC_PIN,    // K13 输出同步触发信号 (接示波器通道2)
    output wire locked       // PLL 锁定指示灯
);

    wire sys_clk;
    wire clk50;

    // 差分转单端
    IBUFDS sys_clk_ibufgds(.O(sys_clk), .I(sys_clk_p), .IB(sys_clk_n));

    // PLL 将 200M 降到 50M
    clk_wiz_0 pll(
        .clk_out1(clk50),
        .reset(~sys_reset),
        .locked(locked),
        .clk_in1(sys_clk)
    );

    // ==========================================
    // 1. 波特率产生器 (1Mbps = 1MHz 频率)
    // ==========================================
    reg [5:0] clk_cnt;
    reg       bit_en;

    always @(posedge clk50) begin
        if (!locked) begin
            clk_cnt <= 6'd0;
            bit_en  <= 1'b0;
        end else if (clk_cnt == 6'd49) begin
            clk_cnt <= 6'd0;
            bit_en  <= 1'b1; // 每 50 个时钟产生一个周期的脉冲
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
            bit_en  <= 1'b0;
        end
    end

    // ==========================================
    // 2. PRBS-7 生成器 (多项式：X^7 + X^6 + 1)
    // ==========================================
    reg [6:0] prbs_reg;
    reg       sync_reg;

    always @(posedge clk50) begin
        if (!locked) begin
            prbs_reg <= 7'b111_1111; // 初始种子
            sync_reg <= 1'b0;
        end
        else if (bit_en) begin
            // 每次寄存器回到初始种子 1111111 时，说明新一轮周期开始了
            if (prbs_reg == 7'b111_1111) begin
                sync_reg <= 1'b1;
            end else begin
                sync_reg <= 1'b0;
            end

            // 移位计算
            prbs_reg <= {prbs_reg[5:0], (prbs_reg[6] ^ prbs_reg[5])};
        end
    end

    // ==========================================
    // 3. 输出
    // ==========================================
    // K14 输出 PRBS 波形
    assign VLC_TX_PIN = prbs_reg[6];

    // K13 输出同步脉冲（当序列处于第一个 bit 时为高电平）
    assign SYNC_PIN = sync_reg;

endmodule