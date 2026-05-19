param(
    [string]$OssCadSuite = "tools/oss-cad-suite-extract/oss-cad-suite"
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$envScript = Join-Path $OssCadSuite "environment.ps1"
if (-not (Test-Path $envScript)) {
    Write-Error "OSS CAD Suite environment not found at $envScript"
    exit 1
}

. $envScript

New-Item -ItemType Directory -Force -Path "results/logs", "build", "waveforms" | Out-Null

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Command,
        [string]$Log
    )

    Write-Host "== $Name =="
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $Command *> $Log
    $ErrorActionPreference = $oldPreference
    $code = $LASTEXITCODE
    if ($null -eq $code) {
        $code = 0
    }
    $message = "$Name exit code: $code"
    Add-Content -Path $Log -Value $message
    Write-Host $message
    return $code
}

Run-Step "Tool versions" {
    yosys -V
    sby --version
    boolector --version
    iverilog -V
} "results/logs/tool_versions.log" | Out-Null

$formalCode = Run-Step "Formal proof" {
    sby -f formal/riscv.sby
} "results/logs/formal_proof.log"

$coverCode = Run-Step "Formal cover" {
    sby -f formal/cover.sby
} "results/logs/formal_cover.log"

$simCode = Run-Step "Simulation" {
    iverilog -g2012 -o build/tb.vvp rtl/alu.sv rtl/regfile.sv rtl/forwarding_unit.sv rtl/hazard_unit.sv rtl/branch_unit.sv rtl/core.sv sim/tb.sv
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    vvp build/tb.vvp
} "results/logs/simulation.log"

$bugSummary = @()
$bugMismatch = $false
$patches = Get-ChildItem bugs -Filter "bug*.patch" | Sort-Object Name
foreach ($patch in $patches) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($patch.Name)
    $log = "results/logs/$name.log"
    Write-Host "== Bug run: $($patch.Name) =="
    try {
        git apply $patch.FullName
        sby -f formal/riscv.sby *> $log
        $code = $LASTEXITCODE
        if ($null -eq $code) {
            $code = 0
        }
        if ($code -ne 0) {
            $bugSummary += "$($patch.Name): expected FAIL observed"
        } else {
            $bugSummary += "$($patch.Name): unexpected PASS"
            $bugMismatch = $true
        }
        "Bug run exit code: $code" | Tee-Object -FilePath $log -Append | Out-Null
    } finally {
        git apply -R $patch.FullName
    }
}

$finalFormalCode = Run-Step "Final clean formal proof" {
    sby -f formal/riscv.sby
} "results/logs/formal_proof_final.log"

$finalCoverCode = Run-Step "Final clean formal cover" {
    sby -f formal/cover.sby
} "results/logs/formal_cover_final.log"

$summary = @(
    "# Local Run Summary",
    "",
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
    "",
    "| Check | Result |",
    "| --- | --- |",
    "| Formal proof | $(if ($formalCode -eq 0) { 'PASS' } else { 'FAIL' }) |",
    "| Formal cover | $(if ($coverCode -eq 0) { 'PASS' } else { 'FAIL' }) |",
    "| Simulation | $(if ($simCode -eq 0) { 'PASS' } else { 'FAIL' }) |",
    "| Final clean formal proof | $(if ($finalFormalCode -eq 0) { 'PASS' } else { 'FAIL' }) |",
    "| Final clean formal cover | $(if ($finalCoverCode -eq 0) { 'PASS' } else { 'FAIL' }) |",
    "| Waveform | $(if (Test-Path 'waveforms/pipeline.vcd') { 'Generated' } else { 'Missing' }) |",
    "",
    "## Bug Injection",
    ""
) + ($bugSummary | ForEach-Object { "- $_" })

$summary | Set-Content -Path "results/local_run_summary.md" -Encoding ASCII

if (($formalCode -ne 0) -or ($coverCode -ne 0) -or ($simCode -ne 0) -or
    ($finalFormalCode -ne 0) -or ($finalCoverCode -ne 0) -or $bugMismatch) {
    exit 1
}
