set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVDS_25} [get_ports sys_clk_p]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVDS_25} [get_ports sys_clk_n]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS15} [get_ports sys_reset]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports locked]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports VLC_TX_PIN]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports SYNC_PIN]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports VLC_TX_PIN]
# ==========================================
# 1. 系统 200MHz 差分时钟
# ==========================================
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]

# ==========================================
# 2. 复位按键
# ==========================================

# ==========================================
# 3. 指示灯 (PLL锁定)
# ==========================================

# ==========================================
# 4. PRBS 信号输出引脚
# ==========================================
# K14 输出 PRBS 波形 (接示波器 CH1)

# K13 输出同步触发信号 (接示波器 CH2)
# ==========================================
# 4. PRBS 波形输出 (K14)
# ==========================================
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

set_load 5.000 [all_outputs]
set_property LOAD 5 [get_ports SYNC_PIN]
set_property LOAD 5 [get_ports VLC_TX_PIN]
set_property LOAD 5 [get_ports locked]
