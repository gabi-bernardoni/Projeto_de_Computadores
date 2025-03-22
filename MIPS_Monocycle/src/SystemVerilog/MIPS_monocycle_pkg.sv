package MIPS_monocycle_pkg;

    // Instruction fields
    `define OPCODE  31:26
    `define RS      25:21
    `define RT      20:16
    `define RD      15:11
    `define IMM     15:0
    `define FUNCT   5:0
    
    typedef enum {
        UNIMPLEMENTED_INSTRUCTION, NOP, ADDU, SUBU, AAND, OOR, SW, LW, ADDIU, 
        ORI, SLT, BEQ, J, JR, JAL, LUI
    } Instruction;
    
    // Returns 
    //      1, if the instruction writes to the register file
    //      0, otherwise
    function logic WriteRegisterFile(Instruction ins);
        
        logic result;
        
        case(ins) // inside
            ADDU, SUBU, AAND, OOR, SLT, LW, ADDIU, ORI, LUI, JAL: begin 
                result = 1'b1;
            end
            
            default: begin
                result = 1'b0;
            end
        endcase
        
        return result;   
    endfunction
    
    // Returns 
    //      1, if the instruction is load
    //      0, otherwise
    function logic LoadInstruction(Instruction ins);
        
        logic result;
        
        case(ins)
            LW: begin // LB, LBU, LH, LHU
                result = 1'b1;
            end
            
            default: begin
                result = 1'b0;
            end
        endcase
        
        return result;   
    endfunction
    
    
    // Returns 
    //      1, if the instruction is store
    //      0, otherwise
    function logic StoreInstruction(Instruction ins);
        
        logic result;
        
        case(ins)
            SW: begin // SB, SH
                result = 1'b1;
            end
            
            default: begin
                result = 1'b0;
            end
        endcase
        
        return result;   
    endfunction
    
endpackage
