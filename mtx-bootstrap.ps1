param(
    [string]$InstallRoot = "$env:LOCALAPPDATA\MTX",
    [string]$ComfyUiPath = "C:\Users\Emmanuel\ComfyUI\main.py",
    [switch]$NoStartServices,
    [switch]$SkipSelfTest
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$msg) {
    Write-Host "[MTX Bootstrap] $msg"
}

function Ensure-Directory([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

function Add-UserPathEntry([string]$entry) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $userPath = $entry
        [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
        return
    }

    $parts = $userPath.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    if ($parts -contains $entry) { return }

    $newPath = ($parts + $entry) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

function Start-BackgroundService([string]$name, [string]$exe, [string]$arguments) {
    $existing = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like $name }
    if ($existing) {
        Write-Step "$name already running"
        return
    }

    Write-Step "Starting $name"
    if ([string]::IsNullOrWhiteSpace($arguments)) {
        Start-Process -FilePath $exe -WindowStyle Hidden | Out-Null
    } else {
        Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden | Out-Null
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceExe = Join-Path $repoRoot "mtx-engine\mtx.exe"

if (-not (Test-Path -LiteralPath $sourceExe)) {
    throw "Could not find MTX runtime at $sourceExe"
}

$binDir = Join-Path $InstallRoot "bin"
Ensure-Directory $InstallRoot
Ensure-Directory $binDir

$targetExe = Join-Path $binDir "mtx.exe"
Write-Step "Installing MTX runtime to $targetExe"
Copy-Item -LiteralPath $sourceExe -Destination $targetExe -Force

$shimPath = Join-Path $binDir "mtx.cmd"
@"
@echo off
"%~dp0mtx.exe" %*
"@ | Set-Content -Path $shimPath -Encoding ASCII

Write-Step "Setting MTX_HOME user variable"
[Environment]::SetEnvironmentVariable("MTX_HOME", $InstallRoot, "User")

Write-Step "Updating user PATH"
Add-UserPathEntry $binDir

if (-not $NoStartServices) {
    $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaCmd) {
        Start-BackgroundService -name "ollama" -exe $ollamaCmd.Source -arguments "serve"
    } else {
        Write-Step "Ollama not found on PATH; skipping auto-start"
    }

    if (Test-Path -LiteralPath $ComfyUiPath) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd) {
            $comfyArgs = "`"$ComfyUiPath`" --cpu"
            Start-BackgroundService -name "python" -exe $pythonCmd.Source -arguments $comfyArgs
        } else {
            Write-Step "Python not found on PATH; skipping ComfyUI auto-start"
        }
    } else {
        Write-Step "ComfyUI script not found at $ComfyUiPath; skipping auto-start"
    }
}

if (-not $SkipSelfTest) {
    Write-Step "Running MTX self-test"
    & $targetExe --self-test | Out-Host
    if ($LASTEXITCODE -ne 0) {
        if ($LASTEXITCODE -eq -1073741515) {
            throw "MTX self-test failed with exit code -1073741515 (0xC0000135: missing runtime DLL). Rebuild MTX as a static binary or install the required C/C++ runtime."
        }
        throw "MTX self-test failed with exit code $LASTEXITCODE"
    }
}

Write-Step "Install complete"
Write-Step "Open a new terminal, then run: mtx"
