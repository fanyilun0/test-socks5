#!/bin/bash

# 表格输出功能库
# 用于格式化输出测试结果为表格形式

# 加载IP检测库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ip_detection.sh"

# 打印表格头部
print_table_header() {
    local proxy_type="$1"  # "HTTP" 或 "SOCKS5"
    
    echo ""
    echo "=========================================="
    echo "           $proxy_type 代理测试结果表格"
    echo "=========================================="
    echo ""
    
    # 表格头部
    printf "%-3s %-25s %-8s %-15s %-8s %-12s %-8s %-6s %-20s\n" \
        "序号" "代理地址" "状态" "返回IP" "国家" "城市" "风险评分" "标记" "组织"
    echo "--------------------------------------------------------------------------------------------------------"
}

# 打印表格行
print_table_row() {
    local index="$1"
    local proxy="$2"
    local status="$3"
    local ip="$4"
    local ip_summary="$5"  # 格式: country|city|org|fraud_score|flags
    
    # 解析IP摘要信息
    local country city org fraud_score flags
    if [ -n "$ip_summary" ]; then
        IFS='|' read -r country city org fraud_score flags <<< "$ip_summary"
    else
        country="未知"
        city="未知"
        org="未知"
        fraud_score="未知"
        flags=""
    fi
    
    # 截断过长的字段
    proxy="${proxy:0:23}"
    ip="${ip:0:13}"
    country="${country:0:6}"
    city="${city:0:10}"
    org="${org:0:18}"
    fraud_score="${fraud_score:0:6}"
    flags="${flags:0:4}"
    
    # 状态显示
    local status_display
    if [ "$status" = "成功" ]; then
        status_display="✅ 成功"
    else
        status_display="❌ 失败"
    fi
    
    printf "%-3s %-25s %-8s %-15s %-8s %-12s %-8s %-6s %-20s\n" \
        "$index" "$proxy" "$status_display" "$ip" "$country" "$city" "$fraud_score" "$flags" "$org"
}

# 打印表格底部统计信息
print_table_footer() {
    local total="$1"
    local success="$2"
    local unique_ips="$3"
    
    echo "--------------------------------------------------------------------------------------------------------"
    echo ""
    echo "统计信息:"
    echo "  总测试数: $total"
    echo "  成功数: $success"
    echo "  失败数: $((total - success))"
    if [ "$total" -gt 0 ]; then
        echo "  成功率: $(( (success * 100) / total ))%"
    fi
    echo "  唯一IP数: $unique_ips"
    echo ""
    echo "标记说明: V=VPN, P=代理, T=TOR"
    echo "风险评分: 0-24(安全), 25-49(低风险), 50-69(中风险), 70-84(高风险), 85+(极高风险)"
}

# 打印IP重复使用表格
print_ip_usage_table() {
    local ip_usage_file="$1"
    
    if [ ! -f "$ip_usage_file" ] || [ ! -s "$ip_usage_file" ]; then
        return
    fi
    
    echo ""
    echo "========================================"
    echo "            IP使用情况统计"
    echo "========================================"
    echo ""
    
    printf "%-15s %-6s %-8s %-12s %-8s %-6s %-20s\n" \
        "IP地址" "次数" "国家" "城市" "风险评分" "标记" "组织"
    echo "--------------------------------------------------------------------------------"
    
    while IFS='|' read -r ip count; do
        # 获取IP摘要信息
        local ip_summary
        ip_summary=$(get_ip_summary "$ip")
        
        # 解析信息
        local country city org fraud_score flags
        IFS='|' read -r country city org fraud_score flags <<< "$ip_summary"
        
        # 截断过长的字段
        ip="${ip:0:13}"
        count="${count:0:4}"
        country="${country:0:6}"
        city="${city:0:10}"
        org="${org:0:18}"
        fraud_score="${fraud_score:0:6}"
        flags="${flags:0:4}"
        
        printf "%-15s %-6s %-8s %-12s %-8s %-6s %-20s\n" \
            "$ip" "$count" "$country" "$city" "$fraud_score" "$flags" "$org"
        
        # 添加延迟避免API请求过快
        sleep 0.5
    done < "$ip_usage_file"
    
    echo "--------------------------------------------------------------------------------"
} 