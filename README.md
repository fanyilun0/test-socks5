# SOCKS5 代理测试工具

这是一个用于测试SOCKS5代理可用性的Shell脚本。它可以批量测试多个代理，并提供详细的IP地理位置信息和统计数据。支持macOS和Linux环境，具有多服务IP查询备选机制。

## 功能特点

- 🚀 批量测试多个SOCKS5代理
- ✅ 自动检测代理是否可用
- 🌍 显示代理IP的详细地理位置信息
- 🔄 多服务IP查询备选机制（ip-api.com、ipapi.co）
- 📊 检测重复IP使用情况
- 📈 提供测试统计数据
- 💾 自动保存测试结果到文件
- 🖥️ 跨平台兼容（macOS/Linux）
- 🛡️ 智能错误处理和重试机制

## 依赖要求

- curl：用于进行HTTP请求
- jq：用于解析JSON数据
- bash：Shell环境（建议bash 4.0+）

### 安装依赖

**macOS:**
```bash
brew install curl jq
```

**Debian/Ubuntu:**
```bash
sudo apt-get install curl jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl jq
```


## 使用方法

### 基本使用

1. 下载脚本并添加执行权限：
   ```bash
   chmod +x test-socks5.sh
   ```

2. 运行脚本：
   ```bash
   ./test-socks5.sh
   ```

3. 在提示处粘贴代理列表，格式如下：
   ```
   socks5://127.0.0.1:8001
   socks5://127.0.0.1:8011
   127.0.0.1:8021
   username:password@host:port
   ```

4. 按 `Ctrl+D` 开始测试

## 输出说明

脚本会输出以下信息：
- 每个代理的测试结果
- 代理IP的地理位置信息（包含数据来源）
- 成功/失败统计
- IP重复使用警告
- 详细的测试报告（保存在文件中）

## 输出示例

```
开始测试代理...
测试时间: 2025-07-07 17:49:37
运行环境: macOS (Bash版本: 3.2.57(1)-release)
注意: 使用兼容模式 (建议升级到 Bash 4.0+ 以获得更好性能)
----------------------------------------
测试代理: socks5://127.0.0.1:8001
✅ 成功! 返回IP: 2.59.61.201
IP详细信息:
    国家/地区: United Kingdom | 城市: Poplar, England | 组织: Catixs Ltd | 时区: Europe/London (来源: ip-api.com)
----------------------------------------

统计信息：
总测试代理数: 1
成功数: 1
失败数: 0
成功率: 100%

IP使用情况：
IP: 2.59.61.201 出现 1 次
详细信息:
    国家/地区: United Kingdom | 城市: Poplar, England | 组织: Catixs Ltd | 时区: Europe/London (来源: ip-api.com)
----------------------------------------

测试完成!
详细结果已保存到: proxy_test_results_20250707_174937.txt
```

## 注意事项

1. 脚本会自动为没有`socks5://`前缀的代理地址添加前缀
2. 每次测试之间有1秒延迟，以避免请求过快
3. 测试结果会自动保存到当前目录下的文件中
4. 文件名格式：`proxy_test_results_YYYYMMDD_HHMMSS.txt`
5. 脚本支持macOS和Linux环境，自动检测并使用兼容模式
6. IP查询服务按优先级自动选择，确保数据获取的可靠性

## 错误处理

- 如果缺少jq，脚本会提示安装（包含对应系统的安装命令）
- 代理测试失败会显示curl的退出码
- 无效的代理格式会导致测试失败
- IP查询失败时会自动尝试其他服务
- 网络超时和错误会自动重试

## 隐私说明

- 脚本使用多个IP查询服务获取地理位置信息：
  - ip-api.com（免费服务）
  - ipapi.co（免费服务）
- 所有测试数据仅保存在本地文件中
- 临时文件在测试完成后会自动删除
- 不会向第三方服务发送敏感信息

## 兼容性

- **macOS**: 完全支持，自动检测并使用兼容模式
- **Linux**: 完全支持，建议使用bash 4.0+
- **Windows**: 可通过WSL或Git Bash运行

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

## 更新日志

### v2.0.0
- ✨ 新增多服务IP查询备选机制
- 🖥️ 增强macOS兼容性
- 🛡️ 改进错误处理和重试机制
- 📊 优化输出格式和统计信息

### v1.0.0
- 🚀 初始版本发布
- ✅ 基本SOCKS5代理测试功能
- 🌍 IP地理位置信息查询

## 作者
:octocat: [fanyilun0](http://github.com/fanyilun0)  
🐦 [fanyilun0](http://x.com/fanyilun0)

## IP 查询服务优先级

1. **ip-api.com** - 免费，无限制，响应快
2. **ipapi.co** - 免费但有请求限制

## 获取 ipinfo.io API Token

1. 访问 [ipinfo.io](https://ipinfo.io)
2. 注册账户并登录
3. 在开发者页面获取 API Token
4. 将 token 添加到 `.env` 文件中

## 故障排除

### IP 信息显示"未知"
- 检查网络连接
- 确认 jq 已正确安装
- 如果使用 token，确认 token 有效

### 脚本运行缓慢
- 这是正常现象，脚本在请求间添加了延迟以避免被服务商限制
- 可以修改脚本中的 `sleep 1` 来调整延迟时间

### 兼容性问题
- 脚本已针对 macOS 和 Linux 进行了优化
- 如果遇到问题，请检查 bash 版本：`bash --version`
