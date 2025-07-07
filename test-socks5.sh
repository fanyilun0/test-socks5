#!/bin/bash
# 检测运行环境
detect_environment() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# 检测 bash 版本是否支持关联数组
check_bash_version() {
    if [ "${BASH_VERSION%%.*}" -ge 4 ]; then
        return 0  # 支持关联数组
    else
        return 1  # 不支持关联数组
    fi
}

# 创建临时文件存储代理列表
temp_file=$(mktemp)
# 创建结果输出文件
output_file="proxy_test_results_$(date +%Y%m%d_%H%M%S).txt"

# 根据环境选择数据存储方式
ENV=$(detect_environment)
if check_bash_version; then
    # 使用关联数组（bash 4.0+）
    declare -A ip_count
    declare -A ip_info
    USE_ASSOCIATIVE_ARRAYS=true
else
    # 使用文件存储（兼容模式）
    ip_list_file=$(mktemp)
    ip_info_file=$(mktemp)
    USE_ASSOCIATIVE_ARRAYS=false
fi

# 获取IP详细信息的函数（多服务备选）
get_ip_info() {
    local ip="$1"
    
    if [ "$USE_ASSOCIATIVE_ARRAYS" = true ]; then
        # 使用关联数组
        if [ -n "${ip_info[$ip]}" ]; then
            echo "${ip_info[$ip]}"
            return
        fi
    else
        # 使用文件缓存
        local cached_info=$(grep "^$ip:" "$ip_info_file" 2>/dev/null | cut -d: -f2-)
        if [ -n "$cached_info" ]; then
            echo "$cached_info"
            return
        fi
    fi
    
    # 确保jq已安装
    if ! command -v jq &> /dev/null; then
        case "$ENV" in
            "macOS")
                echo "需要安装jq来解析JSON。请运行: brew install jq"
                ;;
            "linux")
                echo "需要安装jq来解析JSON。请运行: apt-get install jq 或 yum install jq"
                ;;
            *)
                echo "需要安装jq来解析JSON。"
                ;;
        esac
        return
    fi
    
    # 服务1: ip-api.com (免费，无限制)
    local info=""
    local service_name=""
    info=$(curl -s -m 5 "http://ip-api.com/json/$ip" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$info" ]; then
        local status=$(echo "$info" | jq -r '.status // "fail"')
        if [ "$status" = "success" ]; then
            service_name="ip-api.com"
        fi
    fi
    
    # 服务2: ipapi.co (如果第一个失败)
    if [ -z "$service_name" ]; then
        info=$(curl -s -m 5 "https://ipapi.co/$ip/json/" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$info" ]; then
            local error=$(echo "$info" | jq -r '.error // empty')
            if [ "$error" != "true" ]; then
                service_name="ipapi.co"
            fi
        fi
    fi
    
    # 解析IP信息
    if [ -n "$service_name" ] && [ -n "$info" ]; then
        local country region city org timezone isp
        
        case "$service_name" in
            "ip-api.com")
                country=$(echo "$info" | jq -r '.country // "未知"')
                region=$(echo "$info" | jq -r '.regionName // "未知"')
                city=$(echo "$info" | jq -r '.city // "未知"')
                org=$(echo "$info" | jq -r '.org // "未知"')
                timezone=$(echo "$info" | jq -r '.timezone // "未知"')
                isp=$(echo "$info" | jq -r '.isp // "未知"')
                ;;
            "ipapi.co")
                country=$(echo "$info" | jq -r '.country_name // "未知"')
                region=$(echo "$info" | jq -r '.region // "未知"')
                city=$(echo "$info" | jq -r '.city // "未知"')
                org=$(echo "$info" | jq -r '.org // "未知"')
                timezone=$(echo "$info" | jq -r '.timezone // "未知"')
                isp=$(echo "$info" | jq -r '.org // "未知"')
                ;;
        esac
        
        # 构建信息字符串
        local info_str="    国家/地区: $country | 城市: $city, $region | 组织: $org | 时区: $timezone (来源: $service_name)"
        if [ "$isp" != "未知" ] && [ "$isp" != "$org" ]; then
            info_str="    国家/地区: $country | 城市: $city, $region | ISP: $isp | 组织: $org | 时区: $timezone (来源: $service_name)"
        fi
        
        if [ "$USE_ASSOCIATIVE_ARRAYS" = true ]; then
            ip_info[$ip]="$info_str"
        else
            echo "$ip:$info_str" >> "$ip_info_file"
        fi
        
        echo "$info_str"
    else
        echo "    无法获取IP信息 (所有服务均失败)"
    fi
}

# 增加IP计数的函数
increment_ip_count() {
    local ip="$1"
    if [ "$USE_ASSOCIATIVE_ARRAYS" = true ]; then
        if [ -z "${ip_count[$ip]}" ]; then
            ip_count[$ip]=1
        else
            ip_count[$ip]=$((ip_count[$ip] + 1))
        fi
    else
        echo "$ip" >> "$ip_list_file"
    fi
}

# 提示用户输入代理列表
echo "请粘贴代理列表，完成后按Ctrl+D："
cat > "$temp_file"

{
    echo "开始测试代理..."
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "运行环境: $ENV (Bash版本: ${BASH_VERSION})"
    if [ "$USE_ASSOCIATIVE_ARRAYS" = false ]; then
        echo "注意: 使用兼容模式 (建议升级到 Bash 4.0+ 以获得更好性能)"
    fi
    echo "----------------------------------------"

    # 计数器
    total_count=0
    success_count=0

    while IFS= read -r line; do
        # 跳过空行
        [ -z "$line" ] && continue
        
        total_count=$((total_count + 1))
        
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
            success_count=$((success_count + 1))
            increment_ip_count "$result"
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
    if [ "$USE_ASSOCIATIVE_ARRAYS" = true ]; then
        # 使用关联数组
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
    else
        # 使用文件统计
        if [ -f "$ip_list_file" ] && [ -s "$ip_list_file" ]; then
            sort "$ip_list_file" | uniq -c | while read count ip; do
                echo "IP: $ip 出现 $count 次"
                if [ "$count" -gt 1 ]; then
                    echo "⚠️ 警告：IP $ip 重复使用了 $count 次"
                fi
                echo "详细信息:"
                get_ip_info "$ip"
                echo "----------------------------------------"
            done
        fi
    fi

    echo -e "\n测试完成!"
} | tee "$output_file"

# 清理临时文件
rm -f "$temp_file"
if [ "$USE_ASSOCIATIVE_ARRAYS" = false ]; then
    rm -f "$ip_list_file" "$ip_info_file"
fi

echo "详细结果已保存到: $output_file"
