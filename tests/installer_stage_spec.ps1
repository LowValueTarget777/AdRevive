# Exercise the running-game branch with a simulated process in a unique temp tree.
$ErrorActionPreference = 'Stop'
$base = Join-Path ([IO.Path]::GetTempPath()) ('AdRevive-stage-spec-' + [guid]::NewGuid().ToString('N'))
$bin = Join-Path $base 'platform\steam'
$pkg = Join-Path $base 'pkg'
$mockGame = $null
function Get-Process { param($Name, $ErrorAction) if ($mockGame) { $mockGame } }
function CheckFailure($pattern, $test) {
    try { & $test; throw 'Expected installer refusal.' }
    catch { if ($_.Exception.Message -notlike $pattern) { throw } }
}
try {
    $originalLocal = $env:LOCALAPPDATA
    $env:LOCALAPPDATA = Join-Path $base 'profile'
    foreach ($dir in @("$bin\ue4ss\Mods", "$pkg\Mods\AdRevive\Scripts", "$pkg\Mods\AdRevive\Art", "$pkg\Ad")) {
        [void][IO.Directory]::CreateDirectory($dir)
    }
    foreach ($path in @("$bin\PBZ.exe", "$bin\ue4ss\UE4SS.dll", "$pkg\Mods\AdRevive\Art\ground.png")) {
        [IO.File]::WriteAllText($path, 'fake')
    }
    [IO.File]::WriteAllText("$bin\ue4ss\UE4SS-settings.ini", 'EnableHotReloadSystem = 0')
    [IO.File]::WriteAllText("$pkg\Mods\AdRevive\Scripts\main.lua", 'print("v1")')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\Install.ps1') -Destination "$pkg\Install.ps1"
    & "$pkg\Install.ps1" -GameRoot $base
    $mockGame = [pscustomobject]@{Id=357;Path="$bin\PBZ.exe";StartTime=(Get-Date).AddMinutes(-1)}
    [IO.File]::WriteAllText("$pkg\Mods\AdRevive\Scripts\main.lua", 'print("v2")')
    function WriteLog($timestamp) {
        $prefix = '[' + $timestamp.ToString('yyyy-MM-dd HH:mm:ss') + '.9761768] '
        $rows = @($prefix + '[Lua] [AdRevive] loaded (test)'
            $prefix + '[RegisterHook] Registered script hook (1, 1) for Function /Game/Test.BP_Player_Soul_C:OnDie')
        [IO.File]::WriteAllLines("$bin\ue4ss\UE4SS.log", [string[]]$rows)
    }
    WriteLog (Get-Date).AddDays(-1)
    CheckFailure '*Wait for AdRevive*' { & "$pkg\Install.ps1" -GameRoot $base }
    WriteLog (Get-Date)
    & "$pkg\Install.ps1" -GameRoot $base
    $installed = "$bin\ue4ss\Mods\AdRevive\Scripts\main.lua"
    if ([IO.File]::ReadAllText($installed) -ne 'print("v2")') { throw 'Wrong staged Lua' }
    CheckFailure '*first time or uninstalling*' { & "$pkg\Install.ps1" -GameRoot $base -Uninstall }
    [IO.File]::WriteAllText("$pkg\Mods\AdRevive\Art\ground.png", 'new-art')
    CheckFailure '*non-script files*' { & "$pkg\Install.ps1" -GameRoot $base }
    [IO.File]::WriteAllText($installed, 'my edits')
    CheckFailure '*missing or modified file*' { & "$pkg\Install.ps1" -GameRoot $base }
    'Installer staged update and all four rejection cases passed.'
} finally {
    $env:LOCALAPPDATA = $originalLocal
    $scratch = [IO.Path]::GetFullPath($base)
    if ([IO.Path]::GetDirectoryName($scratch) -eq [IO.Path]::GetTempPath().TrimEnd('\') -and
        [IO.Path]::GetFileName($scratch) -match '^AdRevive-stage-spec-[a-f0-9]{32}$' -and
        [IO.Directory]::Exists($scratch)) {
        Remove-Item -LiteralPath $scratch -Recurse -Force
    }
}
