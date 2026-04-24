`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 04:37:56
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
    input clk,rst,output logic [31:0] debug_pc       
    );
            parameter IF_ID_size=64, ID_EX_size=166, EX_MEM_size=142, MEM_WB_size=107;

    //control signals
    logic PCSource,branch_flush, PCWrite,ALUSrc,ALUOp1,ALUOp0,Branch,MemRead,MemWrite,RegWrite,IF_ID_Write,control_flush;
    
    //ALL declerations
    // ─── Global / Cross-stage ────────────────────────────────────────────
        (* mark_debug = "true" *)logic [4:0]  write_reg;           // WB → ID (register file write port)
        (* mark_debug = "true" *) logic [31:0] write_reg_data;      // WB → ID (register file write data)
        logic [1:0]  forwardA, forwardB;  // Forwarding unit → EX muxes
        logic [31:0] WB_RD;               // WB  → forwarding mux (MEM/WB result)
        logic [31:0] MEM_RD;              // MEM → forwarding mux (EX/MEM result)
        
        assign branch_flush=PCSource;
        // ─── IF Stage ────────────────────────────────────────────────────────
        (* mark_debug = "true" *)logic [31:0] pc_out;              // PC register output
        logic [31:0] pc_next;             // pc_out + 4
        logic [31:0] pc_branch;           // branch target (from MEM stage)
        logic [31:0] instr;               // instruction memory output
        assign debug_pc = pc_out;
        // ─── IF/ID Pipeline Register outputs ─────────────────────────────────
        logic [31:0] pc_out_id;           // PC (not PC+4) for branch base
        logic [31:0] instr_id;            // fetched instruction word
    
        // ─── ID Stage ────────────────────────────────────────────────────────
        logic [4:0]  rs1_id, rs2_id,write_reg_id;      // decoded source register addresses
        logic [4:0]  if_id_rs1, if_id_rs2;// aliases fed to hazard unit
        logic [31:0] RD1_id, RD2_id;      // register file read data
        logic [31:0] sign_extend_out_id;  // sign-extended immediate
        logic [6:0]  func7_id;            // func7 field (or zeroed for I-type)
        logic [2:0]  func3_id;            // func3 field
        logic [12:0]  control_sig_id;      // raw control unit output
        logic [12:0]  control_sig_to_idex; // control after hazard flush mux
        
        // ─── Hazard Unit signals ──────────────────────────────────────────────
        logic        id_ex_MemRead;       // tapped from control_sig_ex[4]
        logic [4:0]  id_ex_rd;            // tapped from write_reg_ex
    
        assign if_id_rs1   = instr_id[19:15];
        assign if_id_rs2   = instr_id[24:20];
        assign id_ex_MemRead = control_sig_ex[6];  // bit[4] = MemRead
        assign id_ex_rd    = write_reg_ex;
    
        // ─── ID/EX Pipeline Register outputs ─────────────────────────────────
        logic [12:0]  control_sig_ex;      // 9 control bits in EX stage (note: was 8, +1 for MemToReg)
        logic [31:0] pc_out_ex;           // PC passed through for branch calc
        logic [31:0] RD1_ex, RD2_ex;      // forwarded register read data
        logic [31:0] sign_extend_out_ex;  // sign-extended immediate
        logic [4:0]  write_reg_ex;        // destination register (rd)
        logic [4:0]  id_ex_rs1, id_ex_rs2;// source registers for forwarding unit
        logic [6:0]  func7_ex;
        logic [2:0]  func3_ex;
    
        // ─── EX Stage ─────────────────────────────────────────────────────────
        logic [3:0]  alu_control;         // ALU_control → ALU
        logic [31:0] fwd_RD2;
        (* mark_debug = "true" *)logic [31:0] alu_result_ex;       // ALU result
        logic        zero_ex;             // ALU zero flag
        logic [31:0] pc_branch_ex;        // computed branch target
        logic [5:0]  control_sig_ex_mem;  // control bits passed to EX/MEM reg
        logic [1:0]  src_a_sel_ex;
        logic [31:0] fwd_RD1;           // forwarded rs1
        logic [31:0] alu_src_a;         // final ALU A input
        
        // Jump control
        logic        jal_ex, jalr_ex, jump_taken;
        logic [31:0] pc_plus4_ex;       // PC+4 piped for write-back
        logic [31:0] jalr_target_ex;    // (rs1+imm) & ~1
        logic        if_id_flush_combined;
        logic        id_ex_flush_combined;
    
        // ─── EX/MEM Pipeline Register outputs ────────────────────────────────
        logic [5:0]  control_sig_mem;     // {RegWrite, MemToReg, Branch, MemRead, MemWrite}
        logic [31:0] pc_branch_mem;       // branch target passed to PC mux
        logic        alu_zero_mem;        // zero flag for branch decision
        logic [31:0] alu_result_mem;      // ALU result (also memory address)
        logic [31:0] RD2_mem;             // store data
        logic [4:0]  write_reg_final_mem; // destination register
        logic [31:0] pc_plus4_mem;      // PC+4 from EX/MEM

        // ─── MEM Stage ───────────────────────────────────────────────────────
        logic [31:0] Read_data_mem;       // data memory read output
        logic [2:0]  func3_mem;
        logic branch_taken;
        logic [3:0]  byte_en;
        logic [31:0] dm_write_data;
        logic [31:0] mem_stage_load_result;
        // ─── MEM/WB Pipeline Register outputs ────────────────────────────────
        logic [31:0] Read_data_wb;        // memory read data
        logic [31:0] alu_result_wb;       // ALU result
        logic [4:0]  write_reg_final_wb;  // destination register → write_reg
        logic [2:0]  control_sig_mem_wb;        // {reg_write, wb_sel[1:0]}
        logic [31:0] pc_plus4_wb;               // PC+4 from MEM/WB
        logic [2:0]  control_sig_wb;            // was [1:0]
        logic [2:0] func3_wb;
        logic [31:0] load_result;

    hazard_unit hu(
        .id_ex_MemRead,
        .id_ex_rd,
        .if_id_rs1,
        .if_id_rs2,
        // Stall outputs
        .PCWrite,        // 0 = freeze PC
        .IF_ID_Write,    // 0 = freeze IF/ID register
        .control_flush   // 1 = zero out ID/EX control signals (insert bubble)
    );
    
    //forwarding unit
    forwarding_unit fu(
        .id_ex_rs1,   // need to pipe rs1/rs2 through ID/EX too
        .id_ex_rs2,
        .ex_mem_rd(write_reg_final_mem),
        .ex_mem_regwrite(control_sig_mem[5]),
        .mem_wb_rd(write_reg_final_wb),
        .mem_wb_regwrite(control_sig_wb[2]),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    //IF Stage
    assign pc_next = pc_out + 32'd4;

    logic [31:0] pc_mux_out;
    always_comb begin
        if      (PCSource)   pc_mux_out = pc_branch_mem;   // taken branch (MEM)
        else if (jalr_ex)    pc_mux_out = jalr_target_ex;  // JALR (EX)
        else if (jal_ex)     pc_mux_out = pc_branch_ex;    // JAL  (EX) - pc_out_ex+J-imm
        else                 pc_mux_out = pc_next;
    end
    PC pc(
        .clk,
        .reset(rst), 
        .PCWrite(PCWrite | PCSource | jump_taken),
        .pc_in(pc_mux_out),
        .pc_out);
        
    instruction_memory im(
        .PC(pc_out),
        .RD(instr)
        );
    assign if_id_flush_combined = branch_flush | jump_taken;
    //IF_ID_Reg
    IF_ID_Reg #(.IF_ID_size(IF_ID_size))  if_id_reg (.clk, .rst,.en(IF_ID_Write),.flush(if_id_flush_combined), .inp({pc_out,instr}), .out({pc_out_id,instr_id}));
     
    //ID stage
    assign id_ex_flush_combined = branch_flush | jump_taken;
    assign rs1_id = instr_id[19:15];
    assign rs2_id = instr_id[24:20];
    control_unit cu(
        .opcode(instr_id[6:0]),
        .control_sig(control_sig_id)
     );
    Register_file reg_file(
         .clk, 
         .rst,  
         .RN1(rs1_id), 
         .RN2(rs2_id), 
         .WN(write_reg), 
         .WD(write_reg_data), 
         .RegWrite, 
         .RD1(RD1_id), 
         .RD2(RD2_id)
         );
    SignExtend se(
        .instr(instr_id),
        .out(sign_extend_out_id)
        );
    assign func7_id =(instr_id[6:0] == 7'b0010011 && instr_id[14:12] != 3'b101 && instr_id[14:12] != 3'b001)? 7'b0 : instr_id[31:25];
    assign func3_id=instr_id[14:12];
    assign write_reg_id=instr_id[11:7];
    assign control_sig_to_idex = control_flush ? 13'b0 : control_sig_id;

     //ID_EX_REG
     ID_EX_Reg #(.ID_EX_size(ID_EX_size)) id_ex_reg(
        .clk,
        .rst,
        .flush(id_ex_flush_combined),
        .inp({control_sig_to_idex, pc_out_id, RD1_id,RD2_id,sign_extend_out_id,write_reg_id,func7_id,func3_id,rs1_id,rs2_id}),
        .out({control_sig_ex, pc_out_ex, RD1_ex,RD2_ex,sign_extend_out_ex,write_reg_ex,func7_ex,func3_ex,id_ex_rs1,id_ex_rs2})
        );
     
     // EX stage
     
     assign {ALUOp1,ALUOp0}= control_sig_ex[4:3];
     assign ALUSrc=control_sig_ex[2];
     assign src_a_sel_ex  = control_sig_ex[1:0];      // NEW
     assign jal_ex        = control_sig_ex[9];        // NEW
     assign jalr_ex       = control_sig_ex[8];
     
     assign control_sig_ex_mem={control_sig_ex[12],       // reg_write
                                  control_sig_ex[11:10],    // wb_sel
                                  control_sig_ex[7],        // branch
                                  control_sig_ex[6],        // mem_read
                                  control_sig_ex[5]};       // mem_write
                                  
     assign fwd_RD1 = (forwardA == 2'b10) ? MEM_RD :(forwardA == 2'b01) ? WB_RD  : RD1_ex;
     
     assign pc_branch_ex= pc_out_ex+sign_extend_out_ex;
     assign fwd_RD2 = (forwardB == 2'b10) ? MEM_RD :
                      (forwardB == 2'b01) ? WB_RD  :
                                            RD2_ex;
    assign pc_plus4_ex    = pc_out_ex + 4;
    assign jalr_target_ex = {alu_result_ex[31:1], 1'b0};  // rs1+imm, bit-0 cleared
    assign jump_taken     = jal_ex | jalr_ex;
    
    always_comb begin
        case (src_a_sel_ex)
            2'b01:   alu_src_a = pc_out_ex;  // AUIPC / JAL
            2'b10:   alu_src_a = 32'b0;      // LUI
            default: alu_src_a = fwd_RD1;    // normal / JALR
        endcase
    end
        
    ALU alu(
    .src_a(alu_src_a),                          // <-- was the inline mux
    .src_b(ALUSrc ? sign_extend_out_ex : fwd_RD2),
    .alu_control,
    .alu_result(alu_result_ex),
    .zero(zero_ex)
    );
    ALU_control alu_ctrl(
        .func7(func7_ex),
        .func3(func3_ex),
        .ALU_op({ALUOp1,ALUOp0}), 
        .ALU_control(alu_control)
    );  
    
    //EX_MEM_REG
    EX_MEM_Reg #(.EX_MEM_size(EX_MEM_size)) ex_mem_reg(
        .clk, .rst,
        .flush(branch_flush),
        .inp({control_sig_ex_mem, pc_plus4_ex, pc_branch_ex,
              func3_ex, alu_result_ex, fwd_RD2, write_reg_ex}),
        .out({control_sig_mem, pc_plus4_mem, pc_branch_mem,
              func3_mem, alu_result_mem, RD2_mem, write_reg_final_mem})
    );
    
    //MEM stage
    
    assign MemWrite=control_sig_mem[0];
    assign MemRead= control_sig_mem[1];
    assign Branch= control_sig_mem[2];
    
    always_comb begin
        byte_en       = 4'b0000;
        dm_write_data = RD2_mem;
    
        if (MemWrite) begin
            case (func3_mem[1:0])    // 00=byte, 01=half, 10=word
    
                2'b00: begin // SB
                    // Replicate the source byte into all four lanes.
                    // byte_en asserts exactly the one lane matching the byte offset.
                    dm_write_data = {4{RD2_mem[7:0]}};
                    case (alu_result_mem[1:0])
                        2'b00: byte_en = 4'b0001;
                        2'b01: byte_en = 4'b0010;
                        2'b10: byte_en = 4'b0100;
                        2'b11: byte_en = 4'b1000;
                    endcase
                end
    
                2'b01: begin // SH - must be halfword-aligned; only addr[1] matters
                    dm_write_data = {2{RD2_mem[15:0]}};
                    byte_en = alu_result_mem[1] ? 4'b1100 : 4'b0011;
                end
    
                default: begin // SW
                    dm_write_data = RD2_mem;
                    byte_en       = 4'b1111;
                end
    
            endcase
        end
    end
    
    always_comb begin
        case (func3_mem)
            3'b000: branch_taken =  (alu_result_mem == 32'b0); // BEQ
            3'b001: branch_taken = ~(alu_result_mem == 32'b0); // BNE
            3'b100: branch_taken =   alu_result_mem[0];        // BLT  (SLT result)
            3'b101: branch_taken =  ~alu_result_mem[0];        // BGE
            3'b110: branch_taken =   alu_result_mem[0];        // BLTU (SLTU result)
            3'b111: branch_taken =  ~alu_result_mem[0];        // BGEU
            default: branch_taken = 1'b0;
        endcase
    end
    assign PCSource = branch_taken & Branch;
    
    data_memory dm (
        .clk,
        .rst,
        .byte_addr  (alu_result_mem[11:0]),
        .write_data (dm_write_data),
        .byte_en    (byte_en),
        .mem_read   (MemRead),
        .read_data  (Read_data_mem)
    );
    always_comb begin
        mem_stage_load_result = Read_data_mem; // default: LW / fallback
    
        case (func3_mem)
            3'b000: // LB - signed byte
                case (alu_result_mem[1:0])
                    2'b00: mem_stage_load_result = {{24{Read_data_mem[ 7]}}, Read_data_mem[ 7: 0]};
                    2'b01: mem_stage_load_result = {{24{Read_data_mem[15]}}, Read_data_mem[15: 8]};
                    2'b10: mem_stage_load_result = {{24{Read_data_mem[23]}}, Read_data_mem[23:16]};
                    2'b11: mem_stage_load_result = {{24{Read_data_mem[31]}}, Read_data_mem[31:24]};
                    default: mem_stage_load_result = Read_data_mem;
                endcase
    
            3'b001: // LH - signed halfword
                mem_stage_load_result = alu_result_mem[1]
                    ? {{16{Read_data_mem[31]}}, Read_data_mem[31:16]}
                    : {{16{Read_data_mem[15]}}, Read_data_mem[15: 0]};
    
            3'b010: mem_stage_load_result = Read_data_mem; // LW
    
            3'b100: // LBU - unsigned byte
                case (alu_result_mem[1:0])
                    2'b00: mem_stage_load_result = {24'b0, Read_data_mem[ 7: 0]};
                    2'b01: mem_stage_load_result = {24'b0, Read_data_mem[15: 8]};
                    2'b10: mem_stage_load_result = {24'b0, Read_data_mem[23:16]};
                    2'b11: mem_stage_load_result = {24'b0, Read_data_mem[31:24]};
                    default: mem_stage_load_result = Read_data_mem;
                endcase
    
            3'b101: // LHU - unsigned halfword
                mem_stage_load_result = alu_result_mem[1]
                    ? {16'b0, Read_data_mem[31:16]}
                    : {16'b0, Read_data_mem[15: 0]};
    
            default: mem_stage_load_result = Read_data_mem;
        endcase
    end
    always_comb begin
        case (control_sig_mem[4:3])   // wb_sel
            2'b01:   MEM_RD = mem_stage_load_result; // ← was Read_data_mem (wrong for sub-word)
            2'b10:   MEM_RD = pc_plus4_mem;
            default: MEM_RD = alu_result_mem;
        endcase
    end
     
    //MEM_WB_reg
    assign control_sig_mem_wb=control_sig_mem[5:3];
    
    
    
    // Replace the old MEM_WB_Reg instantiation:
    MEM_WB_Reg #(.MEM_WB_size(MEM_WB_size)) mem_wb_reg (
        .clk, .rst,
        .inp({control_sig_mem_wb, pc_plus4_mem,
              Read_data_mem, alu_result_mem, func3_mem, write_reg_final_mem}),
        .out({control_sig_wb,    pc_plus4_wb,
              Read_data_wb,  alu_result_wb,  func3_wb,  write_reg_final_wb})
    );    
    
    
    //WB stage
    
    always_comb begin
        load_result = Read_data_wb; // default: LW, no transformation needed
    
        case (func3_wb)
            3'b000: // LB - signed byte
                case (alu_result_wb[1:0])
                    2'b00: load_result = {{24{Read_data_wb[ 7]}}, Read_data_wb[ 7: 0]};
                    2'b01: load_result = {{24{Read_data_wb[15]}}, Read_data_wb[15: 8]};
                    2'b10: load_result = {{24{Read_data_wb[23]}}, Read_data_wb[23:16]};
                    2'b11: load_result = {{24{Read_data_wb[31]}}, Read_data_wb[31:24]};
                endcase
    
            3'b001: // LH - signed halfword (halfword-aligned; addr[1] selects lane)
                load_result = alu_result_wb[1]
                              ? {{16{Read_data_wb[31]}}, Read_data_wb[31:16]}
                              : {{16{Read_data_wb[15]}}, Read_data_wb[15: 0]};
    
            3'b010: load_result = Read_data_wb; // LW - full word, no change
    
            3'b100: // LBU - unsigned byte
                case (alu_result_wb[1:0])
                    2'b00: load_result = {24'b0, Read_data_wb[ 7: 0]};
                    2'b01: load_result = {24'b0, Read_data_wb[15: 8]};
                    2'b10: load_result = {24'b0, Read_data_wb[23:16]};
                    2'b11: load_result = {24'b0, Read_data_wb[31:24]};
                endcase
    
            3'b101: // LHU - unsigned halfword
                load_result = alu_result_wb[1]
                              ? {16'b0, Read_data_wb[31:16]}
                              : {16'b0, Read_data_wb[15: 0]};
    
            default: load_result = Read_data_wb;
        endcase
    end
    assign RegWrite= control_sig_wb[2];
    always_comb begin
        case (control_sig_wb[1:0])   // wb_sel
            2'b01:   write_reg_data = load_result;    // all load variants via wb_sel=01
            2'b10:   write_reg_data = pc_plus4_wb;    // JAL / JALR
            default: write_reg_data = alu_result_wb;  // R/I-type, LUI, AUIPC
        endcase
    end
    assign WB_RD     = write_reg_data;
    assign write_reg = write_reg_final_wb;
endmodule
