// File: pipe_MIPS32.v
// Author: Senior RTL Design Engineer
// Description: Behavioral baseline implementation of a 5-stage MIPS32
//              pipeline using a dual-clock scheme. The module models the
//              fetch, decode, execute, memory, and write-back stages with
//              pipeline register storage and instruction memory access.
// Hierarchy: Top-level pipeline core
// Version History:
//   v1.0.0 - 2026-09-22 - Initial baseline documentation for the NPTEL flow
// Clock Domains:
//   clk1: posedge used for IF and EX stages
//   clk2: posedge used for ID and MEM stages
//   Write-back is performed on clk1 to preserve the original design flow
// Critical Timing:
//   This baseline model intentionally retains the original simulation delays
//   (#2) and is kept behavioral-only for this phase.

module pipe_MIPS32 (clk1, clk2);

  input clk1, clk2;

  // Program Counter and IF/ID pipeline registers.
  // These signals carry the fetched instruction and the next PC value from
  // the fetch stage into the decode stage.
  reg [31:0] PC, IF_ID_IR, IF_ID_NPC;

  // ID/EX pipeline registers.
  // The decoded instruction, operand values, immediate, and operation type are
  // passed to the execute stage for ALU or branch evaluation.
  reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
  reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;

  // EX/MEM pipeline registers.
  // This stage captures ALU results, memory addresses, branch decision,
  // and the data that will be written back to memory or register file.
  reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
  reg EX_MEM_cond;

  // MEM/WB pipeline registers.
  // Memory read data and ALU results are latched here before the final
  // write-back update to the register bank.
  reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

  // Register bank and instruction/data memory used by the baseline CPU model.
  // The memory is modeled as a 1K-word array and is accessed behaviorally.
  reg [31:0] Reg[0:31];
  reg [31:0] Mem[0:1023];

  parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
            SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111,
            LW = 6'b001000, SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
            BNEQZ = 6'b001101, BEQZ = 6'b001110;

  parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011,
            BRANCH = 3'b100, HALT = 3'b101;

  // Pipeline control flags.
  // HALTED stops instruction fetch and execution, while TAKEN_BRANCH captures
  // whether the current branch should redirect the PC.
  reg HALTED;
  reg TAKEN_BRANCH;

  // IF Stage:
  // Fetch the instruction from memory, update the PC, and redirect the flow
  // when a previously resolved branch is taken.
  always @(posedge clk1) // IF Stage
    if (HALTED == 0)
    begin
      if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
        begin
          IF_ID_IR <= #2 Mem[EX_MEM_ALUOut];
          TAKEN_BRANCH <= #2 1'b1;
          IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;
          PC <= #2 EX_MEM_ALUOut + 1;
        end
      else
        begin
          IF_ID_IR <= #2 Mem[PC];
          IF_ID_NPC <= #2 PC + 1;
          PC <= #2 PC + 1;
        end
    end

  // ID Stage:
  // Read the register operands, sign-extend the immediate value, and classify
  // the instruction type for the next execute stage.
  always @(posedge clk2) // ID Stage
    if (HALTED == 0)
    begin
      if (IF_ID_IR[25:21] == 5'b00000)
        ID_EX_A <= 0;
      else
        ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];

      if (IF_ID_IR[20:16] == 5'b00000)
        ID_EX_B <= 0;
      else
        ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];

      ID_EX_NPC <= #2 IF_ID_NPC;
      ID_EX_IR <= #2 IF_ID_IR;
      ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};

      case (IF_ID_IR[31:26])
        ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= #2 RR_ALU;
        ADDI, SUBI, SLTI: ID_EX_type <= #2 RM_ALU;
        LW: ID_EX_type <= #2 LOAD;
        SW: ID_EX_type <= #2 STORE;
        BNEQZ, BEQZ: ID_EX_type <= #2 BRANCH;
        HLT: ID_EX_type <= #2 HALT;
        default: ID_EX_type <= #2 HALT; // invalid opcode
      endcase
    end

  // EX Stage:
  // Perform arithmetic, logical, memory address calculation, and branch
  // condition evaluation based on the decoded instruction type.
  always @(posedge clk1) // EX Stage
    if (HALTED == 0)
    begin
      EX_MEM_type <= #2 ID_EX_type;
      EX_MEM_IR <= #2 ID_EX_IR;
      TAKEN_BRANCH <= #2 1'b0;

      case (ID_EX_type)
        RR_ALU: begin
          case (ID_EX_IR[31:26])
            ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
            SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
            AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
            OR:  EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
            SLT: EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_B) ? 1 : 0;
            MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
            default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; // invalid opcode
          endcase
        end

        RM_ALU: begin
          case (ID_EX_IR[31:26])
            ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
            SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
            SLTI: EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_Imm) ? 1 : 0;
            default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; // invalid opcode
          endcase
        end

        LOAD, STORE:
          begin
            EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
            EX_MEM_B <= #2 ID_EX_B;
          end

        BRANCH:
          begin
            EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
            EX_MEM_cond <= #2 (ID_EX_A == 0) ? 1'b1 : 1'b0;
          end
      endcase

    end

  // MEM Stage:
  // Complete data memory accesses for load/store instructions and propagate the
  // ALU result or memory value to the write-back pipeline stage.
  always @(posedge clk2) // MEM Stage
   if (HALTED == 0)
    begin
      MEM_WB_type <= #2 EX_MEM_type;
      MEM_WB_IR <= #2 EX_MEM_IR;

      case (EX_MEM_type)
        RR_ALU, RM_ALU:
          MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;

        LOAD:
          MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];

        STORE:
          if (TAKEN_BRANCH == 1'b0)
            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;

      endcase
    end

  // WB Stage:
  // Update the register file with ALU results or memory reads, and stop the
  // pipeline when a HLT instruction is encountered.
  always @(posedge clk1) // WB Stage
    begin
      if (TAKEN_BRANCH == 1'b0)
        case (MEM_WB_type)
          RR_ALU:
            Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut;

          RM_ALU:
            Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut;

          LOAD:
            Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;

          HALT:
            HALTED <= #2 1'b1;
        endcase
    end

endmodule
