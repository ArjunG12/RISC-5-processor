`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2026 23:37:06
// Design Name: 
// Module Name: hazard_unit
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

module hazard_unit(
    // From ID/EX register
    input  logic       id_ex_MemRead,
    input  logic [4:0] id_ex_rd,
    // From IF/ID register (the following instruction's source registers)
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,
    // Stall outputs
    output logic       PCWrite,        // 0 = freeze PC
    output logic       IF_ID_Write,    // 0 = freeze IF/ID register
    output logic       control_flush   // 1 = zero out ID/EX control signals (insert bubble)
);
    always_comb begin
        if (id_ex_MemRead &&
        (id_ex_rd != 5'b0)&&
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            PCWrite       = 1'b0;   // hold PC
            IF_ID_Write   = 1'b0;   // hold IF/ID (re-decode same instruction next cycle)
            control_flush = 1'b1;   // insert NOP bubble into ID/EX
        end else begin
            PCWrite       = 1'b1;
            IF_ID_Write   = 1'b1;
            control_flush = 1'b0;
        end
    end
endmodule
