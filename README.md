# MIPS32-pipelined-core

This repository contains the baseline behavioral implementation of a 5-stage MIPS32 pipeline developed in the NPTEL course "Hardware Modeling Using Verilog". The current phase is a monolithic pipeline model with a dual-clock structure, simulation delays (`#2`), and behavioral register/memory arrays, intentionally kept faithful to the original educational reference.

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

## Pipeline Diagram (Mermaid)

```mermaid
flowchart LR
  subgraph IF[Fetch Stage]
    PC[Program Counter]
    I_MEM[Instruction Memory]
    IF_REG[IF_ID Register]
  end

  subgraph ID[Decode Stage]
    RF[Register File]
    CTRL[Instruction Decode]
    ID_REG[ID_EX Register]
  end

  subgraph EX[Execute Stage]
    ALU[ALU / Branch Logic]
    EX_REG[EX_MEM Register]
  end

  subgraph MEM[Memory Stage]
    DATA[Data Memory]
    MEM_REG[MEM_WB Register]
  end

  subgraph WB[Writeback Stage]
    WB[Register Writeback]
  end

  PC -->|Mem[PC]| I_MEM
  I_MEM --> IF_REG
  IF_REG --> RF
  RF --> CTRL
  CTRL --> ID_REG
  ID_REG --> ALU
  ALU --> EX_REG
  EX_REG --> DATA
  DATA --> MEM_REG
  MEM_REG --> WB

  EX_REG -->|branch decision| PC
  DATA -->|load result| WB
  RF -->|write address/data| WB
```

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
