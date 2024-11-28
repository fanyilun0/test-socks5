#!/bin/bash

# 创建临时文件存储代理列表
temp_file=$(mktemp)
# 创建结果输出文件
output_file="proxy_test_results_$(date +%Y%m%d_%H%M%S).txt"
# 创建数组存储所有返回的IP
declare -A ip_count
declare -A ip_info

# 获取IP详细信息的函数
get_ip_info() {
    local ip="$1"
    # 如果已经查询过该IP，直接返回缓存的结果
    if [ -n "${ip_info[$ip]}" ]; then
        echo "${ip_info[$ip]}"
        return
    fi
    
    # 使用ipinfo.io查询IP信息
    local info
    info=$(curl -s "https://ipinfo.io/$ip/json")
    if [ $? -eq 0 ]; then
        # 确保jq已安装
        if ! command -v jq &> /dev/null; then
            echo "需要安装jq来解析JSON。请运行: apt-get install jq"
            return
        fi
        
        # 解析JSON并格式化输出
        local country region city org timezone
        country=$(echo "$info" | jq -r '.country // "未知"')
        region=$(echo "$info" | jq -r '.region // "未知"')
        city=$(echo "$info" | jq -r '.city // "未知"')
        org=$(echo "$info" | jq -r '.org // "未知"')
        timezone=$(echo "$info" | jq -r '.timezone // "未知"')
        
        # 构建信息字符串 - 移除\n转义符
        local info_str="    国家/地区: $country | 城市: $city, $region | 组织: $org | 时区: $timezone"
        ip_info[$ip]="$info_str"
        echo "$info_str"
    else
        echo "    无法获取IP信息"
    fi
}

# 提示用户输入代理列表
echo "请粘贴代理列表，完成后按Ctrl+D："
cat > "$temp_file"

{
    echo "开始测试代理..."
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "----------------------------------------"

    # 计数器
    total_count=0
    success_count=0

    while IFS= read -r line; do
        # 跳过空行
        [ -z "$line" ] && continue
        
        ((total_count++))
        
        # 添加socks5://前缀如果没有
        if [[ ! $line == socks5://* ]]; then
            proxy="socks5://$line"
        else
            proxy="$line"
        fi
        
        echo "测试代理: $proxy"
        
        # 使用curl测试代理
        result=$(curl -s -m 10 -x "$proxy" "https://ipv4.icanhazip.com" 2>/dev/null)
        status=$?
        
        if [ $status -eq 0 ] && [ -n "$result" ]; then
            echo "✅ 成功! 返回IP: $result"
            echo "IP详细信息:"
            get_ip_info "$result"
            ((success_count++))
            ((ip_count[$result]++))
        else
            echo "❌ 失败! curl退出码: $status"
        fi
        echo "----------------------------------------"
        
        # 添加短暂延迟避免请求过快
        sleep 1
    done < "$temp_file"

    # 输出统计信息
    echo -e "\n统计信息："
    echo "总测试代理数: $total_count"
    echo "成功数: $success_count"
    echo "失败数: $((total_count - success_count))"
    if [ $total_count -gt 0 ]; then
        echo "成功率: $(( (success_count * 100) / total_count ))%"
    fi

    # 输出IP重复情况
    echo -e "\nIP使用情况："
    for ip in "${!ip_count[@]}"; do
        count="${ip_count[$ip]}"
        echo "IP: $ip 出现 $count 次"
        if [ "$count" -gt 1 ]; then
            echo "⚠️ 警告：IP $ip 重复使用了 $count 次"
        fi
        echo "详细信息:"
        echo -e "${ip_info[$ip]}"
        echo "----------------------------------------"
    done

    echo -e "\n测试完成!"
} | tee "$output_file"

# 清理临时文件
rm -f "$temp_file"

echo "详细结果已保存到: $output_file"
