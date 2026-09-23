// File: tb_ejemplo1.v
// Author: Senior RTL Design Engineer
// Description: Testbench for the baseline MIPS32 pipeline. It initializes a
//              small instruction sequence in memory, drives the dual-clock
//              timing pattern, and prints the final register file values.
// Hierarchy: Testbench -> pipe_MIPS32
// Version History:
//   v1.0.0 - 2026-09-22 - Initial baseline documentation for the NPTEL flow
// Clock Domains:
//   clk1 and clk2 are toggled with a 10 ns period; each phase is asserted
//   for 5 ns to match the original dual-clock pipeline timing model.
// Critical Timing:
//   This testbench preserves the baseline behavioral timing and does not
//   alter the original RTL execution semantics.

module tb_ejemplo1;

  // Clock and loop control signals.
  reg clk1, clk2;
  integer k, i;

  // Instantiate the DUT under test.
  pipe_MIPS32 mips(clk1, clk2);

  // Clock generation:
  // The baseline design uses two phase clocks. Each half-cycle toggles a
  // different signal to emulate the IF/ID/EX/MEM/WB timing relationship.
  initial
    begin
      clk1 = 0; clk2 = 0;
      repeat (20)
        begin
          #5 clk1 = 1; #5 clk1 = 0;
          #5 clk2 = 1; #5 clk2 = 0;
        end
    end

  // Program initialization:
  // This instruction sequence exercises simple arithmetic and a halt condition.
  // It initializes the register file and loads a small set of MIPS-like
  // instructions into memory.
  initial
    begin
      for (k = 0; k < 32; k = k + 1)
        mips.Reg[k] = k;

      mips.Mem[0] = 32'h2801000a; // ADDI R1, R0, 10
      mips.Mem[1] = 32'h28020014; // ADDI R2, R0, 20
      mips.Mem[2] = 32'h28030019; // ADDI R3, R0, 25
      mips.Mem[3] = 32'h0ce77800; // OR R7, R7, R15; -- dummy instr
      mips.Mem[4] = 32'h0ce77800; // OR R7, R7, R15; -- dummy instr
      mips.Mem[5] = 32'h00222000; // ADD R4, R1, R2
      mips.Mem[6] = 32'h0ce77800; // OR R7, R7, R15; -- dummy instr
      mips.Mem[7] = 32'h00832800; // ADD R5, R4, R3
      mips.Mem[8] = 32'hfc000000; // HLT

      mips.HALTED = 0;
      mips.PC = 0;
      mips.TAKEN_BRANCH = 0;

      #280
      for (k = 0; k < 32; k = k + 1)
        $display("R%2d: %2d", k, mips.Reg[k]);

    end

  // Waveform dump:
  // Store the simulation activity for debugging and visual inspection of the
  // pipeline state and register updates.
  initial
    begin
      $dumpfile("tb_ejemplo1.vcd");
      $dumpvars(0, tb_ejemplo1);
      for (i = 0; i < 31; i = i + 1)
      begin
        $dumpvars(0, mips.Reg[i]);
      end
    end

endmodule
