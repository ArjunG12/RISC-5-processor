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
    input  logic        clk,
    input  logic        rst,
    input  logic [11:0] byte_addr,      // full byte address from ALU result
    input  logic [31:0] write_data,     // pre-shifted by MEM stage
    input  logic [3:0]  byte_en,        // per-byte write enable; 4'b0 = no write
    input  logic        mem_read,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:1023];          // 1024 words = 4 KB

    logic [9:0] word_addr;
    assign word_addr = byte_addr[11:2]; // byte_addr[1:0] handled by MEM/WB stage

    // Combinational read - correct for this 5-stage pipeline with load-use stalls
    always_comb
        read_data = mem_read ? mem[word_addr] : 32'b0;

    // Synchronous byte-enable write
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            foreach (mem[i]) mem[i] <= 32'b0;
        end else begin
            if (byte_en[0]) mem[word_addr][ 7: 0] <= write_data[ 7: 0];
            if (byte_en[1]) mem[word_addr][15: 8] <= write_data[15: 8];
            if (byte_en[2]) mem[word_addr][23:16] <= write_data[23:16];
            if (byte_en[3]) mem[word_addr][31:24] <= write_data[31:24];
        end
    end
endmodule
