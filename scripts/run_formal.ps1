param(
    [switch]$Cover
)

if (-not (Get-Command sby -ErrorAction SilentlyContinue)) {
    Write-Error "sby was not found on PATH. Install OSS CAD Suite or use WSL, then rerun."
    exit 1
}

if ($Cover) {
    sby -f formal/cover.sby
} else {
    sby -f formal/riscv.sby
}
