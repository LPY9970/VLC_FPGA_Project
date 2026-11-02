# ==========================================
# 脚本功能：一键启动 TX 发射端工程的行为级仿真
# 使用方法：在 Vivado Tcl Console 中输入: source sim_tx.tcl
# ==========================================

# 1. 强制关闭旧仿真
if {[current_sim] != ""} { close_sim -force }

# 2. 打开工程
open_project ./TX/TX.xpr

# 3. 强制指定仿真顶层为 tb_tx_top
set_property top tb_tx_top [get_filesets sim_1]
update_compile_order -fileset sim_1

# 4. 启动并运行仿真
puts "==> 正在启动 TX 仿真..."
launch_simulation
run all

puts "=========================================================="
puts "🎉 TX 仿真完成！请查看波形窗口中的 VLC_TX_PIN 信号。"
puts "=========================================================="