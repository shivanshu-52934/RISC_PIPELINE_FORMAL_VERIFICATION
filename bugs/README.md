# Intentional Bug Injection

These patches are designed for formal-debug demonstrations. Apply one patch,
run the proof, inspect the counterexample, then revert the patch and fix the
RTL.

## Workflow

```sh
git apply bugs/bug01_wrong_forwarding_priority.patch
make formal
gtkwave formal/riscv/engine_0/trace.vcd
git apply -R bugs/bug01_wrong_forwarding_priority.patch
```

## Bug Library

| Patch | Expected failing property | Verification lesson |
| --- | --- | --- |
| `bug01_wrong_forwarding_priority.patch` | RAW forwarding priority | Newest producer must beat older writeback |
| `bug02_missing_load_use_rs2.patch` | Load-use stall | Both source operands must be checked |
| `bug03_branch_pc_plus4.patch` | PC redirect | Branch target must use branch instruction PC |
| `bug04_x0_writable.patch` | x0 invariant | Architectural constants need hard guards |

These are intentionally small bugs because the interview story is the formal
debug process: failing assertion, trace, root cause, fix, proof closure.
