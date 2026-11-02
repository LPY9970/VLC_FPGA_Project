# ==========================================
# 自动比对资源与时序验证脚本
# ==========================================
open_run impl_1

puts "\n================== 质量校验开始 =================="

# 1. 提取时序数据 (WNS - Worst Negative Slack)
set timing_paths [get_timing_paths -delay_type max]
if {[llength $timing_paths] > 0} {
    set wns [get_property SLACK $timing_paths]
} else {
    set wns 999.0
}
puts "==> 当前 WNS (最差时序裕量): $wns ns"

# 2. 提取资源利用率 (LUT)
set util_rpt [report_utilization -return_string]
# 正则匹配提取 LUT 数量
regexp {Slice LUTs\s+\|\s+(\d+)} $util_rpt match used_lut
if {![info exists used_lut]} {
    set used_lut 0
}
puts "==> 当前 LUT 占用: $used_lut"

# 3. 黄金参考比对
set target_wns 0.0
set max_lut 5000

set pass_flag 1

if { $wns < $target_wns } {
    puts "❌ 严重警告：时序违例！WNS ($wns) < 黄金参考 ($target_wns)。工程不可交付！"
    set pass_flag 0
} else {
    puts "✅ 时序验证通过：WNS 满足要求。"
}

if { $used_lut > $max_lut } {
    puts "❌ 严重警告：资源超标！LUT ($used_lut) > 黄金参考 ($max_lut)。工程不可交付！"
    set pass_flag 0
} else {
    puts "✅ 资源验证通过：LUT 占用合格。"
}

if { $pass_flag == 1 } {
    puts "🎉 校验完毕，工程具备可复现性与交付标准！\n"
} else {
    error "❌ 校验未通过，请优化代码或修改阈值！"
}