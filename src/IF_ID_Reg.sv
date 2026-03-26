`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:46:32
// Design Name: 
// Module Name: IF_ID_Reg
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


module IF_ID_Reg#(
    parameter IF_ID_size=64   // You can even pass data types!
)(
    input clk,input rst,input en,flush, input [IF_ID_size-1:0] inp, output logic [IF_ID_size-1:0] out 
    );
    
    always_ff@(posedge clk,posedge rst)begin
        if(rst || flush)out<=0;
        else if(en)begin
            out<=inp;
        end
    end
endmodule
