`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.03.2025 15:07:39
// Design Name:
// Module Name: top
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


module top(
    input clk,input rst,output [31:0] ALU_out
    );
    reg [31:0]IF_ID;
    reg [74:0] ID_EX;
    reg [36:0] EX_MEM;
    reg [36:0] MEM_WB;
   
    reg [31:0] PC;
   
    always @(posedge clk, posedge rst)begin
        if(rst)PC=0;
        else PC<=PC+4;
    end
    wire [31:0] RD;
    instr_mem in1(.ADDR(PC), .RD(RD) );
   
    always@(posedge clk,posedge rst)begin
        if(rst) IF_ID=0;
        else IF_ID<=RD;
    end
   
    wire [4:0] rs,rt,rd;
    assign rs= IF_ID[9:5];
    assign rt= IF_ID[4:0];
    assign rd= IF_ID[14:10];
    wire [4:0] R_D;
    wire [5:0] funct;
    assign funct= IF_ID[20:15];
   
    wire [31:0] WD;
    wire [31:0] RD1,RD2;
    reg_file r1(rst,rs,rt,R_D,WD,RD1,RD2);
   
    always @(posedge clk, posedge rst)begin
        if(rst) ID_EX=0;
        else begin
            ID_EX[74:70]<=rd;
            ID_EX[69:38]<= RD1;
            ID_EX[37:6]<=RD2;
            ID_EX[5:0] <=funct;
        end
    end
//    wire [31:0] ALU_out;
    wire ALU_zero;
    ALU A1(ID_EX[5:0],ID_EX[69:38],ID_EX[37:6],ALU_out,ALU_zero);
    always@(posedge clk,posedge rst)begin
        if(rst)EX_MEM<=0;
        else begin
         EX_MEM[36:32]<=rd;
         EX_MEM[31:0]<=ALU_out;
        end
    end
   
    always @(posedge clk,posedge rst)
    begin
        if(rst) MEM_WB<=0;
        else begin
            MEM_WB[36:32]<=EX_MEM[36:32];
            MEM_WB[31:0]<=EX_MEM[31:0];
        end
    end
   
    assign R_D= MEM_WB[36:32];
    assign WD= MEM_WB[31:0];  
   
endmodule

module instr_mem(input[31:0] ADDR, output reg [31:0] RD);

    always@(*)begin
        case(ADDR)
            32'd0: RD=32'b00000000000000100000110001000001;
            32'd4: RD=32'b00000000000000110001100010100100;
            32'd8: RD=32'b00000000000000111010010100000111;
            32'd12: RD=32'b00000000000000101011000101101010;
        endcase
    end
endmodule


module reg_file(
    input rst,
    input [4:0] RN1,
    input [4:0] RN2,
    input [4:0] WN,
    input [31:0] WD,
    output reg [31:0] RD1,
    output reg [31:0] RD2
);
    reg [31:0] registers [31:0];  

    integer i;
    always @(posedge rst) begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 0;
        end

        registers[1]  = 32'h00000020;
        registers[2]  = 32'h00000039;
        registers[4]  = 32'h00000CF1;
        registers[5]  = 32'h0000B3A1;
        registers[7]  = 32'hAB12459E;
        registers[8]  = 32'hFEC43379;
        registers[10] = 32'hDA32001B;
        registers[11] = 32'hC1452D90;
    end

    always@(RN1)begin
        RD1<=registers[RN1];
    end
    always@(RN2)begin
        RD2<=registers[RN2];
    end
   
    always@(WN,WD)begin
        registers[WN]<=WD;
    end
endmodule


module data_mem(input [31:0] ADDR, input [31:0] WD, output [31:0] RD);
    assign RD=0;
endmodule

module ALU(input [5:0] funct, input [31:0] D1, input [31:0] D2, output reg [31:0] res, output zero);
    always@(*)begin
        case(funct)
            6'b000101: res= (D1 + D2);
            6'b000110 : res=  D1- D2;
            6'b000111 : res=  ~(D1 & D2);
            6'b000100 : res=~(D1|D2);
            default: res=0;
        endcase
    end
    assign zero= |res;
endmodule

