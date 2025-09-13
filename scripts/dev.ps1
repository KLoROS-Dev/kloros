param(
  [Parameter(Position=0)]
  [ValidateSet("setup","venv","fmt","lint","type","test","hooks","all","clean")]
  [string]$Task = "all"
)

$ErrorActionPreference = "Stop"

# Prefer project venv binaries if present
function Get-VenvPython {
  if (Test-Path ".\.venv\Scripts\python.exe") { return ".\.venv\Scripts\python.exe" }
  if (Get-Command python -ErrorAction SilentlyContinue) { return "python" }
  return "py"  # fallback to Python launcher
}

function Get-VenvPreCommit {
  if (Test-Path ".\.venv\Scripts\pre-commit.exe") { return ".\.venv\Scripts\pre-commit.exe" }
  return $null
}

function Invoke-Setup {
  Write-Host ">> Creating venv and installing dev tools..." -ForegroundColor Cyan
  $Py = Get-VenvPython
  if (!(Test-Path ".\.venv\Scripts\python.exe")) {
    & $Py -m venv .venv
  }
  $Vpy = ".\.venv\Scripts\python.exe"
  & $Vpy -m pip install -U pip
  & $Vpy -m pip install -e .
  & $Vpy -m pip install -U pre-commit black ruff mypy pytest
  $pc = Get-VenvPreCommit
  if ($pc) { & $pc install }
}

function Invoke-Venv {
  Write-Host ">> Activating venv for this session..." -ForegroundColor Cyan
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  . .\.venv\Scripts\Activate.ps1
}

function Invoke-Fmt  { $Vpy = ".\.venv\Scripts\python.exe"; if (!(Test-Path $Vpy)) { $Vpy = Get-VenvPython } & $Vpy -m black . }
function Invoke-Lint { $Vpy = ".\.venv\Scripts\python.exe"; if (!(Test-Path $Vpy)) { $Vpy = Get-VenvPython } & $Vpy -m ruff check . }
function Invoke-Type { $Vpy = ".\.venv\Scripts\python.exe"; if (!(Test-Path $Vpy)) { $Vpy = Get-VenvPython } & $Vpy -m mypy src }
function Invoke-Test { $Vpy = ".\.venv\Scripts\python.exe"; if (!(Test-Path $Vpy)) { $Vpy = Get-VenvPython } & $Vpy -m pytest -q }

function Invoke-Hooks {
  $pc = Get-VenvPreCommit
  $Vpy = ".\.venv\Scripts\python.exe"
  if ($pc) { & $pc run --all-files }
  else { & $Vpy -m pre_commit run --all-files }
}

function Invoke-All {
  Invoke-Fmt
  Invoke-Lint
  Invoke-Type
  Invoke-Test
}

function Invoke-Clean {
  Write-Host ">> Cleaning caches..." -ForegroundColor Cyan
  Get-ChildItem -Recurse -Force -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  Get-ChildItem -Recurse -Force -Directory -Filter ".pytest_cache" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  if (Test-Path ".ruff_cache") { Remove-Item ".ruff_cache" -Recurse -Force -ErrorAction SilentlyContinue }
}

switch ($Task) {
  "setup" { Invoke-Setup; break }
  "venv"  { Invoke-Venv; break }
  "fmt"   { Invoke-Fmt; break }
  "lint"  { Invoke-Lint; break }
  "type"  { Invoke-Type; break }
  "test"  { Invoke-Test; break }
  "hooks" { Invoke-Hooks; break }
  "all"   { Invoke-All; break }
  "clean" { Invoke-Clean; break }
}
