# Walkthrough: UniRTM GPG Security Hardening

## 概览

本次任务为 UniRTM 构建了从“原子下载”到“指纹锁定”的全链路安全加固体系。

## 关键变更

### 1. 安全校验逻辑

在 `internal/service/installation.go` 中，我们插入了 GPG 校验点。

```go
// 流程：下载资产 -> 校验哈希 -> 下载签名 -> GPG 校验 (指纹匹配)
err := im.gpgVerifier.Verify(ctx, sigPath, downloadPath, versionInfo.GPGKeys)
```

### 2. 交互式 Key 管理

支持 TTY 环境下的动态导入：
> When you install a tool using GPG verification, you will see a prompt similar to this asking you whether you want to trust the key:
>
> `Do you want to trust and import GPG key 0123456789ABCDEF for author@example.com? [y/N]`
*注：UniRTM 会从 keys.openpgp.org 等主流服务器自动拉取 Key。*

### 3. CI/CD 兼容性 (Lockfile Pinning)

`unirtm.lock` 现在具备了安全记忆功能：

```toml
[[tools."node"]]
version = "22.14.0"
backend = "native"

[tools."node"."platforms.darwin-arm64"]
checksum = "sha256:..."
url = "..."
gpg_key = "C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8" # 自动锁定的指纹
```

## 测试验证

- [x] **正常安装**：Node.js 安装过程中自动发现签名并提示导入。
- [x] **指纹伪造**：修改 Registry 指纹，系统正确拦截并提示 `gpg security violation`。
- [x] **Strict 模式**：在无签名的情况下，`strict` 模式成功拦截安装。
- [x] **CI 模式**：在非 TTY 环境下，依赖 `unirtm.lock` 记录的指纹实现零交互通过。

## 结论

UniRTM 现在具备了与 Homebrew/mise 等顶级工具同级别的安全防护能力，能够有效抵御投毒攻击与供应链安全风险。
