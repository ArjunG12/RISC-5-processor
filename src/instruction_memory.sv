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

    logic [7:0] instr_mem [1023:0]; 

    initial begin
        for (int i = 0; i < 256; i++) begin
            instr_mem[i] = i * 15; 
        end
        
    end
    
    assign RD = { instr_mem[{PC[9:2],2'b11}],   // byte 3 → MSB
                  instr_mem[{PC[9:2],2'b10}],
                  instr_mem[{PC[9:2],2'b01}],
                  instr_mem[{PC[9:2],2'b00}] };  // byte 0 → LSB
endmodule
