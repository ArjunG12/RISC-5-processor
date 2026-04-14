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


module instruction_memory (
    input  logic [31:0] PC,
    output logic [31:0] RD
);

    logic [31:0] instr_mem [1023:0]; 

    initial begin
            $readmemh("C:/Users/goela/risc_5/risc_5.sim/bge_test.hex", instr_mem); // ← replaces the dummy loop
        end
    
    
    assign RD = instr_mem[PC[9:2]];  // byte 0 → LSB
endmodule
