`timescale 1ns / 1ps
module Reset_Ctrl(
	input clk50,
	input sys_reset,
	output reg reset
    );

reg [25:0] reset_cnt;

// 50MHz ¡Á 1s = 50,000,000£¬¼Æµ½ 49_999_999 Îª 1s
always@(posedge clk50 or negedge sys_reset)begin
	if(!sys_reset)begin
		reset_cnt <= 26'd0;
		reset <= 1'b0;
	end
	else begin
		if(reset_cnt == 26'd49_999_999)begin
			reset <= 1'b1;
		end
		else begin
			reset_cnt <= reset_cnt + 1'b1;
			reset <= 1'b0;
		end
	end
end

endmodule