# Changelog

## [0.70.0](https://github.com/snowdreamtech/frp/compare/rocky-v0.69.1...rocky-v0.70.0) (2026-07-16)


### 🚀 Features

* add fallback logic to fetch dev commit if VERSION is not semver ([3f8a0b6](https://github.com/snowdreamtech/frp/commit/3f8a0b6b34f05f4890a97552bc3fec4d9b0c9de9))
* implement multi-stage builds for frpc and frps ([3012ab8](https://github.com/snowdreamtech/frp/commit/3012ab8d422be016b2f527e89fa58ec7fe447e76))
* upgrade frp to 0.70.0 ([b348caa](https://github.com/snowdreamtech/frp/commit/b348caaa0f7a838d984954442bb8d9e64c8c9c70))


### 🐛 Bug Fixes

* add release-please block annotations to FRP_VERSION arguments in Dockerfiles ([c9666cc](https://github.com/snowdreamtech/frp/commit/c9666cc14d28317e5f2339a9252f48ea1a11bad8))
* make entrypoint scripts executable ([652628d](https://github.com/snowdreamtech/frp/commit/652628d1345d36858a63d4ebdafdb8ad79b02546))
* only copy specific entrypoint script for each frp variant ([07b3db9](https://github.com/snowdreamtech/frp/commit/07b3db9f3e68a05641ac84c27ab58c20554418cd))
* use ghcr.io for base images to avoid rate limits ([9f1d73a](https://github.com/snowdreamtech/frp/commit/9f1d73a75a61f2f368f5572c4bd28f4c92ef8fd5))


### 🛠 Refactoring

* **docker:** align Dockerfiles with base image structure ([232574f](https://github.com/snowdreamtech/frp/commit/232574fed8418f8c7f257d001e951361dfa467a0))
* remove redundant docker-entrypoint.sh files ([87c576b](https://github.com/snowdreamtech/frp/commit/87c576b27731ad11c5bc0ebc661e07c5a09ff1c1))
* reorganize distribution variants into docker directory ([67a8c91](https://github.com/snowdreamtech/frp/commit/67a8c911e21801bf12b3e83d02e22f3b3f59a2ba))
* simplify release-please configuration by standardizing version comments and adding VERSION file tracking ([aa7177b](https://github.com/snowdreamtech/frp/commit/aa7177bf4da742fe9e54bfac3b4ab8583a5efd8b))
* unify FRP_VERSION into ARG VERSION and decouple from release-please ([8d154cf](https://github.com/snowdreamtech/frp/commit/8d154cfef895acbcfd1c150065e34b6c7ac1d4d5))


### 📖 Documentation

* add detailed comments to entrypoint initialization scripts ([f42cbaa](https://github.com/snowdreamtech/frp/commit/f42cbaab6edfbc5c38c2a636dfd8651fea900940))
* synchronize README and reset changelogs ([89e26eb](https://github.com/snowdreamtech/frp/commit/89e26eb98d5ebce375c50942588dedb13cd96fd7))


### ♻️ Miscellaneous Chores

* add 0-git-keep.sh to prevent empty entrypoint.d directories ([ce77247](https://github.com/snowdreamtech/frp/commit/ce77247762becc1edf85ec7b57747d3f3127044a))
* add variant-specific annotations to release-please version tags in workflows, Dockerfiles, and documentation ([88d7ab6](https://github.com/snowdreamtech/frp/commit/88d7ab647a5c64801bbf2ed32c8fcc0acdc90eac))
* **deps:** bump base images to alpine 3.24.0, debian 13.5.0, rocky 10.2.0 ([1688969](https://github.com/snowdreamtech/frp/commit/168896956d2f4c7f91309c4c98ffef36ca7e8546))
* downgrade version to 0.69.1 and config release-please ([003c06c](https://github.com/snowdreamtech/frp/commit/003c06c0aac9863fb4db29c8e731529be2517267))
* merge version label into the main LABEL block ([e6f7cf4](https://github.com/snowdreamtech/frp/commit/e6f7cf434246ba9cf29642c5cce05cadeaa478f6))
* move version label right below vendor label ([de6a119](https://github.com/snowdreamtech/frp/commit/de6a119300bb0f82b73a0c4957a8f349304faf73))
* release main ([56d9cde](https://github.com/snowdreamtech/frp/commit/56d9cde88d48365c2a7c0ab52cf3576ce575f608))
* release main ([4011a21](https://github.com/snowdreamtech/frp/commit/4011a21a23395acc9545168c95ca0ec5c867e7d3))
* release main ([d52be5c](https://github.com/snowdreamtech/frp/commit/d52be5cf0c5cff45f7f72e973d62c94b48855e1b))
* release main ([f66597a](https://github.com/snowdreamtech/frp/commit/f66597a5feae95e8853f4cc730c81e93e172f6ca))
* release main ([b3a5cc9](https://github.com/snowdreamtech/frp/commit/b3a5cc9ef0a64a7bc04ed7c2acf0cca5327c5c26))
* release main ([deb8454](https://github.com/snowdreamtech/frp/commit/deb8454df7518d56939ab3851245a4cd7b03d709))
* release main ([d87cb81](https://github.com/snowdreamtech/frp/commit/d87cb815685ad9b5b43d4b9a195c68dee2fd8065))
* release main ([78328d2](https://github.com/snowdreamtech/frp/commit/78328d20bd3697d48ea90aee8d0eaa6af4ccc09c))
* release main ([b720ad5](https://github.com/snowdreamtech/frp/commit/b720ad57dd1691d8ae07dcac7d46d0bd257af3a0))
* release main ([32dd84d](https://github.com/snowdreamtech/frp/commit/32dd84de4be973395d0867b5d527d528948a35df))
* release main ([725c69f](https://github.com/snowdreamtech/frp/commit/725c69fdcc222b5b83d0690629ce213a68c586ab))
* release main ([070b694](https://github.com/snowdreamtech/frp/commit/070b694a702763b60fc6b057a81418320418cafa))
* release main ([36d1211](https://github.com/snowdreamtech/frp/commit/36d1211036847a8c6aaa01a21a1c695a47b71d45))
* release main ([9ad4f94](https://github.com/snowdreamtech/frp/commit/9ad4f9490832efdc310f2ebbd8c77f3404daf07f))
* release main ([b0684a3](https://github.com/snowdreamtech/frp/commit/b0684a32a652e83506451e6056168cfec8b9142c))
* release main ([495e18a](https://github.com/snowdreamtech/frp/commit/495e18a4babcb06a12c2f5aec9ea571d97cb32e3))
* release main ([d4a3a34](https://github.com/snowdreamtech/frp/commit/d4a3a34b00a6b9f381cd5d556749c257516b2f08))
* release main ([28d9426](https://github.com/snowdreamtech/frp/commit/28d94263f4374017274707faef7183917b689be9))
* **release:** deduplicate CHANGELOG headers ([4f07b71](https://github.com/snowdreamtech/frp/commit/4f07b71194f58ba214f1fb60ce0dc56d71c499e2))
* **release:** deduplicate CHANGELOG headers ([3068d88](https://github.com/snowdreamtech/frp/commit/3068d883bc6167773d046d3b2b0e4c479e4fee39))
* **release:** deduplicate CHANGELOG headers ([82be3d5](https://github.com/snowdreamtech/frp/commit/82be3d5576b65b7f69b1a9afb8604f2c8f0e47f7))
* **release:** deduplicate CHANGELOG headers ([64038ca](https://github.com/snowdreamtech/frp/commit/64038ca8d027ee5beee1a1c96dbd2f88b9d5a611))
* **release:** deduplicate CHANGELOG headers ([d47fb44](https://github.com/snowdreamtech/frp/commit/d47fb44cb105b368722d7d0e210a27b525f82d87))
* **release:** deduplicate CHANGELOG headers ([e795177](https://github.com/snowdreamtech/frp/commit/e79517795d98b9f8292ef956586a6dc03932d03c))
* **release:** deduplicate CHANGELOG headers ([27919e4](https://github.com/snowdreamtech/frp/commit/27919e4baf4aab5b2a2bf32a7d437b05a717c11b))
* **release:** deduplicate CHANGELOG headers ([438190d](https://github.com/snowdreamtech/frp/commit/438190d297c151c75eca4912fdc22c285d5ec1ea))
* **release:** deduplicate CHANGELOG headers ([256f043](https://github.com/snowdreamtech/frp/commit/256f04311b2344f2648ca5bcf407146f8c690258))
* **release:** deduplicate CHANGELOG headers ([d263aae](https://github.com/snowdreamtech/frp/commit/d263aae7b223103a01dd0e114430381c5d863dd7))
* **release:** deduplicate CHANGELOG headers ([133954e](https://github.com/snowdreamtech/frp/commit/133954e95cfae85cbba2fb9c1ac5acbc677ca39d))
* **release:** deduplicate CHANGELOG headers ([1d82410](https://github.com/snowdreamtech/frp/commit/1d82410d6038be22d7741f1519826f30023b0f3e))
* **release:** deduplicate CHANGELOG headers ([5e1a539](https://github.com/snowdreamtech/frp/commit/5e1a5390319933b48d20ad993714587d826c0aa7))
* **release:** deduplicate CHANGELOG headers [skip ci] ([c93827e](https://github.com/snowdreamtech/frp/commit/c93827e2900c7971ca0e8ca3af9b57024a054a99))
* **release:** implement automatic changelog deduplication step ([282c220](https://github.com/snowdreamtech/frp/commit/282c22081e1ad7a1a010a7f297d20bc7c9b416a7))
* remove leftover release-please block annotations from Dockerfile labels ([d8bd485](https://github.com/snowdreamtech/frp/commit/d8bd4857a8c3acfcc14788360432b6c9ca3be996))
* **speckit:** manual auto-commit trigger ([5f8a5a9](https://github.com/snowdreamtech/frp/commit/5f8a5a9cba5d6bd42a65eaabfecd6e18b01aeeb0))
* sync release versions to 0.70.0 ([0dddcbe](https://github.com/snowdreamtech/frp/commit/0dddcbeb1fb091071c520faf84dba6f6f48a8550))

## [0.70.0](https://github.com/snowdreamtech/frp/compare/rocky-v0.70.0...rocky-v0.70.0) (2026-07-13)


### 🚀 Features

* add fallback logic to fetch dev commit if VERSION is not semver ([3f8a0b6](https://github.com/snowdreamtech/frp/commit/3f8a0b6b34f05f4890a97552bc3fec4d9b0c9de9))
* implement multi-stage builds for frpc and frps ([3012ab8](https://github.com/snowdreamtech/frp/commit/3012ab8d422be016b2f527e89fa58ec7fe447e76))
* upgrade frp to 0.70.0 ([b348caa](https://github.com/snowdreamtech/frp/commit/b348caaa0f7a838d984954442bb8d9e64c8c9c70))


### 🐛 Bug Fixes

* add release-please block annotations to FRP_VERSION arguments in Dockerfiles ([c9666cc](https://github.com/snowdreamtech/frp/commit/c9666cc14d28317e5f2339a9252f48ea1a11bad8))
* make entrypoint scripts executable ([652628d](https://github.com/snowdreamtech/frp/commit/652628d1345d36858a63d4ebdafdb8ad79b02546))
* only copy specific entrypoint script for each frp variant ([07b3db9](https://github.com/snowdreamtech/frp/commit/07b3db9f3e68a05641ac84c27ab58c20554418cd))
* use ghcr.io for base images to avoid rate limits ([9f1d73a](https://github.com/snowdreamtech/frp/commit/9f1d73a75a61f2f368f5572c4bd28f4c92ef8fd5))


### 🛠 Refactoring

* **docker:** align Dockerfiles with base image structure ([232574f](https://github.com/snowdreamtech/frp/commit/232574fed8418f8c7f257d001e951361dfa467a0))
* remove redundant docker-entrypoint.sh files ([87c576b](https://github.com/snowdreamtech/frp/commit/87c576b27731ad11c5bc0ebc661e07c5a09ff1c1))
* reorganize distribution variants into docker directory ([67a8c91](https://github.com/snowdreamtech/frp/commit/67a8c911e21801bf12b3e83d02e22f3b3f59a2ba))
* unify FRP_VERSION into ARG VERSION and decouple from release-please ([8d154cf](https://github.com/snowdreamtech/frp/commit/8d154cfef895acbcfd1c150065e34b6c7ac1d4d5))


### 📖 Documentation

* add detailed comments to entrypoint initialization scripts ([f42cbaa](https://github.com/snowdreamtech/frp/commit/f42cbaab6edfbc5c38c2a636dfd8651fea900940))
* synchronize README and reset changelogs ([89e26eb](https://github.com/snowdreamtech/frp/commit/89e26eb98d5ebce375c50942588dedb13cd96fd7))


### ♻️ Miscellaneous Chores

* add 0-git-keep.sh to prevent empty entrypoint.d directories ([ce77247](https://github.com/snowdreamtech/frp/commit/ce77247762becc1edf85ec7b57747d3f3127044a))
* **deps:** bump base images to alpine 3.24.0, debian 13.5.0, rocky 10.2.0 ([1688969](https://github.com/snowdreamtech/frp/commit/168896956d2f4c7f91309c4c98ffef36ca7e8546))
* merge version label into the main LABEL block ([e6f7cf4](https://github.com/snowdreamtech/frp/commit/e6f7cf434246ba9cf29642c5cce05cadeaa478f6))
* move version label right below vendor label ([de6a119](https://github.com/snowdreamtech/frp/commit/de6a119300bb0f82b73a0c4957a8f349304faf73))
* release main ([4011a21](https://github.com/snowdreamtech/frp/commit/4011a21a23395acc9545168c95ca0ec5c867e7d3))
* release main ([d52be5c](https://github.com/snowdreamtech/frp/commit/d52be5cf0c5cff45f7f72e973d62c94b48855e1b))
* release main ([f66597a](https://github.com/snowdreamtech/frp/commit/f66597a5feae95e8853f4cc730c81e93e172f6ca))
* release main ([b3a5cc9](https://github.com/snowdreamtech/frp/commit/b3a5cc9ef0a64a7bc04ed7c2acf0cca5327c5c26))
* release main ([deb8454](https://github.com/snowdreamtech/frp/commit/deb8454df7518d56939ab3851245a4cd7b03d709))
* release main ([d87cb81](https://github.com/snowdreamtech/frp/commit/d87cb815685ad9b5b43d4b9a195c68dee2fd8065))
* release main ([78328d2](https://github.com/snowdreamtech/frp/commit/78328d20bd3697d48ea90aee8d0eaa6af4ccc09c))
* release main ([b720ad5](https://github.com/snowdreamtech/frp/commit/b720ad57dd1691d8ae07dcac7d46d0bd257af3a0))
* release main ([32dd84d](https://github.com/snowdreamtech/frp/commit/32dd84de4be973395d0867b5d527d528948a35df))
* release main ([725c69f](https://github.com/snowdreamtech/frp/commit/725c69fdcc222b5b83d0690629ce213a68c586ab))
* release main ([070b694](https://github.com/snowdreamtech/frp/commit/070b694a702763b60fc6b057a81418320418cafa))
* release main ([36d1211](https://github.com/snowdreamtech/frp/commit/36d1211036847a8c6aaa01a21a1c695a47b71d45))
* release main ([9ad4f94](https://github.com/snowdreamtech/frp/commit/9ad4f9490832efdc310f2ebbd8c77f3404daf07f))
* release main ([b0684a3](https://github.com/snowdreamtech/frp/commit/b0684a32a652e83506451e6056168cfec8b9142c))
* release main ([495e18a](https://github.com/snowdreamtech/frp/commit/495e18a4babcb06a12c2f5aec9ea571d97cb32e3))
* release main ([d4a3a34](https://github.com/snowdreamtech/frp/commit/d4a3a34b00a6b9f381cd5d556749c257516b2f08))
* release main ([28d9426](https://github.com/snowdreamtech/frp/commit/28d94263f4374017274707faef7183917b689be9))
* **release:** deduplicate CHANGELOG headers ([4f07b71](https://github.com/snowdreamtech/frp/commit/4f07b71194f58ba214f1fb60ce0dc56d71c499e2))
* **release:** deduplicate CHANGELOG headers ([3068d88](https://github.com/snowdreamtech/frp/commit/3068d883bc6167773d046d3b2b0e4c479e4fee39))
* **release:** deduplicate CHANGELOG headers ([82be3d5](https://github.com/snowdreamtech/frp/commit/82be3d5576b65b7f69b1a9afb8604f2c8f0e47f7))
* **release:** deduplicate CHANGELOG headers ([64038ca](https://github.com/snowdreamtech/frp/commit/64038ca8d027ee5beee1a1c96dbd2f88b9d5a611))
* **release:** deduplicate CHANGELOG headers ([d47fb44](https://github.com/snowdreamtech/frp/commit/d47fb44cb105b368722d7d0e210a27b525f82d87))
* **release:** deduplicate CHANGELOG headers ([e795177](https://github.com/snowdreamtech/frp/commit/e79517795d98b9f8292ef956586a6dc03932d03c))
* **release:** deduplicate CHANGELOG headers ([27919e4](https://github.com/snowdreamtech/frp/commit/27919e4baf4aab5b2a2bf32a7d437b05a717c11b))
* **release:** deduplicate CHANGELOG headers ([438190d](https://github.com/snowdreamtech/frp/commit/438190d297c151c75eca4912fdc22c285d5ec1ea))
* **release:** deduplicate CHANGELOG headers ([256f043](https://github.com/snowdreamtech/frp/commit/256f04311b2344f2648ca5bcf407146f8c690258))
* **release:** deduplicate CHANGELOG headers ([d263aae](https://github.com/snowdreamtech/frp/commit/d263aae7b223103a01dd0e114430381c5d863dd7))
* **release:** deduplicate CHANGELOG headers ([133954e](https://github.com/snowdreamtech/frp/commit/133954e95cfae85cbba2fb9c1ac5acbc677ca39d))
* **release:** deduplicate CHANGELOG headers ([1d82410](https://github.com/snowdreamtech/frp/commit/1d82410d6038be22d7741f1519826f30023b0f3e))
* **release:** deduplicate CHANGELOG headers ([5e1a539](https://github.com/snowdreamtech/frp/commit/5e1a5390319933b48d20ad993714587d826c0aa7))
* **release:** deduplicate CHANGELOG headers [skip ci] ([c93827e](https://github.com/snowdreamtech/frp/commit/c93827e2900c7971ca0e8ca3af9b57024a054a99))
* **release:** implement automatic changelog deduplication step ([282c220](https://github.com/snowdreamtech/frp/commit/282c22081e1ad7a1a010a7f297d20bc7c9b416a7))
* remove leftover release-please block annotations from Dockerfile labels ([d8bd485](https://github.com/snowdreamtech/frp/commit/d8bd4857a8c3acfcc14788360432b6c9ca3be996))
* **speckit:** manual auto-commit trigger ([5f8a5a9](https://github.com/snowdreamtech/frp/commit/5f8a5a9cba5d6bd42a65eaabfecd6e18b01aeeb0))

## Changelog

All notable changes to this project will be documented in this file.
