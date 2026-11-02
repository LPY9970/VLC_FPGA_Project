`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 9600 bps, 50MHz, 16 倍过采样
//////////////////////////////////////////////////////////////////////////////////
module uart_rx(
    input  wire       Clk,
    input  wire       Rst_n,
    input  wire       Rs232_Rx,

    output reg  [7:0] data_byte,
    output reg        LED2,
    output reg        Rx_Done
);

    reg s0_Rs232_Rx, s1_Rs232_Rx;
    reg tmp0_Rs232_Rx, tmp1_Rs232_Rx;

    reg [15:0] div_cnt;
    reg        bps_clk;
    reg [7:0]  bps_cnt;
    reg        uart_state;

    reg [2:0] r_data_byte [7:0];
    reg [2:0] START_BIT;
    reg [2:0] STOP_BIT;

    wire nedege;

    // 同步寄存器，消除亚稳态；空闲为高
    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
        s0_Rs232_Rx <= 1'b1;
        s1_Rs232_Rx <= 1'b1;
    end else begin
        s0_Rs232_Rx <= Rs232_Rx;
        s1_Rs232_Rx <= s0_Rs232_Rx;
    end

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
        tmp0_Rs232_Rx <= 1'b1;
        tmp1_Rs232_Rx <= 1'b1;
    end else begin
        tmp0_Rs232_Rx <= s1_Rs232_Rx;
        tmp1_Rs232_Rx <= tmp0_Rs232_Rx;
    end

    assign nedege = !tmp0_Rs232_Rx & tmp1_Rs232_Rx;

    // 50MHz / 9600 / 16 ≈ 324
    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
        div_cnt <= 16'd0;
    else if (uart_state) begin
        if (div_cnt == 16'd324)
            div_cnt <= 16'd0;
        else
            div_cnt <= div_cnt + 1'b1;
    end else
        div_cnt <= 16'd0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
        bps_clk <= 1'b0;
    else if (div_cnt == 16'd1)
        bps_clk <= 1'b1;
    else
        bps_clk <= 1'b0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
        bps_cnt <= 8'd0;
    else if (bps_cnt == 8'd159 || (bps_cnt == 8'd12 && (START_BIT > 2)))
        bps_cnt <= 8'd0;
    else if (bps_clk)
        bps_cnt <= bps_cnt + 1'b1;
    else
        bps_cnt <= bps_cnt;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
        Rx_Done <= 1'b0;
        LED2    <= 1'b0;
    end else if (bps_cnt == 8'd159) begin
        Rx_Done <= 1'b1;
        LED2    <= ~LED2;
    end else
        Rx_Done <= 1'b0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
        data_byte <= 8'd0;
    else if (bps_cnt == 8'd159) begin
        data_byte[0] <= r_data_byte[0][2];
        data_byte[1] <= r_data_byte[1][2];
        data_byte[2] <= r_data_byte[2][2];
        data_byte[3] <= r_data_byte[3][2];
        data_byte[4] <= r_data_byte[4][2];
        data_byte[5] <= r_data_byte[5][2];
        data_byte[6] <= r_data_byte[6][2];
        data_byte[7] <= r_data_byte[7][2];
    end

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
        START_BIT <= 3'd0;
        r_data_byte[0] <= 3'd0; r_data_byte[1] <= 3'd0;
        r_data_byte[2] <= 3'd0; r_data_byte[3] <= 3'd0;
        r_data_byte[4] <= 3'd0; r_data_byte[5] <= 3'd0;
        r_data_byte[6] <= 3'd0; r_data_byte[7] <= 3'd0;
        STOP_BIT <= 3'd0;
    end else if (bps_clk) begin
        case (bps_cnt)
            0: begin
                START_BIT <= 3'd0;
                r_data_byte[0] <= 3'd0; r_data_byte[1] <= 3'd0;
                r_data_byte[2] <= 3'd0; r_data_byte[3] <= 3'd0;
                r_data_byte[4] <= 3'd0; r_data_byte[5] <= 3'd0;
                r_data_byte[6] <= 3'd0; r_data_byte[7] <= 3'd0;
                STOP_BIT <= 3'd0;
            end
            6,7,8,9,10,11:             START_BIT <= START_BIT + s1_Rs232_Rx;
            22,23,24,25,26,27:         r_data_byte[0] <= r_data_byte[0] + s1_Rs232_Rx;
            38,39,40,41,42,43:         r_data_byte[1] <= r_data_byte[1] + s1_Rs232_Rx;
            54,55,56,57,58,59:         r_data_byte[2] <= r_data_byte[2] + s1_Rs232_Rx;
            70,71,72,73,74,75:         r_data_byte[3] <= r_data_byte[3] + s1_Rs232_Rx;
            86,87,88,89,90,91:         r_data_byte[4] <= r_data_byte[4] + s1_Rs232_Rx;
            102,103,104,105,106,107:   r_data_byte[5] <= r_data_byte[5] + s1_Rs232_Rx;
            118,119,120,121,122,123:   r_data_byte[6] <= r_data_byte[6] + s1_Rs232_Rx;
            134,135,136,137,138,139:   r_data_byte[7] <= r_data_byte[7] + s1_Rs232_Rx;
            150,151,152,153,154,155:   STOP_BIT <= STOP_BIT + s1_Rs232_Rx;
            default: ;
        endcase
    end

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n)
        uart_state <= 1'b0;
    else if (nedege)
        uart_state <= 1'b1;
    else if (Rx_Done || (bps_cnt == 8'd12 && (START_BIT > 2)))
        uart_state <= 1'b0;
    else
        uart_state <= uart_state;

endmodule