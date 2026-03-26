`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:57:09
// Design Name: 
// Module Name: PC
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


module PC(
    input clk, reset, PCWrite,
    input [31:0] pc_in,
    output reg [31:0] pc_out
    );
    
    always @(posedge clk) begin
    if (reset)
    pc_out <= 32'b0;
    else if (PCWrite)
    pc_out <= pc_in;
    end
endmodule
