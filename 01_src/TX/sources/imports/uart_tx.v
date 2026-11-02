`timescale 1ns / 1ps
module uart_tx(
    input  wire       Clk,
    input  wire       Rst_n,
    input  wire [7:0] data_byte,
    input  wire       send_en,
    output reg        Rs232_Tx,
    output reg        Tx_Done,
    output reg        LED4,
    output reg        uart_state
);

    reg        bps_clk;
    reg [15:0] div_cnt;
    reg [3:0]  bps_cnt;
    reg [7:0]  r_data_byte;
    reg        uart_state_tmp;
    reg        send_tmp;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) uart_state <= 1'b0;
    else if (send_en) uart_state <= 1'b1;
    else if (bps_cnt == 4'd11) uart_state <= 1'b0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) uart_state_tmp <= 1'b0;
    else uart_state_tmp <= uart_state;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) send_tmp <= 1'b0;
    else send_tmp <= send_en;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) r_data_byte <= 8'd0;
    else if (send_tmp) r_data_byte <= data_byte;

    // 50MHz / 9600 = 5208
    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) div_cnt <= 16'd0;
    else if (uart_state_tmp) begin
        if (div_cnt == 16'd5207) div_cnt <= 16'd0;
        else div_cnt <= div_cnt + 1'b1;
    end else
        div_cnt <= 16'd0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) bps_clk <= 1'b0;
    else if (div_cnt == 16'd1) bps_clk <= 1'b1;
    else bps_clk <= 1'b0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) bps_cnt <= 4'd0;
    else if (bps_cnt == 4'd11) bps_cnt <= 4'd0;
    else if (bps_clk) bps_cnt <= bps_cnt + 1'b1;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) begin
        Tx_Done <= 1'b0;
        LED4    <= 1'b0;
    end else if (bps_cnt == 4'd11) begin
        Tx_Done <= 1'b1;
        LED4    <= ~LED4;
    end else
        Tx_Done <= 1'b0;

    always @(posedge Clk or negedge Rst_n)
    if (!Rst_n) Rs232_Tx <= 1'b1;
    else begin
        case (bps_cnt)
            0:  Rs232_Tx <= 1'b1;
            1:  Rs232_Tx <= 1'b0;
            2:  Rs232_Tx <= r_data_byte[0];
            3:  Rs232_Tx <= r_data_byte[1];
            4:  Rs232_Tx <= r_data_byte[2];
            5:  Rs232_Tx <= r_data_byte[3];
            6:  Rs232_Tx <= r_data_byte[4];
            7:  Rs232_Tx <= r_data_byte[5];
            8:  Rs232_Tx <= r_data_byte[6];
            9:  Rs232_Tx <= r_data_byte[7];
            10: Rs232_Tx <= 1'b1;
            default: Rs232_Tx <= 1'b1;
        endcase
    end

endmodule