# Tasks: UniRTM GPG Security Implementation

## Phase 1: 原子化下载与权限加固 (Atomic Download & Permissions) [DONE]

- [x] 1.1 实现 `.tmp.<rand>` 临时文件下载机制
- [x] 1.2 设置下载临时文件权限为 `0600`
- [x] 1.3 实现下载完成后的原子化 `os.Rename`

## Phase 2: Zip Slip 防护与目录平铺 (Zip Slip & Flattening) [DONE]

- [x] 2.1 修复 Gradle 等原生工具的目录平铺逻辑
- [x] 2.2 实现 `validateInstallDir` 路径安全校验函数
- [x] 2.3 增加对恶意软链接（指向外部敏感文件）的拦截
- [x] 2.4 增加 `http` 协议风险警告

## Phase 3: GPG 校验核心引擎 (GPG Verification Engine) [DONE]

- [x] 3.1 集成 GPG 核心库 (Integrate GPG Core Library) [DONE]
- [x] 3.3 完善 Registry 与指纹发现 (Registry & Discovery) [DONE]
- [x] 3.4 交互式信任流程 (Interactive Trust Flow) [DONE]

## Phase 4: 锁文件与 CI/CD 增强 (Lockfile & CI/CD) [DONE]

- [x] 4.1 锁文件扩展 (Extend Lockfile) [DONE]
- [x] 4.2 环境策略控制 (Security Policy) [DONE]
- [x] 4.3 最终验收测试 (Final E2E Testing) [DONE]
