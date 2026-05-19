# Resume Bullets

These bullets are now backed by the local OSS CAD Suite run recorded in
`docs/results.md`.

## Project Entry

Formal Verification of 5-Stage RV32I Pipelined Processor using SystemVerilog
Assertions and SymbiYosys

## Bullets

- Built a simplified 5-stage RV32I pipelined processor as a formal verification
  DUT, including hazard detection, forwarding, branch redirect, flush logic,
  memory access, and writeback.
- Developed SystemVerilog assertion checks for x0 invariance, PC continuity,
  RAW forwarding priority, load-use stall correctness, branch flush behavior,
  interface safety, and bounded writeback progress.
- Created a SymbiYosys formal harness with constrained instruction assumptions,
  proof and cover configurations, and GitHub Actions CI using OSS CAD Suite.
- Injected intentional RTL bugs in forwarding, branch target generation,
  load-use stall detection, and x0 write protection to demonstrate
  counterexample-driven debug and proof closure.

## One-Line Interview Pitch

I used a compact RISC-V pipeline as the DUT, then focused on proving temporal
pipeline properties and debugging counterexamples, which is much closer to
formal verification work than a normal CPU-design class project.
