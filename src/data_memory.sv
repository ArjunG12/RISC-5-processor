`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.03.2026 23:43:24
// Design Name: 
// Module Name: data_memory
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


module data_memory (
    input  logic  clk,
    input logic rst,
    input  logic [9:0] address,
    input  logic [31:0] write_data,
    input  logic mem_write,
    input logic mem_read,
    output logic [31:0] read_data
);

    logic [31:0] mem [0:(1<<10)-1];

    
    always_comb begin
    
        if(mem_read)read_data = mem[address];
        else read_data=0;
    end

    
    always_ff @(posedge clk,posedge rst) begin
        if(rst) foreach(mem[i])mem[i]<=0;
        else if (mem_write) begin
            mem[address] <= write_data;
        end
    end

endmodule
