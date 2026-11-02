# ==========================================
# 脚本功能：一键打开并编译 PRBS 测试工程
# 使用方法：在 Vivado Tcl Console 中输入: source build_prbs.tcl
# ==========================================

# 1. 打开现有的工程文件 (确保路径正确)
set proj_file "./PRBS/PRBS.xpr"
puts "==> 正在打开工程: $proj_file"
open_project $proj_file

# 2. 清理旧的编译缓存（防止环境切换导致报错）
puts "==> 正在清理旧缓存..."
reset_project

# 3. 自动跑综合
puts "==> 开始综合 (Synthesis)..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "综合失败！请检查代码。"
}

# 4. 自动跑实现并生成 Bit 流
puts "==> 开始实现并生成 Bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "实现失败！请检查管脚约束。"
}

# 5. 打印成功信息
puts "=========================================================="
puts "🎉 PRBS 工程编译完成！"
puts "生成的 .bit 文件位于：./PRBS/PRBS.runs/impl_1/你的顶层模块名.bit"
puts "=========================================================="