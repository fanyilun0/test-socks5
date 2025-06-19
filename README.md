# 代理测试脚本

这是一个用于测试HTTP和SOCKS5代理可用性的Shell脚本套件。它可以批量测试多个代理，并提供详细的IP地理位置信息、风险评分和统计数据。

## 功能特点

- 批量测试多个HTTP和SOCKS5代理
- 自动检测代理是否可用
- 显示代理IP的详细地理位置信息
- **IP风险评分** - 使用IPQualityScore API进行风险评估
- **代理检测** - 识别VPN、代理服务器、TOR网络
- **表格化输出** - 清晰的表格格式显示测试结果
- 检测重复IP使用情况
- 提供测试统计数据
- 自动保存测试结果到文件
- **模块化设计** - 配置文件和功能库分离

## 依赖要求

- curl：用于进行HTTP请求
- jq：用于解析JSON数据
- bash：Shell环境

### 安装依赖

Debian/Ubuntu:

`sudo apt-get install curl jq`

CentOS/RHEL:

`sudo yum install curl jq`

## IPQualityScore API 配置（可选）

为了获得IP风险评分和高级检测功能，可以配置IPQualityScore API：

### 获取 API 密钥

1. 访问 [IPQualityScore 官网](https://www.ipqualityscore.com/)
2. 注册免费账户
3. 登录后进入 Dashboard
4. 在 "API Keys" 部分复制你的 API 密钥

### 配置脚本

编辑 `config.sh` 文件，找到以下行：

```bash
IPQS_API_KEY=""
```

将其替换为：

```bash
IPQS_API_KEY="你的实际API密钥"
```

### 免费配额

- 免费账户每月提供 5,000 次API调用
- 对于代理测试来说通常足够使用

### 启用后的功能

启用 IPQS API 后，脚本将为每个检测到的IP提供：

- **欺诈/风险评分**: 0-100分，越高风险越大
- **IP类型识别**: 住宅IP、数据中心IP、移动IP、企业IP
- **代理检测**: VPN、代理服务器、TOR网络检测
- **ISP信息**: 互联网服务提供商信息
- **地理信息**: 更准确的位置信息

## 使用方法

1. 下载脚本并添加执行权限：
  `chmod +x test-http.sh test-socks5.sh`
2. （可选）配置API密钥以启用高级功能：
  `nano config.sh`
3. 测试HTTP代理：
  `./test-http.sh`
4. 测试SOCKS5代理：
  `./test-socks5.sh`
5. 在提示处粘贴代理列表，格式如下：
  - HTTP代理：`username:password@host:port` 或 `http://username:password@host:port`
  - SOCKS5代理：`username:password@host:port` 或 `socks5://username:password@host:port`
6. 按 Ctrl+D 开始测试

## 输出说明

脚本会输出以下信息：
- **表格格式的测试结果** - 包含代理地址、状态、返回IP、地理信息、风险评分等
- 每个代理的详细测试结果
- 代理IP的地理位置信息
- IP风险评分和检测结果（如已配置API）
- 成功/失败统计
- IP重复使用统计表格
- 详细的测试报告（保存在文件中）

## 输出示例

### 表格格式输出
```
==========================================
           HTTP 代理测试结果表格
==========================================

序号 代理地址                   状态     返回IP          国家     城市         风险评分 标记 组织                
--------------------------------------------------------------------------------------------------------
1   proxy1.example.com:8080   ✅ 成功  212.107.33.196  NL       Amsterdam    85       VP   LeaseWeb Netherlands
2   proxy2.example.com:3128   ❌ 失败  -               未知     未知         未知     -    未知                
--------------------------------------------------------------------------------------------------------

统计信息:
  总测试数: 2
  成功数: 1
  失败数: 1
  成功率: 50%
  唯一IP数: 1

标记说明: V=VPN, P=代理, T=TOR
风险评分: 0-24(安全), 25-49(低风险), 50-69(中风险), 70-84(高风险), 85+(极高风险)
```

### 详细信息输出
```
测试代理: http://user:pass@host:port
✅ 成功! 返回IP: 212.107.30.196
IP详细信息:
    [基本信息] 国家/地区: NL | 城市: Amsterdam, North Holland | 组织: AS60781 LeaseWeb Netherlands B.V. | 时区: Europe/Amsterdam
    [风险评分] 欺诈评分: 85/100 (极高风险) | 位置: Amsterdam, North Holland (NL) | 类型: 数据中心IP | 检测: VPN 代理 | ISP: LeaseWeb Netherlands B.V.
```

## 配置说明

### config.sh 配置选项

```bash
# IPQualityScore API密钥
IPQS_API_KEY=""

# 其他配置选项
REQUEST_TIMEOUT=10          # 请求超时时间（秒）
REQUEST_DELAY=1             # 请求间隔（秒）
ENABLE_RISK_SCORING=true    # 是否启用风险评分
ENABLE_GEO_INFO=true        # 是否启用地理信息查询
```

## 文件说明

- `test-http.sh` - HTTP代理测试脚本
- `test-socks5.sh` - SOCKS5代理测试脚本
- `config.sh` - 配置文件（需要手动创建）
- `ip_detection.sh` - IP检测功能库
- `table_output.sh` - 表格输出功能库

## 注意事项

1. 脚本会自动为没有协议前缀的代理地址添加相应前缀
2. 每次测试之间有可配置的延迟，以避免请求过快
3. 测试结果会自动保存到当前目录下的文件中
4. 文件名格式：`http_proxy_test_results_YYYYMMDD_HHMMSS.txt` 或 `socks5_proxy_test_results_YYYYMMDD_HHMMSS.txt`
5. 未配置API密钥时，仍可使用基本功能（地理信息查询）

## 错误处理

- 如果缺少jq，脚本会提示安装
- 代理测试失败会显示curl的退出码
- 无效的代理格式会导致测试失败
- API配置错误会自动降级到基本功能

## 隐私说明

- 脚本使用ipinfo.io API获取基本IP地理位置信息
- 如配置，使用IPQualityScore API获取风险评分
- 所有测试数据仅保存在本地文件中
- 临时文件在测试完成后会自动删除

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

## 作者
:octocat: [fanyilun0](http://github.com/fanyilun0)  
🐦 [fanyilun0](http://x.com/fanyilun0)
