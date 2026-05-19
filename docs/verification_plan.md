# Verification Plan

## Goal

Prove correctness properties over a 5-stage pipelined RISC-V DUT using
SystemVerilog Assertions and SymbiYosys. The purpose is to demonstrate formal
verification methodology: assumptions, assertions, temporal checks,
counterexample debug, and closure.

## Formal Environment

`formal/formal_harness.sv` instantiates the core and lets the formal engine
choose instruction and data-memory values. `formal/assumptions.sv` constrains
instruction fetch to the supported RV32I subset so proofs focus on pipeline
correctness rather than unsupported ISA behavior.

## Properties

| Category | Property | Assertion intent |
| --- | --- | --- |
| Architectural invariant | x0 is always zero | Register zero cannot be modified |
| Interface safety | No simultaneous data read/write | Data memory command is well-formed |
| PC sequencing | PC increments by 4 without branch/stall | Temporal PC continuity |
| Stall behavior | Load-use hazard holds IF/ID and PC | No stale load consumer advances |
| Forwarding | EX/MEM and MEM/WB RAW matches select bypass | No stale register operand |
| Control hazard | Taken branch redirects PC and flushes younger stages | Wrong-path instructions are killed |
| Progress evidence | Covers writeback, stall, branch | Proof explores meaningful pipeline states |

## Expected Commands

```sh
make formal
make cover
make sim
```

`make formal` runs `sby -f formal/riscv.sby`. `make sim` builds a short smoke
test with Icarus Verilog and writes `waveforms/pipeline.vcd`.
`make cover` runs `sby -f formal/cover.sby` to generate traces that reach
writeback, stall, and branch behavior.

## Closure Criteria

1. All assertions pass at the configured bounded depth.
2. Cover statements reach writeback, load-use stall, and taken branch states.
3. Intentional bug variants produce clear counterexample traces.
4. Each debugged bug is documented with failure, root cause, and fix.

## Current Execution Status

See `docs/results.md`. The project has been run locally with OSS CAD Suite:
proof passes, cover targets are reached, simulation passes, and all intentional
bug patches are detected by formal assertions.
