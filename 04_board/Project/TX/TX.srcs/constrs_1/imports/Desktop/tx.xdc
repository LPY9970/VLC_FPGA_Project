# 1. 系统 200MHz 差分时钟
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVDS_25} [get_ports sys_clk_p]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVDS_25} [get_ports sys_clk_n]
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]

# 2. 复位按键
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS15} [get_ports sys_reset]

# 3. PLL 锁定指示灯
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports locked]

# 4. 串口接收 (接电脑)
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33 PULLUP true} [get_ports UART_RX_PIN]

# 5. 用户 LED (TX 板)
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports LED1]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports LED2]

# 6. VLC 光通信发送引脚
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports VLC_TX_PIN]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports VLC_TX_PIN2]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
# 补全缺失的三个引脚约束
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports UART_TX_PIN]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports LED3]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports LED4]