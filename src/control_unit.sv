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


module control_unit (
    input  logic [6:0] opcode,
    output logic [7:0] control_sig
);
    logic alu_src, mem_write, mem_read, branch, reg_write, mem_to_reg;   
    logic [1:0] alu_op;    
    assign control_sig={reg_write,mem_to_reg,branch,mem_read,mem_write,alu_op,alu_src};
    always_comb begin
        // Default: No operations
        {alu_src, alu_op, mem_write, mem_read, branch, reg_write, mem_to_reg} = '0;

        case (opcode)
            7'b0110011: begin // R-type
                alu_op = 2'b10; reg_write = 1;
            end
            7'b0010011: begin // I-type
                alu_src = 1; alu_op = 2'b10; reg_write = 1;
            end
            7'b0000011: begin // Load (lw)
                alu_src = 1; mem_read = 1; reg_write = 1; mem_to_reg = 1;
            end
            7'b0100011: begin // Store (sw)
                alu_src = 1; mem_write = 1;
            end
            7'b1100011: begin // Branch (beq)
                branch = 1; alu_op = 2'b01;
            end
        endcase
    end
endmodule
