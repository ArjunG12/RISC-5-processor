# RISC-V 5-Stage Pipelined Processor

A fully functional 32-bit RISC-V (RV32I subset) processor implemented in SystemVerilog, featuring a classic 5-stage pipeline with complete hazard handling, data forwarding, and FPGA-ready memory interfaces.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
- [Hazard Handling](#hazard-handling)
- [Supported Instructions](#supported-instructions)
- [Module Breakdown](#module-breakdown)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Running Simulation](#running-simulation)
- [FPGA Synthesis (Xilinx Vivado)](#fpga-synthesis-xilinx-vivado)
- [Simulation & Verification](#simulation--verification)
- [Known Limitations](#known-limitations)
- [Design Decisions](#design-decisions)

---

## Overview

This project implements a 5-stage pipelined RISC-V processor targeting the RV32I base integer instruction set. The design prioritises correctness and readability, and is structured to synthesise cleanly onto Xilinx 7-series and UltraScale FPGAs using BRAM primitives for both instruction and data memory.

**Key features:**

- 5-stage pipeline: IF → ID → EX → MEM → WB
- Full data forwarding (EX/MEM → EX, MEM/WB → EX) eliminating most data hazards without stalling
- Load-use hazard detection with automatic 1-cycle stall insertion
- Branch resolution in the MEM stage with 3-stage pipeline flush
- Single-cycle ALU supporting all RV32I arithmetic, logical, and shift operations
- Parameterised pipeline register widths
- `mark_debug` annotations on key signals for Vivado ILA integration

---

## Architecture
<img width="5284" height="3644" alt="image" src="https://github.com/user-attachments/assets/4212392c-a290-4240-87c8-76bdb09d8a9a" />

The datapath diagram is included in `docs/riscv_datapath.pdf`.

---

## Pipeline Stages

| Stage | Register | Width | Key Operations |
|-------|----------|-------|----------------|
| IF    | IF/ID    | 64 bits  | PC fetch, instruction memory read |
| ID    | ID/EX    | 161 bits | Register file read, sign-extend, control decode |
| EX    | EX/MEM   | 107 bits | ALU operation, branch target compute, forwarding |
| MEM   | MEM/WB   | 71 bits  | Data memory read/write, branch resolution |
| WB    | —        | —     | Write-back to register file |

---

## Hazard Handling

### Data Hazards — Forwarding Unit

The forwarding unit eliminates the majority of data hazards by routing results directly from later pipeline stages back to the EX stage ALU inputs. Forwarding priority is strictly enforced:

1. **EX/MEM forward (forwardA/B = 10)** — taken first; the in-flight EX result is the most recent.
2. **MEM/WB forward (forwardA/B = 01)** — taken only when EX/MEM does not match, avoiding a stale overwrite.
3. **Register file (forwardA/B = 00)** — no hazard; use the value read in ID.

Both forwarding paths correctly guard against writes to `x0`.

### Load-Use Hazards — Hazard Detection Unit

When a `LOAD` instruction is in EX and the immediately following instruction reads the load destination, a 1-cycle stall is inserted:

- `PCWrite = 0` — freezes the program counter.
- `IF_ID_Write = 0` — freezes the IF/ID register (re-presents the same instruction for decode).
- `control_flush = 1` — zeros the ID/EX control signals, inserting a NOP bubble.

The x0 register is excluded from hazard checks.

### Control Hazards — Branch Flush

Branches are resolved in the MEM stage using the ALU zero flag and the Branch control bit. When a branch is taken (`PCSource = 1`):

- The PC is loaded with the branch target (`pc_branch_mem`).
- IF/ID, ID/EX, and EX/MEM pipeline registers are flushed to zero on the next rising edge.

> **Note on stall + branch coincidence:** `PCWrite` is overridden by `PCSource` so that a simultaneous load-use stall never blocks a taken branch from updating the PC.

---

## Supported Instructions

| Category | Instructions |
|----------|-------------|
| R-type   | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I-type ALU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| Load     | LW |
| Store    | SW |
| Branch   | BEQ |
| — | JAL, JALR, LUI, AUIPC not yet implemented (see [Known Limitations](#known-limitations)) |

The `SignExtend` module correctly handles all five RISC-V immediate formats: I, S, B, U, and J.

---

## Module Breakdown

| Module | File | Description |
|--------|------|-------------|
| `top` | `top.sv` | Top-level integration; all pipeline stages wired |
| `PC` | `PC.sv` | Program counter register with synchronous load enable |
| `instruction_memory` | `instruction_memory.sv` | 256-entry instruction ROM; initialised via `$readmemh` |
| `IF_ID_Reg` | `IF_ID_Reg.sv` | 64-bit pipeline register with enable and flush |
| `control_unit` | `control_unit.sv` | Opcode → 8-bit control word decoder |
| `Register_file` | `Register_file.sv` | 32×32 register file; combinational read with WB forwarding |
| `SignExtend` | `SignExtend.sv` | Full RV32I immediate decoder (I/S/B/U/J) |
| `ID_EX_Reg` | `ID_EX_Reg.sv` | 161-bit pipeline register with flush |
| `ALU` | `ALU.sv` | 32-bit ALU; all RV32I ops via `alu_pkg` typedef |
| `ALU_control` | `ALU_control.sv` | func7/func3/ALUOp → 4-bit ALU control decoder |
| `EX_MEM_Reg` | `EX_MEM_Reg.sv` | 107-bit pipeline register with flush |
| `data_memory` | `data_memory.sv` | 1024-entry data RAM; synchronous read and write |
| `MEM_WB_Reg` | `MEM_WB_Reg.sv` | 71-bit pipeline register |
| `hazard_unit` | `hazard_unit.sv` | Load-use hazard detection; drives PCWrite, IF_ID_Write, control_flush |
| `forwarding_unit` | `forwarding_unit.sv` | EX/MEM and MEM/WB forwarding logic for ALU operands |
| `alu_pkg` | `alu_pkg.sv` | Package defining `alu_op_t` typedef and all ALU/ALUOp constants |

---

## Project Structure

```
.
├── src/
│   ├── top.sv                  # Top-level integration
│   ├── alu_pkg.sv              # ALU control package (import first)
│   ├── PC.sv                   # Program counter
│   ├── instruction_memory.sv   # Instruction ROM
│   ├── IF_ID_Reg.sv            # IF/ID pipeline register
│   ├── control_unit.sv         # Main control decoder
│   ├── Register_file.sv        # 32×32 register file
│   ├── SignExtend.sv           # Immediate sign-extension
│   ├── ID_EX_Reg.sv            # ID/EX pipeline register
│   ├── ALU.sv                  # 32-bit ALU
│   ├── ALU_control.sv          # ALU control decoder
│   ├── EX_MEM_Reg.sv           # EX/MEM pipeline register
│   ├── data_memory.sv          # Data RAM
│   ├── MEM_WB_Reg.sv           # MEM/WB pipeline register
│   ├── hazard_unit.sv          # Load-use hazard detection
│   └── forwarding_unit.sv      # Data forwarding logic
├── sim/
│   ├── tb_top.sv               # Testbench
│   └── program.hex             # Assembled RV32I test program (hex)
│   └── tb.wcfg                 # Output waveform containing registers and data memory
├── docs/
│   └── riscv_datapath.pdf      # Pipeline datapath and control diagram
└── README.md
```

---

## Getting Started

### Prerequisites

- **Simulation:** ModelSim, QuestaSim, Icarus Verilog (≥ 11), or Vivado Simulator
- **Synthesis:** Xilinx Vivado 2022.x or later (for BRAM inference)
- **Assembler:** [RARS](https://github.com/TheThirdOne/rars) or any RV32I assembler to produce `.hex` files

### Cloning

```bash
git clone https://github.com/<your-username>/riscv-5stage-pipeline.git
cd riscv-5stage-pipeline
```

### Loading a Program

Assemble your RISC-V program to a hex file and place it in `sim/`:

```bash
# Using RARS to export a memory dump in hex format
# File → Dump Memory → Hexadecimal Text → save as sim/program.hex
```

The instruction memory initialises from `program.hex` via `$readmemh`. Update the path in `instruction_memory` if needed.

---

## Running Simulation

### Vivado Simulator

1. Create a new Vivado project and add all files under `src/` and `sim/`.
2. Set `tb_top.sv` as the simulation top.
3. Run Behavioral Simulation.
4. Monitor `debug_pc` to trace fetch addresses. Use the ILA if synthesising to hardware.

### Icarus Verilog

```bash
iverilog -g2012 -o sim.out \
  src/alu_pkg.sv \
  src/PC.sv \
  src/instruction_memory.sv \
  src/IF_ID_Reg.sv \
  src/control_unit.sv \
  src/Register_file.sv \
  src/SignExtend.sv \
  src/ID_EX_Reg.sv \
  src/ALU.sv \
  src/ALU_control.sv \
  src/EX_MEM_Reg.sv \
  src/data_memory.sv \
  src/MEM_WB_Reg.sv \
  src/hazard_unit.sv \
  src/forwarding_unit.sv \
  src/top.sv \
  sim/tb_top.sv
vvp sim.out
```

### QuestaSim / ModelSim

```tcl
vlib work
vlog -sv src/alu_pkg.sv \
         src/PC.sv \
         src/instruction_memory.sv \
         src/IF_ID_Reg.sv \
         src/control_unit.sv \
         src/Register_file.sv \
         src/SignExtend.sv \
         src/ID_EX_Reg.sv \
         src/ALU.sv \
         src/ALU_control.sv \
         src/EX_MEM_Reg.sv \
         src/data_memory.sv \
         src/MEM_WB_Reg.sv \
         src/hazard_unit.sv \
         src/forwarding_unit.sv \
         src/top.sv \
         sim/tb_top.sv
vsim tb_top
run -all
```

---

## FPGA Synthesis (Xilinx Vivado)

Both memories are coded for BRAM inference:

- **Synchronous read** in `always_ff` blocks — required for Xilinx RAMB18/RAMB36 primitives.
- **No mass-reset** on memory arrays — BRAM primitives do not support synchronous reset; initialisation is handled via `$readmemh` / `.mif` / `.coe`.

After synthesis, confirm in the Utilization report that both memories appear under **Block RAM Tile** and not under **Slice LUTs**. If they appear as LUT RAM, verify no combinational read paths remain.

The `(* mark_debug = "true" *)` attributes on `pc_out`, `write_reg`, `write_reg_data`, and `alu_result_ex` enable direct ILA probing in Vivado without modifying the netlist.

---

## Simulation & Verification

### Test 5 — Array Sum Loop ✅

The processor has been verified against **Test 5**, a comprehensive integration test that exercises the following features simultaneously:

- `SW` / `LW` — word-granularity store and load
- **Load-use hazard stalls** — the `LW → ADD` dependency triggers the hazard unit every loop iteration, inserting a 1-cycle bubble and verifying that `PCWrite` and `IF_ID_Write` are correctly de-asserted
- **Data forwarding** — `ADD x10, x10, x8` uses the MEM/WB forwarding path after the stall resolves
- **Taken BEQ branches** — the unconditional back-branch (`beq x0, x0, loop5`) flushes three pipeline stages on every iteration, exercising the full branch-flush path
- `ADDI` with positive and zero immediates for counter / accumulator initialisation

**Program summary:**

```asm
# Store array {10, 20, 30, 40, 50} into mem[0..16]
addi x1,x0,10  ;  addi x2,x0,20  ;  addi x3,x0,30
addi x4,x0,40  ;  addi x5,x0,50
sw x1,0(x0) ; sw x2,4(x0) ; sw x3,8(x0) ; sw x4,12(x0) ; sw x5,16(x0)

# Loop: accumulate sum in x10
addi x6,x0,0   # base pointer
addi x7,x0,20  # end pointer
addi x10,x0,0  # accumulator
loop5:
    beq  x6, x7, done5   # exit when pointer reaches end
    lw   x8, 0(x6)       # load-use hazard: 1 stall inserted
    add  x10, x10, x8    # accumulate
    addi x6, x6, 4       # advance pointer
    beq  x0, x0, loop5   # unconditional back-branch (3-cycle flush)
done5:
    sw  x10, 24(x0)      # store result
    lw  x11, 24(x0)      # reload (load-use stall)
    addi x12, x11, 0     # copy
```

**Result:** `x10 = 10 + 20 + 30 + 40 + 50 = 150` ✅
<img width="1483" height="316" alt="image" src="https://github.com/user-attachments/assets/f5fa8176-27ff-4bba-a9c3-dacf3e7f1d43" />

The final value of `150` was confirmed in simulation via both the register file (`x10 = 0x00000096`) and the memory writeback at address `24` (`mem[24] = 0x00000096`).

---

## Known Limitations

The following instructions are **not yet implemented** and will execute as NOPs (all control signals zero):

- `JAL` / `JALR` — requires a third PC mux input and a link-register write path
- `LUI` / `AUIPC` — requires bypassing the ALU or adding a dedicated upper-immediate adder
- `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` — only `BEQ` is currently supported; other branch types need an expanded branch condition unit
- Byte and halfword memory operations (`LB`, `LH`, `LBU`, `LHU`, `SB`, `SH`) — memory currently operates at word (32-bit) granularity only

Branch resolution occurs in the **MEM stage**, resulting in a 3-cycle penalty on every taken branch. Moving resolution to the EX stage would reduce this to 1 cycle and is a planned improvement.

---

## Design Decisions

**Why resolve branches in MEM rather than EX?**
Resolving in EX requires forwarding the branch comparator result and the branch target before the EX/MEM register is written, which adds a combinational path between the forwarding mux outputs and the PC. Resolving in MEM is simpler for a first implementation and trades hardware complexity for a predictable 3-cycle flush penalty.

**Why use an 8-bit control word packed as a single bus?**
Packing control signals into a single vector simplifies the pipeline register interfaces — each register stores and forwards one bus rather than a named set of individual wires. Bit-field assignments (`control_sig_ex[2:1]`, etc.) are explicitly documented in the top-level comments and verified against the control unit packing order.

**Why keep `func7` zeroed for most I-type instructions?**
The RV32I encoding reuses the `func7` field as the upper 7 bits of the immediate for I-type instructions. Zeroing `func7` allows the same `ALU_control` decoder to handle both R-type and I-type without a separate decode path. The exception is `SRAI` (func3=101, bit[30]=1), which preserves `func7[5]` to distinguish arithmetic from logical right shift.
