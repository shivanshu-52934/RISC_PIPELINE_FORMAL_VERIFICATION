# Bug Analysis Playbook

This document is meant to be filled as bugs are injected and debugged. The goal
is to show verification thinking, not just a passing final design.

Ready-to-apply bug patches are available in `bugs/`.

The full bug-injection flow has been run locally. All four intentional bugs
were detected by formal assertions; logs are available under `results/logs/`.

## Bug 1: Wrong Forwarding Select

**Injection idea:** Change `forwarding_unit.sv` so `MEM/WB` has priority over
`EX/MEM`.

**Expected failure:** The forwarding assertion should fail when two in-flight
instructions target the same source register and the newest value is in
`EX/MEM`.

**Debug story:** The counterexample should show an instruction in EX consuming
an older writeback value instead of the newer ALU result.

**Fix:** Restore priority to `EX/MEM`, then use `MEM/WB` only if no newer match
exists.

## Bug 2: Missing Load-Use Stall

**Injection idea:** Disable `load_use_stall` when the consumer uses `rs2`.

**Expected failure:** The load-use assertion should fail for an instruction
that consumes a load result before memory data reaches writeback.

**Debug story:** The trace should show the dependent instruction entering EX
one cycle too early.

**Fix:** Stall if either used source register matches the destination of a load
in EX.

## Bug 3: Incorrect Branch Target

**Injection idea:** Compute branch target as `pc + 4 + imm`.

**Expected failure:** The PC redirect assertion should fail on a taken `BEQ`.

**Debug story:** The trace should show correct compare, wrong target, and PC
redirect mismatch.

**Fix:** Use the RISC-V branch target rule `target = branch_pc + immediate`.

## Bug 4: x0 Accidentally Writable

**Injection idea:** Remove the `rd_i != 0` guard in `regfile.sv`.

**Expected failure:** The x0 invariant should fail immediately after a write to
register zero.

**Debug story:** The counterexample should identify the writeback event that
corrupts x0.

**Fix:** Ignore writes to `x0` and hardwire reads of `x0` to zero.
