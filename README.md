# 看广告复活 · AdRevive

《影之刃零》Windows Steam 版 MOD 看满30秒广告,或者点击充值VIP跳过广告按钮(假的,不用真充值)即可立即复活

## 下载与安装

在 GitHub Releases 或 Nexus Mods 的 Files 中按下表选一份。安装时复制压缩包中的 `platform` 文件夹。

| 你的游戏目录 | 下载文件 |
| --- | --- |
| 首次安装 UE4SS | `AdRevive-0.14.1-with-UE4SS.zip`（内含适配 PBZ 的 UE4SS 4.0.0） |
| 已装适配 PBZ 的 UE4SS 4.0.0，或已有其他 UE4SS MOD | `AdRevive-0.14.1-mod-only.zip` |

1. 退出游戏并解压 ZIP。在 Steam 库里右键《影之刃零》，选择「管理 → 浏览本地文件」。
2. 将解压出的 `platform` 文件夹复制到游戏根目录，与原有的 `platform` 合并。安装后应能找到 `platform/steam/ue4ss/Mods/AdRevive/Scripts/main.lua`。
3. 从 Steam 正常启动游戏。在 `platform/steam/ue4ss/UE4SS.log` 中找到本次启动的 `[AdRevive] loaded v0.14.1` 就表示已加载。

首次加载 MOD 时，会自动在 `platform/steam/ue4ss/Mods/AdRevive/Save` 创建小游戏存档。从 v0.14.0 升级后，小游戏从新一局开始。

手动卸载时，先退出游戏。如需保留小游戏进度，先备份 MOD 目录中的 `Save` 文件夹，再移除 `platform/steam/ue4ss/Mods/AdRevive`。这会保留共享的 UE4SS 和游戏本体存档。若最初使用了含加载器包，想一并卸掉它，可以用源码仓库里的 `Install.ps1 -GameRoot '游戏根目录' -Uninstall` 按清单清理。

## 独立试玩

从 GitHub 下载并解压源码，双击 `ADgame/dist/index.html` 即可离线试玩，也可以用 Node.js 运行开发版。浏览器进度和 MOD 进度分别保存。[小游戏操作与构建说明](ADgame/README.md)

## 从源码构建

仓库包含可运行的 Lua 脚本、原生贴图以及浏览器单文件。修改小游戏规则后，在 Windows 上运行以下命令同步构建。构建脚本使用 Node.js、npm、uv、Go 以及 Windows 楷体生成 Lua、贴图、浏览器版和旧版存档迁移工具。

```powershell
.\Ad\build.ps1
```

生成两份发布 ZIP 需要 Windows 和 Python 3.9 或更高版本。在仓库根目录运行以下命令。脚本在临时目录组装文件，自动下载并校验指定版本的 UE4SS，输出到 `dist/`。已有原版加载器 ZIP 时可追加 `--loader-archive 文件路径` 离线打包。

```powershell
python tools/package_release.py
```

在仓库根目录用 Lua 5.4 运行 `tests/*_spec.lua` 可验证复生入口、视口和存档等逻辑。安装器的独立检查为 `tests/installer_stage_spec.ps1`。

## 素材与依赖

角色、武器的美术素材取自《影之刃零》BWIKI 图鉴。[图鉴来源](https://wiki.biligame.com/yingzhiren/)

UE4SS 来自 KintaroModding 的 PBZ 适配版，完整包附带上游 LICENSE。小游戏与工具的开源依赖声明见 [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt)。[UE4SS 上游版本](https://github.com/KintaroModding/ue4ss/releases/tag/v4.0.0)
