$ErrorActionPreference = 'Stop'
$gameDir = Join-Path $PSScriptRoot '..\ADgame'
Push-Location $gameDir
try {
    if (!(Test-Path 'node_modules\.bin\tstl.cmd')) {
        & npm.cmd ci
        if ($LASTEXITCODE -ne 0) { throw 'ADgame dependency restore failed.' }
    }
    & npm.cmd run build:native
    if ($LASTEXITCODE -ne 0) { throw 'ADgame Lua build failed.' }
    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw 'ADgame preview build failed.' }
    & uv run --no-project --python 3.12 --with pillow python build_art.py
    if ($LASTEXITCODE -ne 0) { throw 'ADgame texture build failed.' }
} finally { Pop-Location }
Push-Location (Join-Path $PSScriptRoot 'migrate')
try {
    & go build -trimpath -ldflags '-s -w' -o ..\MigrateProgress.exe .
    if ($LASTEXITCODE -ne 0) { throw 'Progress importer build failed.' }
} finally { Pop-Location }
