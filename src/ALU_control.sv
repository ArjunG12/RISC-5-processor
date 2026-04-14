`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2026 02:18:18
// Design Name: 
// Module Name: ALU_control
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
// ─────────────────────────────────────────────────────────────────
//  ALU operation codes - shared package
//  Include this in both files with `import alu_pkg::*;`
// ─────────────────────────────────────────────────────────────────
package alu_pkg;

    // 4-bit ALU control codes (match ALU case statement exactly)
    typedef logic [3:0] alu_op_t;

    localparam alu_op_t ALU_ADD  = 4'b0000;
    localparam alu_op_t ALU_SUB  = 4'b1000;
    localparam alu_op_t ALU_SLL  = 4'b0001;
    localparam alu_op_t ALU_SLT  = 4'b0010;
    localparam alu_op_t ALU_SLTU = 4'b0011;
    localparam alu_op_t ALU_XOR  = 4'b0100;
    localparam alu_op_t ALU_SRL  = 4'b0101;
    localparam alu_op_t ALU_SRA  = 4'b1101;
    localparam alu_op_t ALU_OR   = 4'b0110;
    localparam alu_op_t ALU_AND  = 4'b0111;
    localparam alu_op_t ALU_UNDEF = 4'b1111;

    // ALUOp encoding from control unit
    localparam logic [1:0] ALUOP_ADD    = 2'b00; // load / store
    localparam logic [1:0] ALUOP_SUB    = 2'b01; // branch (BEQ)
    localparam logic [1:0] ALUOP_RTYPE  = 2'b10; // R-type / I-type ALU

    // {func7[6:0], func3[2:0]} decode keys
    localparam logic [9:0] F_ADD  = {7'b0000000, 3'b000};
    localparam logic [9:0] F_SUB  = {7'b0100000, 3'b000};
    localparam logic [9:0] F_SLL  = {7'b0000000, 3'b001};
    localparam logic [9:0] F_SLT  = {7'b0000000, 3'b010};
    localparam logic [9:0] F_SLTU = {7'b0000000, 3'b011};
    localparam logic [9:0] F_XOR  = {7'b0000000, 3'b100};
    localparam logic [9:0] F_SRL  = {7'b0000000, 3'b101};
    localparam logic [9:0] F_SRA  = {7'b0100000, 3'b101};
    localparam logic [9:0] F_OR   = {7'b0000000, 3'b110};
    localparam logic [9:0] F_AND  = {7'b0000000, 3'b111};

endpackage

// ─────────────────────────────────────────────────────────────────
//  ALU_control
// ─────────────────────────────────────────────────────────────────
import alu_pkg::*;

module ALU_control (
    input  logic [6:0] func7,
    input  logic [2:0] func3,
    input  logic [1:0] ALU_op,
    output alu_op_t    ALU_control
);

    always_comb begin
        case (ALU_op)

            ALUOP_ADD: ALU_control = ALU_ADD;   // load / store addr calc

            ALUOP_SUB: begin                          // branch instructions
                case (func3)
                    3'b000, 3'b001: ALU_control = ALU_SUB;   // BEQ, BNE  → check zero
                    3'b100, 3'b101: ALU_control = ALU_SLT;   // BLT, BGE  → signed compare
                    3'b110, 3'b111: ALU_control = ALU_SLTU;  // BLTU, BGEU → unsigned compare
                    default:        ALU_control = ALU_SUB;
                endcase
            end

            ALUOP_RTYPE: begin
                // For I-type ALU (opcode 0010011) the top-level zeroes func7,
                // so SUB and SRA are R-type only - that is intentional.
                case ({func7, func3})
                    F_ADD  : ALU_control = ALU_ADD;
                    F_SUB  : ALU_control = ALU_SUB;
                    F_SLL  : ALU_control = ALU_SLL;
                    F_SLT  : ALU_control = ALU_SLT;
                    F_SLTU : ALU_control = ALU_SLTU;
                    F_XOR  : ALU_control = ALU_XOR;
                    F_SRL  : ALU_control = ALU_SRL;
                    F_SRA  : ALU_control = ALU_SRA;
                    F_OR   : ALU_control = ALU_OR;
                    F_AND  : ALU_control = ALU_AND;
                    default: ALU_control = ALU_UNDEF;
                endcase
            end

            default: ALU_control = ALU_ADD;  // safe fallback

        endcase
    end

endmodule
