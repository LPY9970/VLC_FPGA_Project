# ==========================================
# 脚本功能：一键启动 PRBS 测试工程的行为级仿真
# 使用方法：在 Vivado Tcl Console 中输入: source sim_prbs.tcl
# ==========================================

# 1. 如果之前有打开的仿真，先强制关闭
if {[current_sim] != ""} { close_sim -force }

# 2. 打开工程 (注意路径，如果你在 04_board 目录下，路径如下)
open_project ./PRBS/PRBS.xpr

# 3. 强制指定仿真顶层为 tb_prbs_top
set_property top tb_prbs_top [get_filesets sim_1]
update_compile_order -fileset sim_1

# 4. 启动并运行仿真
puts "==> 正在启动 PRBS 仿真..."
launch_simulation
run all

puts "=========================================================="
puts "🎉 PRBS 仿真完成！请查看弹出的波形窗口。"
puts "提示：点击波形窗口工具栏的 'Zoom Fit' (或按 F6) 查看全局。"
puts "=========================================================="