`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:31:33
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module control_unit (
    input  logic [6:0]  opcode,
    output logic [12:0] control_sig
);
    // ── Control signal declarations ───────────────────────────────────────
    logic        reg_write;
    logic [1:0]  wb_sel;        // 00 = ALU result, 01 = MEM read, 10 = PC+4
    logic        jal;
    logic        jalr;
    logic        branch;
    logic        mem_read;
    logic        mem_write;
    logic [1:0]  alu_op;
    logic        alu_src_b;     // 0 = register (rs2), 1 = immediate
    logic [1:0]  src_a_sel;     // 00 = rs1, 01 = PC (AUIPC/JAL), 10 = zero (LUI)

    // ── Packing order (MSB → LSB) ─────────────────────────────────────────
    // [12]    = reg_write
    // [11:10] = wb_sel
    // [9]     = jal
    // [8]     = jalr
    // [7]     = branch
    // [6]     = mem_read
    // [5]     = mem_write
    // [4:3]   = alu_op
    // [2]     = alu_src_b
    // [1:0]   = src_a_sel
    assign control_sig = {reg_write, wb_sel, jal, jalr,
                          branch, mem_read, mem_write,
                          alu_op, alu_src_b, src_a_sel};

    always_comb begin
        // Default: all signals off
        {reg_write, wb_sel, jal, jalr, branch,
         mem_read, mem_write, alu_op, alu_src_b, src_a_sel} = '0;

        case (opcode)
            7'b0110011: begin   // R-type  (ADD, SUB, SLL, …)
                reg_write = 1;
                alu_op    = 2'b10;
            end

            7'b0010011: begin   // I-type ALU  (ADDI, XORI, …)
                reg_write = 1;
                alu_op    = 2'b10;
                alu_src_b = 1;
            end

            7'b0000011: begin   // Load  (LW)
                reg_write = 1;
                mem_read  = 1;
                alu_src_b = 1;
                wb_sel    = 2'b01;
            end

            7'b0100011: begin   // Store  (SW)
                mem_write = 1;
                alu_src_b = 1;
            end

            7'b1100011: begin   // Branch  (BEQ / BNE / …)
                branch = 1;
                alu_op = 2'b01;
            end

            7'b0110111: begin   // LUI  -  rd = 0 + U-imm
                reg_write = 1;
                alu_src_b = 1;
                src_a_sel = 2'b10;  // force ALU A = 0
            end

            7'b0010111: begin   // AUIPC  -  rd = PC + U-imm
                reg_write = 1;
                alu_src_b = 1;
                src_a_sel = 2'b01;  // ALU A = PC
            end

            7'b1101111: begin   // JAL  -  rd = PC+4 ; PC = PC + J-imm
                reg_write = 1;
                jal       = 1;
                wb_sel    = 2'b10;  // write back PC+4
                alu_src_b = 1;
                src_a_sel = 2'b01;  // ALU A = PC (computes branch target)
            end

            7'b1100111: begin   // JALR  -  rd = PC+4 ; PC = (rs1+I-imm)&~1
                reg_write = 1;
                jalr      = 1;
                wb_sel    = 2'b10;  // write back PC+4
                alu_src_b = 1;
                // src_a_sel = 00 → ALU A = rs1 → ALU computes rs1+imm
            end
        endcase
    end
endmodule
