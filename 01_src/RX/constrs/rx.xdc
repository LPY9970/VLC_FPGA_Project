set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVDS_25} [get_ports sys_clk_p]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVDS_25} [get_ports sys_clk_n]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS15} [get_ports sys_reset]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports locked]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports UART_TX_PIN]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports LED3]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports LED4]
# 1. 系统 200MHz 差分时钟
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]

# 2. 复位按键

# 3. PLL 锁定指示灯

# 4. 串口发送 (接电脑)

# 5. 用户 LED (RX 板)

# 6. VLC 光通信接收引脚 (H14 加上拉)s
set_property PACKAGE_PIN H14 [get_ports VLC_RX_PIN]
set_property IOSTANDARD LVCMOS33 [get_ports VLC_RX_PIN]
set_property PULLTYPE PULLUP [get_ports VLC_RX_PIN]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

set_load 5.000 [all_outputs]
set_property LOAD 5 [get_ports LED3]
set_property LOAD 5 [get_ports LED4]
set_property LOAD 5 [get_ports UART_TX_PIN]
set_property LOAD 5 [get_ports locked]
