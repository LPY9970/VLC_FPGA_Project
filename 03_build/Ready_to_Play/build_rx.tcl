# ==========================================
# 脚本功能：一键打开并编译 RX / 回环工程
# 使用方法：在 Vivado Tcl Console 中输入: source build_rx.tcl
# ==========================================

set proj_file "./RX/RX.xpr"
puts "==> 正在打开 RX 工程: $proj_file"
open_project $proj_file
reset_project

puts "==> 开始综合..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "RX 综合失败！"
}

puts "==> 开始实现..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "RX 实现失败！"
}

puts "=========================================================="
puts "🎉 RX 工程编译完成！"
puts "=========================================================="