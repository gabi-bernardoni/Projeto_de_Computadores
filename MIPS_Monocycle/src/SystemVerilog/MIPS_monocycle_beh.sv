import MIPS_monocycle_pkg::*;

module MIPS_monocycle_beh #(
    parameter logic [31:0] PC_START_ADDRESS = '0
)(
    input logic clk, rst,
    
    // Instruction memory interface
    output logic [31:0] instruction_address,
    input logic [31:0] instruction,
    
    // Data memory interface
    output logic [31:0] data_address,
    input logic [31:0] data_in,
    output logic [31:0] data_out,
    output logic ce,
    output logic [3:0] wbe 
        
);
    logic [31:0] pc, read_data2, write_data, instruction_fetch_address;
    logic [31:0] sign_extended, zero_extended;
    logic [31:0] alu_operand1, alu_operand2, result;
    logic [31:0] branch_offset, branch_target, jump_target;
    logic [4:0] write_register;
    logic reg_write;
    logic zero; 
    
    logic [31:0] register_file[0:31];
    
    Instruction decoded_instruction;
    
    // Locks the processor until the first clk rising edge
    logic lock;
    
    assign decoded_instruction =    (lock) ? NOP : 
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b100001) ? ADDU :
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b100011) ? SUBU :
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b100100) ? AAND :
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b100101) ? OOR :
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b101010) ? SLT :                                    
                                    (instruction[`OPCODE] == 6'b101011) ? SW :
                                    (instruction[`OPCODE] == 6'b100011) ? LW :
                                    (instruction[`OPCODE] == 6'b001001) ? ADDIU :
                                    (instruction[`OPCODE] == 6'b001101) ? ORI :
                                    (instruction[`OPCODE] == 6'b000100) ? BEQ :
                                    (instruction[`OPCODE] == 6'b000010) ? J :
                                    (instruction[`OPCODE] == 6'b000000 && instruction[`FUNCT] == 6'b001000) ? JR :
                                    (instruction[`OPCODE] == 6'b000011) ? JAL :
                                    (instruction[`OPCODE] == 6'b001111 && instruction[`RS] == 5'b00000) ? LUI :
                                     UNIMPLEMENTED_INSTRUCTION ;    // Invalid or not implemented instruction
                                     
    // Register PC
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc <= PC_START_ADDRESS;
            lock <= 1'b1;   // Locks the processor until the first clk rising edge
        end
        else begin
            pc <= instruction_address + 32'd4;
            
            // Unlocks the processor
            if (lock) begin
                lock <= 1'b0;
            end
        end
    end
    
    // Selects the instruction field which contains the register to be written
    // In R-type instructions the destination register is in the 'rd' field
    // MUX at the register file input (datapath diagram)
    assign write_register = (instruction[`OPCODE] == 5'b00000) ? instruction[`RD] : // R-type instructions
                            (decoded_instruction == JAL) ? 5'b11111 : // $ra ($31)
                            instruction[`RT]; // Load instructions
                            
    // Sign extends the low 16 bits of instruction (I-Type immediate constant)
    // Below the register file (datapath diagram)
    //assign sign_extended = 32'($signed(instruction[`IMM]));
    assign sign_extended = { {16{instruction[15]}}, instruction[`IMM]};
    
    // Zero extends the low 16 bits of instruction (I-Type immediate constant)
    // Not present in datapath diagram
    //assign zero_extended = 32'($unsigned(instruction[`IMM]));
    assign zero_extended = { {16{1'b0}}, instruction[`IMM]};
    
    // Converts the branch offset from words to bytes (multiply by 4) 
    // Hardware at the second Branch ADDER input (datapath diagram)
    assign branch_offset = {sign_extended[29:0], 2'b00}; 
    
    // Branch target address
    // Branch ADDER above the ALU (datapath diagram)
    assign branch_target = pc + branch_offset;
    
    // Builds the jump target address
    // Top of datapath diagram
    assign jump_target = {pc[31:28], instruction[25:0], 2'b00};
    
    // MUX which selects the source address of the next instruction 
    // Not present in datapath diagram
    // In case of jump/branch, PC must be bypassed due to synchronous memory read
    assign instruction_fetch_address =  (decoded_instruction == BEQ && zero) ? branch_target :
                                        (decoded_instruction == J || decoded_instruction == JAL) ? jump_target :
                                        (decoded_instruction == JR) ? alu_operand1 : 
                                        pc;
    
    // Instruction memory addressing
    assign instruction_address = instruction_fetch_address;
       
    /*
     * Behavioural register file
     */
     assign read_data2 = register_file[instruction[`RT]];
     
    // Selects the data to be written in the register file
    // In load instructions the data comes from the data memory
    // MUX at the data memory output
    assign write_data = (LoadInstruction(decoded_instruction)) ? data_in :
                        (decoded_instruction == JAL) ? pc :
                        result;
                        
    // R-type, ADDIU, ORI and load instructions, store the result in the register file
    assign reg_write = WriteRegisterFile(decoded_instruction);    
    
    // Register $0 is read-only (constant 0)
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register_file[0] = '0;
        end
        else begin
            if (reg_write && write_register != 5'b00000) begin
                register_file[write_register] <= write_data;
            end
        end     
    end
    
    // The first ALU operand always comes from the register file
    assign alu_operand1 = register_file[instruction[`RS]];     
    
    // Selects the second ALU operand
    // In R-type or BEQ instructions, the second ALU operand comes from the register file
    // In ORI instruction the second ALU operand is zeroExtended
    // MUX at the ALU second input
    assign alu_operand2 =   (instruction[`OPCODE] == 5'b00000 || decoded_instruction == BEQ)  ? read_data2 :
                            (decoded_instruction == ORI) ? zero_extended :
                            sign_extended;                           
                            
                            
    /*
     * Behavioural ALU
     */             
     assign result =    (decoded_instruction == SUBU || decoded_instruction == BEQ) ? alu_operand1 - alu_operand2 :
                        (decoded_instruction == AAND) ? alu_operand1 & alu_operand2 :
                        (decoded_instruction == OOR || decoded_instruction == ORI) ? alu_operand1 | alu_operand2 :
                        (decoded_instruction == SLT && $signed(alu_operand1) < $signed(alu_operand2)) ? 32'h00000001 :
                        (decoded_instruction == SLT && !($signed(alu_operand1) < $signed(alu_operand2))) ? 32'h00000000 :
                        (decoded_instruction == LUI) ? { alu_operand2, {16{1'b0}} } :
                        alu_operand1 + alu_operand2;  // default for ADDU, ADDIU, SW, LW
                        
     // Generates the zero flag
     assign zero = (result == 32'h00000000) ? 1'b1 : 1'b0;
                        
                        
     /*
     * Data memory interface
     */                    
     // ALU output address the data memory
     assign data_address = result;
     
     // Data to data memory comes from the second read register at register file
     assign data_out = read_data2;
     
     assign wbe = (decoded_instruction == SW) ? 4'b1111 : 4'b0000;
     
     assign ce = (LoadInstruction(decoded_instruction) || StoreInstruction(decoded_instruction)) ? 1'b1 : 1'b0;
     
     
                         
      
     
endmodule