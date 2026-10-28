# GitHub API Rate Limit Monitoring

## 概述

在 CI/CD 工作流中自动监控和显示 GitHub API 速率限制信息，帮助及时发现和预防 API 配额耗尽问题。

## 功能特性

### 📊 自动监控

- **自动检测**: 自动检测 `GITHUB_TOKEN` 和 `WORKFLOW_SECRET`
- **实时查询**: 通过 GitHub API 获取最新的速率限制信息
- **智能警告**: 当剩余请求数 < 100 时显示警告标识

### 📈 显示信息

每个 token 显示以下信息：

| 字段 | 说明 | 示例 |
|------|------|------|
| Token | Token 名称 | GITHUB_TOKEN |
| Limit | 总限制数 | 5000 |
| Remaining | 剩余请求数 | 4996 |
| Used | 已使用数 | 4 |
| Usage % | 使用百分比 | 0% |
| Reset Time | 重置时间 (UTC) | 2026-04-24 13:01:58 UTC |

### 🔔 警告机制

当剩余请求数低于 100 时，会在 token 名称前显示 ⚠️ 警告标识：

```markdown
| ⚠️ GITHUB_TOKEN | 5000 | 95 | 4905 | 98% | 2026-04-24 14:00:00 UTC |
```

## 使用方法

### 自动集成

以下脚本已自动集成 API 速率限制监控：

- `scripts/setup.sh` - 环境设置
- `scripts/update.sh` - 工具更新
- `scripts/audit.sh` - 安全审计

无需额外配置，运行这些脚本时会自动在 CI Summary 中显示 API 信息。

### 手动调用

如果需要在其他脚本中使用，可以手动集成：

```bash
#!/usr/bin/env sh

# 加载库
SCRIPT_DIR=$(cd "$(dirname "${0}")" && pwd)
. "${SCRIPT_DIR}/lib/github-api-info.sh"

# 在脚本结束时添加 API 信息
append_github_api_info
```

### 独立测试

运行测试脚本验证功能：

```bash
sh scripts/test-github-api-info.sh
```

## 示例输出

### CI Summary 中的显示

```markdown
### 🔑 GitHub API Rate Limit Status

| Token | Limit | Remaining | Used | Usage % | Reset Time (UTC) |
| :--- | ---: | ---: | ---: | ---: | :--- |
| GITHUB_TOKEN | 5000 | 4996 | 4 | 0% | 2026-04-24 13:01:58 UTC |
| WORKFLOW_SECRET | 5000 | 4850 | 150 | 3% | 2026-04-24 13:15:30 UTC |

> 📊 Rate limits are per token and reset hourly. [Learn more](https://docs.github.com/en/rest/rate-limit)
```

### 测试脚本输出

```
🧪 Testing GitHub API Info Functions
--------------------------------------

Test 1: Checking GITHUB_TOKEN availability...
✅ GITHUB_TOKEN is set

Test 2: Fetching rate limit...
✅ Successfully fetched rate limit

Test 3: Parsing rate limit...
✅ Parsed info: 5000|4996|4|0%|2026-04-24 13:01:58 UTC

Formatted output:
  Limit: 5000
  Remaining: 4996
  Used: 4
  Usage: 0%
  Reset Time: 2026-04-24 13:01:58 UTC

Test 4: Generating summary table...
✅ Summary generated successfully

✨ Tests complete!
```

## API 函数

### `get_github_rate_limit(token_name, token_value)`

获取指定 token 的速率限制信息。

**参数:**

- `token_name`: Token 名称（用于显示）
- `token_value`: Token 值

**返回:** JSON 格式的速率限制信息

### `parse_rate_limit(json_response)`

解析 GitHub API 返回的 JSON 数据。

**参数:**

- `json_response`: API 返回的 JSON 字符串

**返回:** 格式化的速率限制信息（管道分隔）

```
limit|remaining|used|percentage%|reset_time
```

### `generate_github_api_summary()`

生成 Markdown 格式的速率限制表格并写入 `CI_STEP_SUMMARY`。

### `append_github_api_info()`

便捷函数，在脚本结束时调用以添加 API 信息到 summary。

## 技术细节

### POSIX 兼容

- 使用标准 POSIX shell 语法
- 兼容 sh、bash、dash 等
- 无需额外依赖

### JSON 解析

使用 `grep` 和 `sed` 进行 POSIX 兼容的 JSON 解析：

```bash
_limit=$(echo "${_json}" | grep -o '"limit": *[0-9]*' | grep -o '[0-9]*')
```

### 时间格式化

自动检测平台并使用合适的 `date` 命令：

```bash
# macOS
date -r "${timestamp}" "+%Y-%m-%d %H:%M:%S UTC"

# Linux
date -d "@${timestamp}" "+%Y-%m-%d %H:%M:%S UTC"
```

## 速率限制说明

### GitHub API 限制

| Token 类型 | 限制 | 重置周期 |
|-----------|------|---------|
| GITHUB_TOKEN (Actions) | 1000/小时 | 每小时 |
| Personal Access Token | 5000/小时 | 每小时 |
| GitHub App | 5000/小时 | 每小时 |

### 最佳实践

1. **监控使用情况**: 定期检查 CI Summary 中的 API 使用情况
2. **优化请求**: 减少不必要的 API 调用
3. **使用缓存**: 缓存 API 响应以减少请求
4. **错误处理**: 当接近限制时实施退避策略

### 常见问题

**Q: 为什么显示 N/A？**

A: 可能的原因：

- Token 未设置或无效
- 网络连接问题
- API 响应格式变化

**Q: 如何增加速率限制？**

A:

- 使用 Personal Access Token 而不是 GITHUB_TOKEN
- 使用 GitHub App 认证
- 联系 GitHub 支持申请更高限制

**Q: 速率限制何时重置？**

A: 每小时重置一次，具体时间显示在 "Reset Time" 列中。

## 相关资源

- [GitHub REST API - Rate Limits](https://docs.github.com/en/rest/rate-limit)
- [GitHub Actions - Rate Limits](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration)
- [Best Practices for API Usage](https://docs.github.com/en/rest/guides/best-practices-for-integrators)

## 更新日志

### v1.0.0 (2026-04-24)

- ✨ 初始版本
- ✅ 支持 GITHUB_TOKEN 和 WORKFLOW_SECRET
- ✅ 自动警告机制
- ✅ POSIX 兼容实现
- ✅ 集成到主要工作流脚本
