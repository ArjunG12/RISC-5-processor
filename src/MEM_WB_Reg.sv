`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:46:32
// Design Name: 
// Module Name: MEM_WB_Reg
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


module MEM_WB_Reg#(
    parameter MEM_WB_size=71   // You can even pass data types!
)(
    input clk,input rst,input [MEM_WB_size-1:0] inp, output logic [MEM_WB_size-1:0] out 
    );
    
    always_ff@(posedge clk,posedge rst)begin
        if(rst)out<=0;
        else begin
            out<=inp;
        end
    end
endmodule
