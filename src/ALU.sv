`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.03.2026 23:03:46
// Design Name: 
// Module Name: ALU
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
//  ALU
//  Fixes:  == instead of = for zero flag
//          src_a / src_b port names (were scr_a / scr_b)
// ─────────────────────────────────────────────────────────────────
import alu_pkg::*;

module ALU (
    input  logic [31:0] src_a,        // was scr_a - typo fixed
    input  logic [31:0] src_b,        // was scr_b - typo fixed
    input  alu_op_t     alu_control,
    output logic [31:0] alu_result,
    output logic        zero
);

    always_comb begin
        case (alu_control)
            ALU_ADD  : alu_result = src_a + src_b;
            ALU_SUB  : alu_result = src_a - src_b;
            ALU_SLL  : alu_result = src_a << src_b[4:0];
            ALU_SLT  : alu_result = {{31{1'b0}}, $signed(src_a) < $signed(src_b)};
            ALU_SLTU : alu_result = {{31{1'b0}}, src_a < src_b};
            ALU_XOR  : alu_result = src_a ^ src_b;
            ALU_SRL  : alu_result = src_a >> src_b[4:0];
            ALU_SRA  : alu_result = $signed(src_a) >>> src_b[4:0];
            ALU_OR   : alu_result = src_a | src_b;
            ALU_AND  : alu_result = src_a & src_b;
            default  : alu_result = 32'b0;
        endcase
    end

    // BUG FIX: was (alu_result=32'b0) - single = is assignment, not comparison
    assign zero = (alu_result == 32'b0);

endmodule
