`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03.03.2026 15:08:11
// Design Name:
// Module Name: instruction_memory
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

module instruction_memory #(
    parameter INIT_FILE = "C:/Users/goela/risc_5/risc_5.sim/program.hex"
) (
    input  logic [31:0] PC,
    output logic [31:0] RD
);

    logic [31:0] instr_mem [1023:0];
    logic [9:0]  word_addr;

    initial begin
        $readmemh(INIT_FILE, instr_mem);
    end

    assign word_addr = PC[11:2];
    assign RD = instr_mem[word_addr];  // byte 0 -> LSB
endmodule
