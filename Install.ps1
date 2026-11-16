[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [string]$LoaderArchive,
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$bin = (Resolve-Path -LiteralPath (Join-Path $GameRoot 'platform\steam')).ProviderPath
$game = Join-Path $bin 'PBZ.exe'
if (-not [IO.File]::Exists($game)) { throw "Missing game executable: $game" }
function RunningGame {
    Get-Process -Name PBZ -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $game }
}
$mod = 'ue4ss\Mods\AdRevive'
$receipt = Join-Path $bin 'AdRevive.install.json'
$bootstrapFiles = @(
    'ue4ss\LICENSE', 'ue4ss\MemberVariableLayout.ini', 'ue4ss\UE4SS-settings.ini',
    'ue4ss\UE4SS.dll', 'ue4ss\UE4SS_SDK_Backends\UE4SS.json',
    'ue4ss\UE4SS_Signatures\GNatives.lua', 'ue4ss\UE4SS_Signatures\GUObjectArray.lua',
    'ue4ss\Mods\shared\UEHelpers\UEHelpers.lua', 'ue4ss\Mods\mods.txt', 'dwmapi.dll'
)
$modPattern = '^ue4ss\\Mods\\AdRevive\\(?:Scripts\\[\w.-]+\.lua|Art\\(?:ground|unit-[0-9]{3})\.png|ReviveAd\.exe|AdLaunch\.dll|enabled\.txt)$'
$archiveHash = '7D7FAE124C8C0E26861382E084A663702BEA3F401B3BA8D90BD970B0381ABF48'
$archiveUrl = 'https://github.com/KintaroModding/ue4ss/releases/download/v4.0.0/phantombladezero_ue4ss_v4.0.0.zip'

function FileHash($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function CheckLinks($path) {
    while ($path -ne $bin) {
        if ((Test-Path -LiteralPath $path) -and
            ((Get-Item -Force -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Resolve the linked installation path before proceeding: $path"
        }
        $path = [IO.Path]::GetDirectoryName($path)
    }
}
function Target($relative) {
    if ($relative -notin $bootstrapFiles -and $relative -notmatch $modPattern) {
        throw "Unexpected file in AdRevive receipt: $relative"
    }
    $file = Join-Path $bin $relative
    CheckLinks $file
    $file
}
function EnsureParent($file) {
    $missing = @()
    $dir = [IO.Path]::GetDirectoryName($file)
    while (-not [IO.Directory]::Exists($dir)) {
        $missing += $dir
        $dir = [IO.Path]::GetDirectoryName($dir)
    }
    [array]::Reverse($missing)
    foreach ($dir in $missing) {
        [void][IO.Directory]::CreateDirectory($dir)
        $createdDirs.Add($dir.Substring($bin.Length + 1))
    }
}
function RemoveEmptyDirs($dirs) {
    foreach ($d in ($dirs | Sort-Object Length -Descending)) {
        $dir = Join-Path $bin $d
        CheckLinks $dir
        if ([IO.Directory]::Exists($dir) -and @(Get-ChildItem -LiteralPath $dir -Force).Count -eq 0) {
            [IO.Directory]::Delete($dir)
        }
    }
}
function ChangeFile($dest, $source) {
    $copy = $null
    if ([IO.File]::Exists($dest)) {
        $copy = Join-Path $work ("previous-" + $undo.Count)
        [IO.File]::Copy($dest, $copy)
    }
    EnsureParent $dest
    $undo.Add(@{file=$dest; backup=$copy})
    if ($null -eq $source) { [IO.File]::Delete($dest) }
    else { [IO.File]::Copy($source, $dest, $true) }
}
$mutex = New-Object Threading.Mutex($false, 'Local\PBZ-AdRevive-Installer')
try { $locked = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked = $true }
if (-not $locked) { $mutex.Dispose(); throw 'Another AdRevive installer is running.' }
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$work = Join-Path $tempBase ('PBZ-AdRevive-' + [guid]::NewGuid().ToString('N'))
$undo = New-Object 'System.Collections.Generic.List[object]'
$createdDirs = New-Object 'System.Collections.Generic.List[string]'
try {
    [void][IO.Directory]::CreateDirectory($work)
    CheckLinks $receipt
    $owned = @{}
    $oldDirs = @()
    if ([IO.File]::Exists($receipt)) {
        $previous = Get-Content -LiteralPath $receipt -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($previous.format -ne 'AdRevive/1') { throw "Unexpected receipt: $receipt" }
        foreach ($entry in $previous.files) {
            $null = Target $entry.path
            if ($entry.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Invalid receipt checksum.' }
            $owned[$entry.path] = $entry.sha256
        }
        $oldDirs = @($previous.directories)
        $allowedDirs = foreach ($rel in $owned.Keys) {
            $d = [IO.Path]::GetDirectoryName($rel)
            while ($d) { $d; $d = [IO.Path]::GetDirectoryName($d) }
        }
        foreach ($d in $oldDirs) { if ($d -notin $allowedDirs) { throw "Invalid receipt directory: $d" } }
    }
    # UE4SS loads Lua modules into memory. When that load is complete, a
    # script-only update on disk can be picked up by the next game launch.
    $running = RunningGame
    if ($running) {
        if ($Uninstall -or -not $owned.ContainsKey("$mod\Scripts\main.lua")) {
            throw 'Exit Phantom Blade Zero before installing for the first time or uninstalling.'
        }
        foreach ($name in $owned.Keys) {
            $existing = Target $name
            if (-not [IO.File]::Exists($existing) -or (FileHash $existing) -ne $owned[$name]) {
                throw "Cannot stage a running-game update over a missing or modified file: $existing"
            }
        }
        $settings = Target 'ue4ss\UE4SS-settings.ini'
        if (-not [IO.File]::Exists($settings) -or
            (Get-Content -LiteralPath $settings -Raw) -notmatch '(?im)^\s*EnableHotReloadSystem\s*=\s*0\s*$') {
            throw 'Exit Phantom Blade Zero before updating when UE4SS hot reload is enabled or unknown.'
        }
        $log = Join-Path $bin 'ue4ss\UE4SS.log'
        $loaded = $false
        $observersLoaded = $false
        if ([IO.File]::Exists($log)) {
            $markers = @('\[Lua\]\s+\[AdRevive\]\s+loaded\b',
                '\[RegisterHook\].*BP_Player_Soul_C:OnDie\s*$')
            foreach ($row in (Select-String -LiteralPath $log -Pattern $markers)) {
                if ($row.Line -match '^\[(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)') {
                    $stamp = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture)
                    if ($stamp -ge $running.StartTime.AddMilliseconds(-999)) {
                        if ($row.Line -match $markers[0]) { $loaded = $true }
                        elseif ($row.Line -match $markers[1]) { $observersLoaded = $true }
                    }
                }
            }
        }
        # In 0.2.0 deathwatch.lua is required by the first game-thread callback,
        # after main.lua prints "loaded". Wait for both parts of startup.
        if (-not ($loaded -and $observersLoaded)) {
            throw 'Wait for AdRevive to finish loading or exit Phantom Blade Zero before updating.'
        }
    }
    if ($Uninstall) {
        if (-not [IO.File]::Exists($receipt)) { Write-Output 'No AdRevive installation receipt.'; return }
        $keepLoader = $false
        if ($owned.ContainsKey('dwmapi.dll')) {
            $modsDir = Join-Path $bin 'ue4ss\Mods'
            $others = @(Get-ChildItem -LiteralPath $modsDir -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notin @('shared','AdRevive') })
            $customized = @($bootstrapFiles | Where-Object {
                $f = Target $_
                [IO.File]::Exists($f) -and (FileHash $f) -ne $owned[$_]
            })
            $keepLoader = $others.Count -gt 0 -or $customized.Count -gt 0
            if ($keepLoader) { Write-Output 'Keeping the shared UE4SS installation and its configuration.' }
        }
        foreach ($name in $owned.Keys) {
            if ($keepLoader -and $name -in $bootstrapFiles) { continue }
            $file = Target $name
            if (-not [IO.File]::Exists($file)) { continue }
            if ((FileHash $file) -ne $owned[$name]) { Write-Output "Keeping modified file: $file"; continue }
            ChangeFile $file $null
        }
        ChangeFile $receipt $null
        RemoveEmptyDirs $oldDirs
        Write-Output 'AdRevive uninstalled.'
        return
    }

    $scripts = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Mods\AdRevive\Scripts') -Filter '*.lua' -File
    if ('main.lua' -notin $scripts.Name) { throw 'Missing Mods\AdRevive\Scripts\main.lua.' }
    $sources = [ordered]@{}
    foreach ($script in $scripts) { $sources["$mod\Scripts\$($script.Name)"] = $script.FullName }
    $art = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Mods\AdRevive\Art') -Filter '*.png' -File
    if ('ground.png' -notin $art.Name) { throw 'Missing ADgame battlefield texture.' }
    foreach ($texture in $art) { $sources["$mod\Art\$($texture.Name)"] = $texture.FullName }
    $enabled = Join-Path $work 'enabled.txt'
    [IO.File]::WriteAllBytes($enabled, [byte[]]@())
    $sources["$mod\enabled.txt"] = $enabled
    $runtime = Target 'ue4ss\UE4SS.dll'
    if (-not [IO.File]::Exists($runtime)) {
        if ($running) { throw 'Exit Phantom Blade Zero before repairing the mod loader.' }
        if (-not $owned.ContainsKey('dwmapi.dll')) {
            $collisions = @('ue4ss','dwmapi.dll','dinput8.dll','version.dll','hid.dll','winmm.dll','dxgi.dll') |
                Where-Object { Test-Path -LiteralPath (Join-Path $bin $_) }
            if ($collisions) { throw "An existing loader needs to be identified before installing UE4SS: $($collisions -join ', ')" }
        }
        if (-not $LoaderArchive) {
            $LoaderArchive = Join-Path $work 'ue4ss.zip'
            Invoke-WebRequest -UseBasicParsing -Uri $archiveUrl -OutFile $LoaderArchive
        }
        if ((FileHash $LoaderArchive) -ne $archiveHash) { throw 'The PBZ UE4SS 4.0.0 archive checksum does not match.' }
        $extracted = Join-Path $work 'loader'
        Expand-Archive -LiteralPath $LoaderArchive -DestinationPath $extracted
        # Only the runtime, shared library and this mod start on a clean installation.
        [IO.File]::WriteAllText((Join-Path $extracted 'ue4ss\Mods\mods.txt'), '')
        foreach ($name in $bootstrapFiles) { $sources[$name] = Join-Path $extracted $name }
    }
    $updates = [ordered]@{}
    foreach ($name in $sources.Keys) {
        $dest = Target $name
        $newHash = FileHash $sources[$name]
        if ([IO.File]::Exists($dest)) {
            if (-not $owned.ContainsKey($name)) { throw "Preserving file from another installation: $dest" }
            $current = FileHash $dest
            if ($current -eq $newHash) { $owned[$name]=$newHash; continue }
            if ($current -ne $owned[$name]) { throw "Preserving your edited file: $dest" }
        }
        $updates[$name] = $sources[$name]
        $owned[$name] = $newHash
    }
    # Retire unchanged files owned by older versions, including the external window.
    foreach ($name in @($owned.Keys)) {
        if ($name -notmatch $modPattern -or $sources.Contains($name)) { continue }
        $dest = Target $name
        if ([IO.File]::Exists($dest)) {
            if ((FileHash $dest) -ne $owned[$name]) { throw "Preserving your edited file: $dest" }
            $updates[$name] = $null
        }
        $owned.Remove($name)
    }
    $nowRunning = RunningGame
    if ($nowRunning) {
        if (-not $running -or $running.Id -ne $nowRunning.Id -or $running.StartTime -ne $nowRunning.StartTime) {
            throw 'Phantom Blade Zero started during setup. Retry after the mod has loaded.'
        }
        foreach ($name in $updates.Keys) {
            if ($name -notmatch '^ue4ss\\Mods\\AdRevive\\Scripts\\[\w.-]+\.lua$') {
                throw "Exit Phantom Blade Zero before replacing non-script files: $name"
            }
        }
    }
    foreach ($name in $updates.Keys) { ChangeFile (Target $name) $updates[$name] }
    $saved = Join-Path $work 'install.json'
    $entries = @(foreach ($name in ($owned.Keys | Sort-Object)) { @{path=$name; sha256=$owned[$name]} })
    $dirs = @(($oldDirs + $createdDirs.ToArray()) | Sort-Object -Unique)
    $json = @{format='AdRevive/1'; version='0.14.1'; files=$entries; directories=$dirs} | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($saved, $json)
    ChangeFile $receipt $saved
    if ($nowRunning) { Write-Output "AdRevive scripts prepared for the next game start in $(Join-Path $bin $mod)" }
    else { Write-Output "AdRevive installed in $(Join-Path $bin $mod)" }
} catch {
    for ($i=$undo.Count-1; $i -ge 0; $i--) {
        $item=$undo[$i]
        if ($item.backup) {
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($item.file))
            [IO.File]::Copy($item.backup, $item.file, $true)
        } else { [IO.File]::Delete($item.file) }
    }
    RemoveEmptyDirs $createdDirs
    throw
} finally {
    $scratchPath = [IO.Path]::GetFullPath($work)
    if ([IO.Path]::GetDirectoryName($scratchPath) -eq $tempBase -and
        [IO.Path]::GetFileName($scratchPath) -match '^PBZ-AdRevive-[a-f0-9]{32}$' -and
        [IO.Directory]::Exists($scratchPath)) {
        Remove-Item -LiteralPath $scratchPath -Force -Recurse
    }
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
