`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:46:32
// Design Name: 
// Module Name: ID_EX_Reg
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


module ID_EX_Reg#(
    parameter ID_EX_size=161   // You can even pass data types!
)(
    input clk,input rst,flush,input [ID_EX_size-1:0] inp, output logic [ID_EX_size-1:0] out 
    );
    
    always_ff@(posedge clk,posedge rst)begin
        if(rst||flush)out<=0;
        else begin
            out<=inp;
        end
    end
endmodule
