set PDK_PATH "/home/jjt/install/pdk/nangate45"

create_lib final_test.ndm \
    -technology ${PDK_PATH}/rtk-tech.tf \
    -ref_libs {./work_icc2/nangate45_stdcells.ndm}

# 正确的查询方式：指定库名
set cells [get_lib_cells nangate45_stdcells/* -quiet]

puts "\n=========================================="
puts "✓✓✓ 最终验证结果 ✓✓✓"
puts "=========================================="
puts "标准单元总数: [sizeof_collection $cells]"

if {[sizeof_collection $cells] > 100} {
    puts "\n✓✓✓ 成功！NDM 参考库完全可用！✓✓✓"
    puts "\n单元示例（前15个）："
    set count 0
    foreach_in_collection cell $cells {
        set cell_name [get_object_name $cell]
        # 移除 /frame 后缀显示
        regsub {/frame$} $cell_name "" clean_name
        puts "  $clean_name"
        incr count
        if {$count >= 15} break
    }
    puts "\n库文件位置: ./work_icc2/nangate45_stdcells.ndm"
    puts "在 ICC2 脚本中使用方法："
    puts "  create_lib <design>.ndm -technology <tech.tf> \\"
    puts "    -ref_libs {./work_icc2/nangate45_stdcells.ndm}"
} else {
    puts "✗ 单元数不足"
}

close_lib
exit
