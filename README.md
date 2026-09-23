# MIPS32-pipelined-core

## Repository Description

This repository documents the Phase 1 behavioral baseline of a 5-stage MIPS32 pipeline implemented as part of the NPTEL course "Hardware Modeling Using Verilog". The current design is intentionally kept monolithic and uses a dual-clock scheme with behavioral timing delays (`#2`) to match the original teaching model. It is intended as a reference implementation for studying the pipeline flow, register/memory behavior, and basic control logic before the refactor to a cleaner, single-clock architecture.

## Module Overview

The top-level RTL under analysis is `pipe_MIPS32.v`. It implements a classic 5-stage MIPS32 pipeline:

- Fetch (IF)
- Decode (ID)
- Execute (EX)
- Memory (MEM)
- Writeback (WB)

The pipeline is driven by two clock phases, `clk1` and `clk2`, as defined in the original baseline design.

## Port Table

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk1` | input | 1 bit | Rising-edge clock used for IF and EX stages in the baseline design. |
| `clk2` | input | 1 bit | Rising-edge clock used for ID and MEM stages in the baseline design. |

## Internal Parameter Table

| Name | Value | Description |
| --- | --- | --- |
| `ADD` | `6'b000000` | R-type add opcode |
| `SUB` | `6'b000001` | R-type subtract opcode |
| `AND` | `6'b000010` | R-type logical AND |
| `OR` | `6'b000011` | R-type logical OR |
| `SLT` | `6'b000100` | R-type set less-than |
| `MUL` | `6'b000101` | R-type multiply opcode |
| `HLT` | `6'b111111` | Halt instruction |
| `LW` | `6'b001000` | Load word |
| `SW` | `6'b001001` | Store word |
| `ADDI` | `6'b001010` | Immediate add |
| `SUBI` | `6'b001011` | Immediate subtract |
| `SLTI` | `6'b001100` | Immediate compare |
| `BNEQZ` | `6'b001101` | Branch if not equal to zero |
| `BEQZ` | `6'b001110` | Branch if equal to zero |
| `RR_ALU` | `3'b000` | Register-register ALU operation |
| `RM_ALU` | `3'b001` | Register-immediate ALU operation |
| `LOAD` | `3'b010` | Memory load operation |
| `STORE` | `3'b011` | Memory store operation |
| `BRANCH` | `3'b100` | Branch operation |
| `HALT` | `3'b101` | Pipeline halt state |

## Pipeline Flow

The baseline pipeline is organized in the following execution flow:

```mermaid
flowchart LR
  IF[Fetch / IF]
  ID[Decode / ID]
  EX[Execute / EX]
  MEM[Memory / MEM]
  WB[Writeback / WB]

  IF_ID[IF_ID Register<br/>PC + IR]
  ID_EX[ID_EX Register<br/>A, B, Imm, IR]
  EX_MEM[EX_MEM Register<br/>ALUout, B, IR]
  MEM_WB[MEM_WB Register<br/>Result / LMD]

  IF --> IF_ID
  IF_ID --> ID
  ID --> ID_EX
  ID_EX --> EX
  EX --> EX_MEM
  EX_MEM --> MEM
  MEM --> MEM_WB
  MEM_WB --> WB

  EX -->|branch decision| IF
```

This flow reflects the original dual-clock behavioral design, where interstage registers carry the instruction and execution context between pipeline stages.

## Refactoring Roadmap (Phase 2)

1. Add more testbench scenarios to validate data hazards, control hazards, branch behavior, and instruction dependencies.
2. Remove artificial simulation delays (`#2`) and replace them with a clean, synthesizable clocked design.
3. Migrate from the dual-clock baseline to a single-clock architecture while optimizing the register bank and pipeline synchronization.
4. Restructure the monolithic RTL into strict datapath and control path modules with cleaner separation of responsibilities.
5. Implement a hazard unit and forwarding unit to manage data dependencies and reduce stall penalties.

## Files

- `pipe_MIPS32.v` — 5-stage MIPS32 baseline pipeline
- `tb_ejemplo1.v` — example behavioral testbench
- `.gitignore` — ignores simulation artifacts
