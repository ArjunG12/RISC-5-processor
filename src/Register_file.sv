`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.03.2026 22:51:22
// Design Name: 
// Module Name: Register_file
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


module Register_file(
    input clk,input rst, input [4:0] RN1, input [4:0] RN2, input [4:0] WN, input [31:0] WD, input RegWrite, output logic [31:0] RD1, output logic [31:0] RD2
    );
    reg [31:0] registers [31:0];
    always_ff@(posedge clk,posedge rst)begin
        if(rst)foreach(registers[i])registers[i]<=0;
        else if(RegWrite &&  WN != 5'b0) registers[WN]<=WD;
    end
    
    always_comb begin
        RD1 = (RN1 == 5'b0)                       ? 32'b0 :
              (RegWrite && WN == RN1 && WN != 5'b0) ? WD    :
                                                       registers[RN1];
        RD2 = (RN2 == 5'b0)                       ? 32'b0 :
              (RegWrite && WN == RN2 && WN != 5'b0) ? WD    :
                                                       registers[RN2];
    end
    
endmodule
