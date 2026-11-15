"""Build both manual distributions from a clean, isolated Windows installation."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]
STEAM = Path("platform/steam")
MOD = Path("ue4ss/Mods/AdRevive")


def zip_entry(archive, name, data):
    # Use portable names and fixed metadata so identical inputs give identical ZIPs.
    info = zipfile.ZipInfo(Path(name).as_posix(), (2020, 1, 1, 0, 0, 0))
    info.create_system = 3
    info.external_attr = 0o100644 << 16
    archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)


def stage(game, profile, loader):
    binary = game / STEAM
    binary.mkdir(parents=True)
    (binary / "PBZ.exe").touch()  # The installer checks the layout; no game is run.
    shell = shutil.which("pwsh") or shutil.which("powershell")
    if not shell:
        raise RuntimeError("PowerShell is required to stage the release.")
    cmd = [shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
           str(ROOT / "Install.ps1"), "-GameRoot", str(game)]
    if loader:
        cmd.extend(["-LoaderArchive", str(loader.resolve(strict=True))])
    subprocess.run(cmd, env={**os.environ, "LOCALAPPDATA": str(profile)}, check=True)
    return binary


def make_archives(temp, binary):
    receipt_name = "AdRevive.install.json"
    receipt = json.loads((binary / receipt_name).read_text(encoding="utf-8-sig"))
    version = receipt["version"]
    runtime = {}
    for entry in receipt["files"]:
        p = Path(entry["path"])
        if p.is_absolute() or p.drive or ".." in p.parts:
            raise ValueError(f"Unexpected receipt path: {p}")
        data = (binary / p).read_bytes()
        if hashlib.sha256(data).hexdigest().upper() != entry["sha256"].upper():
            raise ValueError(f"Staged file checksum mismatch: {p}")
        runtime[p] = data
    mod_files = {p: data for p, data in runtime.items() if MOD in p.parents}
    for required in ("enabled.txt", "Scripts/main.lua", "Art/ground.png"):
        if MOD / required not in mod_files:
            raise ValueError(f"Missing mod file: {required}")
    if b"loaded v" + version.encode() not in mod_files[MOD / "Scripts/main.lua"]:
        raise ValueError("Installer and Lua versions differ")
    if Path("dwmapi.dll") not in runtime or Path("ue4ss/UE4SS.dll") not in runtime:
        raise ValueError("Loader missing from clean staging directory")

    standalone = (ROOT / "ADgame/dist/index.html").read_bytes()
    notices = (ROOT / "THIRD-PARTY-NOTICES.txt").read_bytes()
    bundles = []
    for full in (True, False):
        variant = "with-UE4SS" if full else "mod-only"
        name = f"AdRevive-{version}-{variant}.zip"
        welcome = ("本包内含适配 PBZ 的 UE4SS 4.0.0，适用于首次安装。已有 UE4SS 请用 mod-only 包。"
                   if full else "本包仅含 MOD，游戏目录需要已安装适配 PBZ 的 UE4SS 4.0.0。")
        guide = (f"看广告复活 · AdRevive {version}\n\n{welcome}\n\n"
                 "1. 完全退出游戏，解压 ZIP。\n"
                 "2. 在 Steam 库右键《影之刃零》，选择「管理 → 浏览本地文件」。\n"
                 "3. 把解压出的 platform 文件夹复制到游戏根目录，合并同名文件夹。\n"
                 "4. 确认 platform/steam/ue4ss/Mods/AdRevive/Scripts/main.lua 存在，从 Steam 启动游戏。\n"
                 f"5. 在 platform/steam/ue4ss/UE4SS.log 查找本次启动的 [AdRevive] loaded v{version}。\n\n"
                 "离线试玩：直接打开本包的 ADgame/index.html。\n"
                 "卸载 MOD：退出游戏并移除 platform/steam/ue4ss/Mods/AdRevive。小游戏进度保存在 %LOCALAPPDATA%/PBZ/AdRevive。\n"
                 "游戏角色和武器图鉴素材来自《影之刃零》BWIKI。https://wiki.biligame.com/yingzhiren/\n")
        with zipfile.ZipFile(temp / name, "w") as archive:
            zip_entry(archive, "安装说明.txt", guide.replace("\n", "\r\n").encode("utf-8-sig"))
            zip_entry(archive, "ADgame/index.html", standalone)
            zip_entry(archive, "THIRD-PARTY-NOTICES.txt", notices)
            for rel, data in sorted((runtime if full else mod_files).items()):
                zip_entry(archive, STEAM / rel, data)
            if full:
                encoded = json.dumps(receipt, sort_keys=True, indent=2).encode("utf-8")
                zip_entry(archive, STEAM / receipt_name, encoded)
        with zipfile.ZipFile(temp / name) as archive:
            if archive.testzip() is not None:
                raise ValueError(f"CRC verification failed for {name}")
        bundles.append(name)
    return bundles


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--loader-archive", type=Path, help="Use a local copy of the pinned upstream ZIP")
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("This packager uses the Windows installer.")
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="AdRevive-release-", dir=output) as directory:
        temp = Path(directory)
        binary = stage(temp / "PBZ", temp / "profile", args.loader_archive)
        for name in make_archives(temp, binary):
            (temp / name).replace(output / name)
            print(output / name)


if __name__ == "__main__":
    main()
