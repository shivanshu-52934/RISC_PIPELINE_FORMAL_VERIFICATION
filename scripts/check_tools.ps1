$tools = @("yosys", "sby", "boolector", "iverilog", "gtkwave")

foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Output ("[OK]      {0} -> {1}" -f $tool, $cmd.Source)
    } else {
        Write-Output ("[MISSING] {0}" -f $tool)
    }
}
