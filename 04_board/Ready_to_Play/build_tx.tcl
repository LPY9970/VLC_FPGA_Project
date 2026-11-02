# ==========================================
# 脚本功能：一键打开并编译 TX 发射端工程
# 使用方法：在 Vivado Tcl Console 中输入: source build_tx.tcl
# ==========================================

set proj_file "./TX/TX.xpr"
puts "==> 正在打开 TX 工程: $proj_file"
open_project $proj_file
reset_project

puts "==> 开始综合..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "TX 综合失败！"
}

puts "==> 开始实现..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "TX 实现失败！"
}

puts "=========================================================="
puts "🎉 TX 工程编译完成！可以去烧录了。"
puts "=========================================================="