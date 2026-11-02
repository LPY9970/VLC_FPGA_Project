# ==========================================
# 脚本功能：一键启动 RX 接收端工程的行为级仿真
# 使用方法：在 Vivado Tcl Console 中输入: source sim_rx.tcl
# ==========================================

# 1. 强制关闭旧仿真
if {[current_sim] != ""} { close_sim -force }

# 2. 打开工程
open_project ./RX/RX.xpr

# 3. 强制指定仿真顶层为 tb_rx_top
set_property top tb_rx_top [get_filesets sim_1]
update_compile_order -fileset sim_1

# 4. 启动并运行仿真
puts "==> 正在启动 RX 仿真..."
launch_simulation
run all

puts "=========================================================="
puts "🎉 RX 仿真完成！请查看波形窗口中的 UART_TX_PIN 信号。"
puts "=========================================================="