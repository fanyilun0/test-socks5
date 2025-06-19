#!/bin/bash

# 加载依赖库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ip_detection.sh"
source "$SCRIPT_DIR/table_output.sh"

# 创建临时文件存储代理列表
temp_file=$(mktemp)
# 创建结果输出文件
output_file="http_proxy_test_results_$(date +%Y%m%d_%H%M%S).txt"

# 使用普通数组和文件来替代关联数组以提高兼容性
ip_list_file=$(mktemp)

# 存储表格数据
table_data_file=$(mktemp)

# 清理函数
cleanup() {
    rm -f "$temp_file" "$ip_list_file" "$table_data_file" 2>/dev/null
    cleanup_ip_detection
}
trap cleanup EXIT

# 检查IP是否已经测试过
is_ip_tested() {
    local ip="$1"
    grep -q "^$ip|" "$ip_list_file" 2>/dev/null
}

# 记录IP
record_ip() {
    local ip="$1"
    if is_ip_tested "$ip"; then
        # IP已存在，增加计数
        local current_count=$(grep "^$ip|" "$ip_list_file" | cut -d'|' -f2)
        local new_count=$((current_count + 1))
        # 使用临时文件更新
        grep -v "^$ip|" "$ip_list_file" > "${ip_list_file}.tmp" 2>/dev/null || true
        echo "$ip|$new_count" >> "${ip_list_file}.tmp"
        mv "${ip_list_file}.tmp" "$ip_list_file"
    else
        echo "$ip|1" >> "$ip_list_file"
    fi
}

# 提示用户输入代理列表
echo "请粘贴HTTP代理列表，完成后按Ctrl+D："
cat > "$temp_file"

{
    echo "开始测试HTTP代理..."
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    if [ -z "$IPQS_API_KEY" ] || [ "$IPQS_API_KEY" = "YOUR_API_KEY_HERE" ]; then
        echo "注意: 未配置IPQS API密钥，将跳过IP风险评分功能"
        echo "请编辑 config.sh 文件配置你的API密钥"
    else
        echo "已启用IP风险评分功能 (IPQualityScore)"
    fi
    echo "----------------------------------------"

    # 计数器
    total_count=0
    success_count=0
    unique_ips=0

    # 打印表格头部
    print_table_header "HTTP"

    while IFS= read -r line; do
        # 跳过空行
        [ -z "$line" ] && continue
        
        ((total_count++))
        
        # 添加http://前缀如果没有
        if [[ ! $line == http://* ]]; then
            proxy="http://$line"
        else
            proxy="$line"
        fi
        
        echo "测试HTTP代理: $proxy" >&2
        
        # 使用curl测试代理
        result=$(curl -s -m "$REQUEST_TIMEOUT" -x "$proxy" "https://ipv4.icanhazip.com" 2>/dev/null)
        status=$?
        
        if [ $status -eq 0 ] && [ -n "$result" ]; then
            echo "✅ 成功! 返回IP: $result" >&2
            
            # 获取IP摘要信息用于表格
            ip_summary=$(get_ip_summary "$result")
            
            # 打印表格行
            print_table_row "$total_count" "$proxy" "成功" "$result" "$ip_summary"
            
            # 详细信息输出到stderr以避免影响表格
            echo "IP详细信息:" >&2
            get_basic_ip_info "$result" >&2
            get_ip_risk_score "$result" >&2
            
            ((success_count++))
            record_ip "$result"
            
            # 保存表格数据
            echo "$total_count|$proxy|成功|$result|$ip_summary" >> "$table_data_file"
        else
            echo "❌ 失败! curl退出码: $status" >&2
            print_table_row "$total_count" "$proxy" "失败" "-" ""
            echo "$total_count|$proxy|失败|-|" >> "$table_data_file"
        fi
        echo "----------------------------------------" >&2
        
        # 添加延迟避免请求过快
        sleep "$REQUEST_DELAY"
    done < "$temp_file"

    # 计算唯一IP数
    if [ -f "$ip_list_file" ] && [ -s "$ip_list_file" ]; then
        unique_ips=$(wc -l < "$ip_list_file")
    fi

    # 打印表格底部
    print_table_footer "$total_count" "$success_count" "$unique_ips"

    # 打印IP使用情况表格
    if [ -f "$ip_list_file" ] && [ -s "$ip_list_file" ]; then
        print_ip_usage_table "$ip_list_file"
    fi

    echo -e "\n测试完成!"
} | tee "$output_file"

echo "详细结果已保存到: $output_file" 