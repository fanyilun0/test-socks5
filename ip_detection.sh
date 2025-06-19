#!/bin/bash

# IP检测功能库
# 包含IP信息查询、风险评分等功能

# 加载配置文件
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh" 2>/dev/null || {
    echo "警告: 无法加载配置文件 config.sh，使用默认配置"
    IPQS_API_KEY=""
    REQUEST_TIMEOUT=10
    REQUEST_DELAY=1
    ENABLE_RISK_SCORING=true
    ENABLE_GEO_INFO=true
}

# 创建临时缓存文件
ip_info_cache=$(mktemp)
risk_score_cache=$(mktemp)

# 清理缓存文件的函数
cleanup_ip_detection() {
    rm -f "$ip_info_cache" "$risk_score_cache" 2>/dev/null
}

# 注册清理函数
trap cleanup_ip_detection EXIT

# 获取基本IP信息（使用ipinfo.io）
get_basic_ip_info() {
    local ip="$1"
    local cache_key="basic_$ip"
    
    # 检查缓存
    if grep -q "^$cache_key|" "$ip_info_cache" 2>/dev/null; then
        grep "^$cache_key|" "$ip_info_cache" | cut -d'|' -f2-
        return
    fi
    
    if [ "$ENABLE_GEO_INFO" != "true" ]; then
        return
    fi
    
    # 查询IP信息
    local info
    info=$(curl -s -m "$REQUEST_TIMEOUT" "https://ipinfo.io/$ip/json")
    if [ $? -eq 0 ]; then
        # 确保jq已安装
        if ! command -v jq &> /dev/null; then
            echo "    [基本信息] 需要安装jq来解析JSON"
            return
        fi
        
        # 解析JSON并格式化输出
        local country region city org timezone
        country=$(echo "$info" | jq -r '.country // "未知"')
        region=$(echo "$info" | jq -r '.region // "未知"')
        city=$(echo "$info" | jq -r '.city // "未知"')
        org=$(echo "$info" | jq -r '.org // "未知"')
        timezone=$(echo "$info" | jq -r '.timezone // "未知"')
        
        # 构建信息字符串
        local info_str="    [基本信息] 国家/地区: $country | 城市: $city, $region | 组织: $org | 时区: $timezone"
        
        # 缓存结果
        echo "$cache_key|$info_str" >> "$ip_info_cache"
        echo "$info_str"
    else
        echo "    [基本信息] 无法获取IP信息"
    fi
}

# 获取IP风险评分（使用IPQualityScore）
get_ip_risk_score() {
    local ip="$1"
    local cache_key="risk_$ip"
    
    # 检查缓存
    if grep -q "^$cache_key|" "$risk_score_cache" 2>/dev/null; then
        grep "^$cache_key|" "$risk_score_cache" | cut -d'|' -f2-
        return
    fi
    
    if [ "$ENABLE_RISK_SCORING" != "true" ]; then
        return
    fi
    
    # 检查API密钥是否配置
    if [ -z "$IPQS_API_KEY" ] || [ "$IPQS_API_KEY" = "YOUR_API_KEY_HERE" ]; then
        echo "    [风险评分] 未配置IPQS API密钥，跳过风险评分"
        return
    fi
    
    # 调用IPQualityScore API
    local risk_info
    risk_info=$(curl -s -m "$REQUEST_TIMEOUT" "https://www.ipqualityscore.com/api/json/ip/$IPQS_API_KEY/$ip")
    if [ $? -eq 0 ]; then
        # 确保jq已安装
        if ! command -v jq &> /dev/null; then
            echo "    [风险评分] 需要安装jq来解析JSON"
            return
        fi
        
        # 解析关键风险信息
        local fraud_score is_vpn is_tor is_proxy connection_type isp_name
        local country_code region city organization
        
        fraud_score=$(echo "$risk_info" | jq -r '.fraud_score // "未知"')
        is_vpn=$(echo "$risk_info" | jq -r '.vpn // false')
        is_tor=$(echo "$risk_info" | jq -r '.tor // false')
        is_proxy=$(echo "$risk_info" | jq -r '.proxy // false')
        connection_type=$(echo "$risk_info" | jq -r '.connection_type // "未知"')
        isp_name=$(echo "$risk_info" | jq -r '.ISP // "未知"')
        
        # 从IPQS获取地理信息作为补充
        country_code=$(echo "$risk_info" | jq -r '.country_code // "未知"')
        region=$(echo "$risk_info" | jq -r '.region // "未知"')
        city=$(echo "$risk_info" | jq -r '.city // "未知"')
        organization=$(echo "$risk_info" | jq -r '.organization // "未知"')
        
        # 构建风险信息字符串，添加风险等级说明
        local risk_level=""
        if [ "$fraud_score" != "未知" ]; then
            if [ "$fraud_score" -ge 85 ]; then
                risk_level=" (极高风险)"
            elif [ "$fraud_score" -ge 70 ]; then
                risk_level=" (高风险)"
            elif [ "$fraud_score" -ge 50 ]; then
                risk_level=" (中等风险)"
            elif [ "$fraud_score" -ge 25 ]; then
                risk_level=" (低风险)"
            else
                risk_level=" (安全)"
            fi
        fi
        
        local risk_str="    [风险评分] 欺诈评分: $fraud_score/100$risk_level"
        
        # 添加地理信息（从IPQS）
        if [ "$country_code" != "未知" ] || [ "$city" != "未知" ]; then
            risk_str="$risk_str | 位置: $city, $region ($country_code)"
        fi
        
        # 添加IP类型信息
        if [ "$connection_type" != "未知" ] && [ "$connection_type" != "Premium required." ]; then
            case "$connection_type" in
                "Residential") risk_str="$risk_str | 类型: 住宅IP" ;;
                "Corporate") risk_str="$risk_str | 类型: 企业IP" ;;
                "Data Center") risk_str="$risk_str | 类型: 数据中心IP" ;;
                "Mobile") risk_str="$risk_str | 类型: 移动IP" ;;
                *) risk_str="$risk_str | 类型: $connection_type" ;;
            esac
        else
            # 免费版限制时，根据其他指标推断类型
            if [ "$is_proxy" = "true" ] || [ "$is_vpn" = "true" ]; then
                risk_str="$risk_str | 类型: 代理/VPN服务器"
            fi
        fi
        
        # 添加代理/VPN检测结果
        if [ "$is_vpn" = "true" ] || [ "$is_proxy" = "true" ] || [ "$is_tor" = "true" ]; then
            local detection_results=""
            [ "$is_vpn" = "true" ] && detection_results="${detection_results}VPN "
            [ "$is_proxy" = "true" ] && detection_results="${detection_results}代理 "
            [ "$is_tor" = "true" ] && detection_results="${detection_results}TOR "
            risk_str="$risk_str | 检测: $detection_results"
        else
            risk_str="$risk_str | 检测: 未发现代理特征"
        fi
        
        # 添加ISP信息
        if [ "$isp_name" != "未知" ]; then
            risk_str="$risk_str | ISP: $isp_name"
        fi
        
        # 缓存结果
        echo "$cache_key|$risk_str" >> "$risk_score_cache"
        echo "$risk_str"
    else
        echo "    [风险评分] 无法获取IP风险信息"
    fi
}

# 获取IP的简化信息用于表格显示
get_ip_summary() {
    local ip="$1"
    local summary=""
    
    # 获取基本信息
    if [ "$ENABLE_GEO_INFO" = "true" ]; then
        local info
        info=$(curl -s -m "$REQUEST_TIMEOUT" "https://ipinfo.io/$ip/json")
        if [ $? -eq 0 ] && command -v jq &> /dev/null; then
            local country city org
            country=$(echo "$info" | jq -r '.country // "未知"')
            city=$(echo "$info" | jq -r '.city // "未知"')
            org=$(echo "$info" | jq -r '.org // "未知"')
            summary="$country|$city|$org"
        else
            summary="未知|未知|未知"
        fi
    else
        summary="未知|未知|未知"
    fi
    
    # 获取风险评分
    if [ "$ENABLE_RISK_SCORING" = "true" ] && [ -n "$IPQS_API_KEY" ] && [ "$IPQS_API_KEY" != "YOUR_API_KEY_HERE" ]; then
        local risk_info
        risk_info=$(curl -s -m "$REQUEST_TIMEOUT" "https://www.ipqualityscore.com/api/json/ip/$IPQS_API_KEY/$ip")
        if [ $? -eq 0 ] && command -v jq &> /dev/null; then
            local fraud_score is_vpn is_proxy is_tor
            fraud_score=$(echo "$risk_info" | jq -r '.fraud_score // "未知"')
            is_vpn=$(echo "$risk_info" | jq -r '.vpn // false')
            is_proxy=$(echo "$risk_info" | jq -r '.proxy // false')
            is_tor=$(echo "$risk_info" | jq -r '.tor // false')
            
            local risk_flags=""
            [ "$is_vpn" = "true" ] && risk_flags="${risk_flags}V"
            [ "$is_proxy" = "true" ] && risk_flags="${risk_flags}P"
            [ "$is_tor" = "true" ] && risk_flags="${risk_flags}T"
            
            summary="$summary|$fraud_score|$risk_flags"
        else
            summary="$summary|未知|"
        fi
    else
        summary="$summary|未知|"
    fi
    
    echo "$summary"
} 