# NVIDIA Formal Verification Alignment

Target role: Formal Verification Engineer, New College Graduate.

Job requisition: JR2017808.

## Requirement Mapping

| NVIDIA requirement | Project evidence |
| --- | --- |
| Understand RTL quickly | 5-stage pipeline split into ALU, regfile, hazard, forwarding, branch, and core modules |
| Hands-on Verilog/SystemVerilog | RTL is written in SystemVerilog with synthesizable pipeline state |
| Temporal logic assertions | `formal/properties.sv` uses clocked SVA-style temporal checks and `$past` |
| Formal methodology | `formal_harness.sv`, `assumptions.sv`, and `riscv.sby` define environment, constraints, and proof flow |
| Robust verification plan | `docs/verification_plan.md` lists property categories and closure criteria |
| Debug difficult problems | `docs/bug_analysis.md` describes injected bugs, expected failures, traces, and fixes |
| Abstraction techniques | Instruction stream is constrained to a focused RV32I subset to keep proof scope tractable |

## Interview Pitch

This is not positioned as a CPU design project. The processor is a realistic DUT
chosen to expose formal verification problems: RAW hazards, forwarding priority,
load-use stalls, branch redirection, flush behavior, and architectural
invariants.

The main value is the verification flow:

1. Define what correctness means.
2. Encode it as assertions.
3. Constrain the formal environment.
4. Run bounded proof.
5. Inspect counterexample waveforms.
6. Fix RTL and prove closure.

That maps directly to entry-level formal verification ownership on IP blocks.
