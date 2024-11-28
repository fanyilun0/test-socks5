# 代理测试脚本

这是一个用于测试SOCKS5代理可用性的Shell脚本。它可以批量测试多个代理，并提供详细的IP地理位置信息和统计数据。

## 功能特点

- 批量测试多个SOCKS5代理
- 自动检测代理是否可用
- 显示代理IP的详细地理位置信息
- 检测重复IP使用情况
- 提供测试统计数据
- 自动保存测试结果到文件

## 依赖要求

- curl：用于进行HTTP请求
- jq：用于解析JSON数据
- bash：Shell环境

### 安装依赖

Debian/Ubuntu:

`sudo apt-get install curl jq`

CentOS/RHEL:

`sudo yum install curl jq`


## 使用方法

1. 下载脚本并添加执行权限：
  `chmod +x test-socks5.sh`
2. 运行脚本：
   `./test-socks5.sh`
3. 在提示处粘贴代理列表，格式如下：
  `username:password@host:port`或`socks5://username:password@host:port`
4. 按 Ctrl+D 开始测试

## 输出说明

脚本会输出以下信息：
- 每个代理的测试结果
- 代理IP的地理位置信息
- 成功/失败统计
- IP重复使用警告
- 详细的测试报告（保存在文件中）

## 输出示例
```
测试代理: socks5://user:pass@host:port
✅ 成功! 返回IP: 220.109.48.195
IP详细信息:
国家/地区: JP | 城市: Tokyo | 组织: AS2527 Sony Network | 时区: Asia/Tokyo
----------------------------------------
统计信息：
总测试代理数: 4
成功数: 4
失败数: 0
成功率: 100%
```

## 注意事项

1. 脚本会自动为没有`socks5://`前缀的代理地址添加前缀
2. 每次测试之间有1秒延迟，以避免请求过快
3. 测试结果会自动保存到当前目录下的文件中
4. 文件名格式：proxy_test_results_YYYYMMDD_HHMMSS.txt

## 错误处理

- 如果缺少jq，脚本会提示安装
- 代理测试失败会显示curl的退出码
- 无效的代理格式会导致测试失败

## 隐私说明

- 脚本使用ipinfo.io API获取IP地理位置信息
- 所有测试数据仅保存在本地文件中
- 临时文件在测试完成后会自动删除

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

## 作者
:octocat: [fanyilun0](http://github.com/fanyilun0)  
🐦 [fanyilun0](http://x.com/fanyilun0)
