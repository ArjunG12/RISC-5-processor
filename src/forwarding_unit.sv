`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2026 23:37:24
// Design Name: 
// Module Name: forwarding_unit
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

module forwarding_unit(
    input  logic [4:0] id_ex_rs1, id_ex_rs2,
    input  logic [4:0] ex_mem_rd,  
    input  logic [4:0] mem_wb_rd,
    input  logic       ex_mem_regwrite, mem_wb_regwrite,
    output logic [1:0] forwardA, forwardB
);
    // ForwardA
    always_comb begin
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
            forwardA = 2'b10;   // forward from EX/MEM
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1))
            forwardA = 2'b01;   // forward from MEM/WB
        else
            forwardA = 2'b00;   // no forwarding, use register file
    end
    // ForwardB
    always_comb begin
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2))
            forwardB = 2'b10;
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2))
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end
endmodule
