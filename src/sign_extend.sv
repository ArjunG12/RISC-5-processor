`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:55:34
// Design Name: 
// Module Name: sign_extend
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


module SignExtend(
    input  logic [31:0] instr,   // full instruction word
    output logic [31:0] out
);
    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        case (opcode)
            7'b0010011,          // I-type (ALU immediate)
            7'b0000011:          // I-type (Load)
                out = {{20{instr[31]}}, instr[31:20]};

            7'b0100011:          // S-type (Store)
                out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            7'b1100011:          // B-type (Branch)
                out = {{19{instr[31]}}, instr[31], instr[7],
                        instr[30:25], instr[11:8], 1'b0};

            7'b0110111,          // U-type (LUI)
            7'b0010111:          // U-type (AUIPC)
                out = {instr[31:12], 12'b0};

            7'b1101111:          // J-type (JAL)
                out = {{11{instr[31]}}, instr[31], instr[19:12],
                        instr[20], instr[30:21], 1'b0};

            default: out = 32'b0;
        endcase
    end
endmodule