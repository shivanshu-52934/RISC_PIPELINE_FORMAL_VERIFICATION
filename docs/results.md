# Results

## Local Run

Date: 2026-05-18.

Environment: Windows PowerShell with official YosysHQ OSS CAD Suite
`oss-cad-suite-windows-x64-20260517.exe`, extracted locally under `tools/`.

The full local flow was run with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_all_windows.ps1
```

## Tool Versions

| Tool | Version |
| --- | --- |
| Yosys | `0.65+37` |
| SBY | `v0.65` |
| Boolector | `3.2.4` |
| Icarus Verilog | `14.0 devel` |

Note: the Windows OSS CAD Suite package used here does not include `make`, so
the Windows flow uses the PowerShell runner. The GitHub Actions Linux workflow
uses `make formal`, `make cover`, and `make sim`.

## Proof, Cover, Simulation

| Check | Result | Evidence |
| --- | --- | --- |
| Formal proof | PASS | `results/logs/formal_proof.log`, `results/logs/formal_proof_final.log` |
| Formal cover | PASS | `results/logs/formal_cover.log`, `results/logs/formal_cover_final.log` |
| Simulation | PASS | `results/logs/simulation.log` |
| Waveform generation | PASS | `waveforms/pipeline.vcd` |

Formal proof result:

```text
DONE (PASS, rc=0)
successful proof by k-induction
```

Formal cover result:

```text
DONE (PASS, rc=0)
cover trace: formal/cover/engine_0/trace0.vcd
cover trace: formal/cover/engine_0/trace1.vcd
cover trace: formal/cover/engine_0/trace2.vcd
```

Simulation result:

```text
Simulation exit code: 0
waveforms/pipeline.vcd generated
```

Icarus Verilog emitted non-fatal warnings about `unique case` handling and
constant selects in `always_*` sensitivity. The simulation still compiled and
completed with exit code 0.

## Implemented Verification Targets

| Target | Status | File |
| --- | --- | --- |
| x0 architectural invariant | Proven | `formal/properties.sv` |
| PC + 4 continuity | Proven | `formal/properties.sv` |
| Stall holds PC and IF/ID | Proven | `formal/properties.sv` |
| EX/MEM forwarding priority | Proven | `formal/properties.sv` |
| MEM/WB forwarding fallback | Proven | `formal/properties.sv` |
| Branch target formula | Proven | `formal/properties.sv` |
| Branch redirect and flush | Proven | `formal/properties.sv` |
| Bounded writeback progress | Proven | `formal/properties.sv` |
| Writeback, stall, branch covers | Reached | `formal/properties.sv` |

## Bug Injection Results

Each intentional bug patch was applied, checked with `sby -f formal/riscv.sby`,
and reverted. All four bugs were detected by formal assertions.

| Bug patch | Result | Failing assertion |
| --- | --- | --- |
| `bug01_wrong_forwarding_priority.patch` | Expected FAIL observed | `properties.sv:33` |
| `bug02_missing_load_use_rs2.patch` | Expected FAIL observed | `properties.sv:66` |
| `bug03_branch_pc_plus4.patch` | Expected FAIL observed | `properties.sv:70` |
| `bug04_x0_writable.patch` | Expected FAIL observed | `properties.sv:22` |

Logs are stored in `results/logs/bug*.log`.

## CI Result Path

The repository includes `.github/workflows/formal.yml`. After pushing to
GitHub, the workflow installs OSS CAD Suite, runs the proof, reaches cover
points, runs simulation, and uploads proof/waveform artifacts.
