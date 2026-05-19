# Architecture

This repository contains a deliberately compact 5-stage RV32I pipeline used as a
formal-verification DUT. The CPU is not the main product of the project; it is
the controllable design target for proving temporal properties.

## Pipeline

| Stage | Responsibility | Important state |
| --- | --- | --- |
| IF | Fetch instruction at current PC | `pc_q`, `if_id_*` |
| ID | Decode, immediate generation, register reads | `id_*`, regfile |
| EX | ALU, branch compare/target, operand forwarding | `id_ex_*`, forwarding muxes |
| MEM | Data memory request | `ex_mem_*` |
| WB | Register writeback | `mem_wb_*` |

## Supported Instruction Subset

The design implements a focused RV32I subset:

| Class | Instructions |
| --- | --- |
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT` |
| I-type | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI` |
| Memory | `LW`, `SW` |
| Branch | `BEQ` |

Unsupported encodings decode as bubbles. This keeps the verification scope
clear while still exercising real pipeline behavior.

## Hazard Handling

The forwarding unit bypasses ALU results from `EX/MEM` and writeback results
from `MEM/WB` into the execute stage. Load-use hazards are handled by stalling
fetch/decode for one cycle and injecting a bubble into execute.

Branch decisions are resolved in EX. When a branch is taken, IF/ID and ID/EX
are flushed and the PC is redirected to the computed target.
