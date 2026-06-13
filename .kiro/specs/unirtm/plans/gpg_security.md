# UniRTM GPG 签名校验与安全增强规范 (Draft)

## 1. 核心目标

构建工业级的工具安装安全防线，确保 UniRTM 下载的任何二进制文件都具备**来源可信性（Authenticity）**与**内容完整性（Integrity）**，同时兼顾开发环境的交互体验与 CI/CD 环境的自动化需求。

## 2. GPG 校验流程

### 2.1 签名文件获取

- **自动定位**：UniRTM 会根据工具类型自动寻找 `.asc`, `.sig` 或包含签名的 `SHASUMS256.txt.asc`。
- **并行下载**：签名文件与安装包并行下载，使用同样的原子下载机制（`.tmp` 随机后缀 + `0600` 权限）。

### 2.2 信任链管理 [DONE]

- **三级信任模型**：
    1. **内置（Bundled）**：UniRTM 官方 Registry 内置主流工具（Node, Go, Python 等）的公钥指纹。 [DONE]
    2. **显式（Explicit）**：用户在 `unirtm.yaml` 中配置的 `gpg_keys`。 [DONE]
    3. **动态（Dynamic）**：通过交互式确认后存入本地信任库的 Key。 [DONE]

### 2.3 校验逻辑

- 在解压前，UniRTM 调用 `gpg` (或内置库) 执行：`gpg --verify <sig_file> <data_file>`。
- **Strict Mode**：若校验失败或签名缺失，**强制中断**安装并清理临时文件。

## 3. CI/CD 兼容性方案 (Non-Interactive)

### 3.1 锁文件指纹锁定 (Lockfile Pinning)

- **原理**：`unirtm.lock` 将新增 `gpg_fingerprint` 字段。
- **GPG 引擎优化**：识别 `NO_PUBKEY` 错误，实现交互式公钥导入。 [DONE]
- **智能 Shell 启用/禁用 (unirtm enable/disable)**：实现一键自动配置/撤销 Shell 激活（zsh/bash/fish），支持幂等操作。 [DONE]
- **锁定 GPG 指纹**：在 `unirtm.lock` 中持久化已验证的指纹。 [DONE]
    3. CI 环境检测到 `unirtm.lock` 中已存在指纹，直接执行静默校验，无需用户干预。

### 3.2 环境变量逃生舱

- `UNIRTM_GPG_VERIFY=strict` (默认)：校验不通过则失败。
- `UNIRTM_GPG_VERIFY=warn`：仅警告，不中断（不推荐用于生产）。
- `UNIRTM_TRUST_KEY=FP1,FP2`：预置信任指纹列表。

## 4. 其它安全增强策略

### 4.1 原子化操作 (Atomicity)

- **下载阶段**：`filename.zip.tmp.<rand>` + `0600` 权限。
- **解压阶段**：`install_dir.unirtm-tmp` + 解压完成后原子重命名。
- **防投毒**：确保校验、解压、移动全过程在受限权限下完成。

### 4.2 路径安全 (Zip Slip Protection)

- **扫描验证**：解压后立即遍历所有文件，严禁任何文件路径或软链接目标指向 `install_path` 之外。

### 4.3 审计日志 (Auditing)

- 记录每次 GPG 校验的结果、指纹 ID 及操作人员信息，存入本地 SQLite 数据库以备溯源。

## 5. 实施路线图

- **Phase 1**: 实现基础的原子下载与 Zip Slip 防护（已完成）。
- **Phase 2**: 实现 `GenericProvider` 的解压后路径校验（已完成）。
- **Phase 3**: 引入 GPG 校验核心引擎，支持 Registry 内置指纹。
- **Phase 4**: 实现 `unirtm.lock` 的指纹锁定与 CI/CD 静默模式。

---
*Created by Antigravity for SnowdreamTech Security Standards*
