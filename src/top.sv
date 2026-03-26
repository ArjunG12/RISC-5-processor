module top(
    input clk,rst,output logic [31:0] debug_pc       
    );
            parameter IF_ID_size=64,ID_EX_size=161, EX_MEM_size= 107, MEM_WB_size= 71;
    //control signals
    logic PCSource,branch_flush, PCWrite,ALUSrc,ALUOp1,ALUOp0,Branch,MemRead,MemWrite,RegWrite,MemToReg,IF_ID_Write,control_flush;
    
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
        logic [7:0]  control_sig_id;      // raw control unit output
        logic [7:0]  control_sig_to_idex; // control after hazard flush mux
        
        // ─── Hazard Unit signals ──────────────────────────────────────────────
        logic        id_ex_MemRead;       // tapped from control_sig_ex[4]
        logic [4:0]  id_ex_rd;            // tapped from write_reg_ex
    
        assign if_id_rs1   = instr_id[19:15];
        assign if_id_rs2   = instr_id[24:20];
        assign id_ex_MemRead = control_sig_ex[4];  // bit[4] = MemRead
        assign id_ex_rd    = write_reg_ex;
    
        // ─── ID/EX Pipeline Register outputs ─────────────────────────────────
        logic [7:0]  control_sig_ex;      // 9 control bits in EX stage (note: was 8, +1 for MemToReg)
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
        logic [4:0]  control_sig_ex_mem;  // control bits passed to EX/MEM reg
    
        // ─── EX/MEM Pipeline Register outputs ────────────────────────────────
        logic [4:0]  control_sig_mem;     // {RegWrite, MemToReg, Branch, MemRead, MemWrite}
        logic [31:0] pc_branch_mem;       // branch target passed to PC mux
        logic        alu_zero_mem;        // zero flag for branch decision
        logic [31:0] alu_result_mem;      // ALU result (also memory address)
        logic [31:0] RD2_mem;             // store data
        logic [4:0]  write_reg_final_mem; // destination register
    
        // ─── MEM Stage ───────────────────────────────────────────────────────
        logic [31:0] Read_data_mem;       // data memory read output
        logic [1:0]  control_sig_mem_wb;  // {RegWrite, MemToReg} passed to MEM/WB
    
        // ─── MEM/WB Pipeline Register outputs ────────────────────────────────
        logic [1:0]  control_sig_wb;      // {RegWrite, MemToReg}
        logic [31:0] Read_data_wb;        // memory read data
        logic [31:0] alu_result_wb;       // ALU result
        logic [4:0]  write_reg_final_wb;  // destination register → write_reg
    
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
        .ex_mem_regwrite(control_sig_mem[4]),
        .mem_wb_rd(write_reg_final_wb),
        .mem_wb_regwrite(control_sig_wb[1]),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    //IF Stage
    assign pc_next=pc_out+4;
    assign pc_branch=pc_branch_mem;
    PC pc(
        .clk,
        .reset(rst), 
        .PCWrite(PCWrite | PCSource),
        .pc_in(PCSource?pc_branch:pc_next),
        .pc_out);
        
    instruction_memory im(
        .PC(pc_out),
        .RD(instr)
        );
        
    //IF_ID_Reg
    IF_ID_Reg #(.IF_ID_size(IF_ID_size))  if_id_reg (.clk, .rst,.en(IF_ID_Write),.flush(branch_flush), .inp({pc_out,instr}), .out({pc_out_id,instr_id}));
     
    //ID stage
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
    assign control_sig_to_idex = control_flush ? 8'b0 : control_sig_id;
     //ID_EX_REG
     ID_EX_Reg #(.ID_EX_size(ID_EX_size)) id_ex_reg(
        .clk,
        .rst,
        .flush(branch_flush),
        .inp({control_sig_to_idex, pc_out_id, RD1_id,RD2_id,sign_extend_out_id,write_reg_id,func7_id,func3_id,rs1_id,rs2_id}),
        .out({control_sig_ex, pc_out_ex, RD1_ex,RD2_ex,sign_extend_out_ex,write_reg_ex,func7_ex,func3_ex,id_ex_rs1,id_ex_rs2})
        );
     
     // EX stage
     
     assign {ALUOp1,ALUOp0}= control_sig_ex[2:1];
     assign ALUSrc=control_sig_ex[0];
     assign control_sig_ex_mem=control_sig_ex[7:3];
     assign pc_branch_ex= pc_out_ex+sign_extend_out_ex;
     assign fwd_RD2 = (forwardB == 2'b10) ? MEM_RD :
                      (forwardB == 2'b01) ? WB_RD  :
                                            RD2_ex;
     ALU alu(
        .src_a((forwardA==2'b00)?RD1_ex:((forwardA==2'b01)?WB_RD:MEM_RD)),
        .src_b(ALUSrc?sign_extend_out_ex:fwd_RD2),
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
            .clk,
            .rst,
            .flush(branch_flush),
            .inp({control_sig_ex_mem, pc_branch_ex, zero_ex,alu_result_ex,fwd_RD2,write_reg_ex}),
            .out({control_sig_mem, pc_branch_mem, alu_zero_mem,alu_result_mem,RD2_mem,write_reg_final_mem})
            );
    
    
    
    //MEM stage
    
    assign MemWrite=control_sig_mem[0];
    assign MemRead= control_sig_mem[1];
    assign Branch= control_sig_mem[2];
    assign PCSource= alu_zero_mem & Branch;
    
    data_memory dm(
        .clk,
        .rst,
        .address(alu_result_mem[9:0]),
        .write_data(RD2_mem),
        .mem_write(MemWrite),
        .mem_read(MemRead),
        .read_data(Read_data_mem)
    );
    assign MEM_RD=alu_result_mem; 
     
    //MEM_WB_reg
    assign control_sig_mem_wb=control_sig_mem[4:3];
    
    MEM_WB_Reg #(.MEM_WB_size(MEM_WB_size)) mem_wb_reg(
                .clk,
                .rst,
                .inp({control_sig_mem_wb, Read_data_mem,alu_result_mem,write_reg_final_mem}),
                .out({control_sig_wb, Read_data_wb,alu_result_wb,write_reg_final_wb})
                );
               
    
    
    //WB stage
    assign RegWrite= control_sig_wb[1];
    assign MemToReg= control_sig_wb[0];
    assign write_reg_data=MemToReg? Read_data_wb: alu_result_wb;
    assign WB_RD=write_reg_data;
    assign write_reg= write_reg_final_wb;
endmodule
