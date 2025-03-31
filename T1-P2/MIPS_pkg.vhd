-------------------------------------------------------------------------
-- Design unit: MIPS package
-- Description: Types and functions used in the processor description
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package MIPS_pkg is 
    
    -- Implemented instructions
    type Instruction_type is (
        UNIMPLEMENTED_INSTRUCTION, NOP, ADDU, SUBU, AAND, OOR, SW, LW, ADDIU, 
        ORI, SLT, BEQ, J, JR, JAL, LUI, XOOR, XORI, NOOR, ANDI, BNE, SHIFT_LL,
        SHIFT_RL, SHIFT_RA, SLLV, SRLV, SRAV, LB, LBU, LH, LHU, SB, SH, SLTI,
        SLTIU, BGEZ, BLEZ, JALR
    );
    
    -- Functions used to facilitate the processor description
    function Decode(instruction: std_logic_vector(31 downto 0)) return Instruction_type;
    function R_Type(instruction: std_logic_vector(31 downto 0)) return boolean;
    function WriteRegisterFile(instruction: Instruction_type)   return boolean;
    function LoadInstruction(instruction: Instruction_type)     return boolean;
    function StoreInstruction(instruction: Instruction_type)    return boolean;
    function BranchInstruction(instruction: Instruction_type)   return boolean;
    function JumpInstruction(instruction: Instruction_type)     return boolean;
  
         
end MIPS_pkg;

package body MIPS_pkg is

    function R_Type(instruction: std_logic_vector(31 downto 0)) return boolean is
    begin
        if instruction(31 downto 26) = "000000" then
            return true;
        else
            return false;
        end if;
    end R_Type;

      
    -- Instruction decoding
    function Decode(instruction: std_logic_vector(31 downto 0)) return Instruction_type is
        variable decodedInstruction : Instruction_type;
    begin
    
        decodedInstruction := UNIMPLEMENTED_INSTRUCTION; -- Invalid or not implemented instruction
    
        case(instruction(31 downto 26)) is
            when "000000" => -- R-Type        
                if instruction(5 downto 0) = "100001" then
                    decodedInstruction := ADDU;
                
                elsif instruction(5 downto 0) = "100011" then
                    decodedInstruction := SUBU;
                
                elsif instruction(5 downto 0) = "100100" then
                    decodedInstruction := AAND;
                
                elsif instruction(5 downto 0) = "100101" then
                    decodedInstruction := OOR;
                
                elsif instruction(5 downto 0) = "101010" then
                    decodedInstruction := SLT;
                
                elsif instruction(5 downto 0) = "001000" then
                    decodedInstruction := JR;
 
                elsif instruction(5 downto 0) = "001001" then
                    decodedInstruction := JALR;
               
                elsif instruction(5 downto 0) = "100110" then
                    decodedInstruction := XOOR;

                elsif instruction(5 downto 0) = "100111" then
                    decodedInstruction := NOOR;

                elsif instruction(5 downto 0) = "000000" then
                    decodedInstruction := SHIFT_LL;

                elsif instruction(5 downto 0) = "000010" then
                    decodedInstruction := SHIFT_RL;

                elsif instruction(5 downto 0) = "000011" then
                    decodedInstruction := SHIFT_RA;

                elsif instruction(5 downto 0) = "000100" then
                    decodedInstruction := SLLV;

                elsif instruction(5 downto 0) = "000110" then
                    decodedInstruction := SRLV;

                elsif instruction(5 downto 0) = "000111" then
                    decodedInstruction := SRAV;
                end if;
        
            when "101011" => decodedInstruction := SW;
            when "100011" => decodedInstruction := LW;
            when "001001" => decodedInstruction := ADDIU;
            when "001101" => decodedInstruction := ORI;
            when "000100" => decodedInstruction := BEQ;
            when "000010" => decodedInstruction := J;
            when "000011" => decodedInstruction := JAL;
            when "001111" => 
                if instruction(25 downto 21) = "00000" then
                    decodedInstruction := LUI;
                end if;
            when "001110" => decodedInstruction := XORI;
            when "001100" => decodedInstruction := ANDI;
            when "000101" => decodedInstruction := BNE;
            when "100000" => decodedInstruction := LB;
            when "100100" => decodedInstruction := LBU;
            when "100001" => decodedInstruction := LH;
            when "100101" => decodedInstruction := LHU;
            when "101000" => decodedInstruction := SB;
            when "101001" => decodedInstruction := SH;
            when "001010" => decodedInstruction := SLTI;
            when "001011" => decodedInstruction := SLTIU;
            when others => decodedInstruction := UNIMPLEMENTED_INSTRUCTION;
        end case;
        
        case instruction(20 downto 16) is
                    when "00001" => 
            decodedInstruction := BGEZ;
                   
                    when "00000" => 
            decodedInstruction := BLEZ;
                    when others => null;
                end case;
        end case;
            
            return decodedInstruction;
    
    end Decode;

    -- Retorna verdadeiro se a instrucao escreve algum dado em registerFile
    function WriteRegisterFile(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when ADDU | SUBU | AAND | OOR | SLT | LW | ADDIU | ORI | LUI | JAL | XOOR | XORI |
                 NOOR | ANDI | SHIFT_LL | SHIFT_RL | SHIFT_RA | SLLV | SRLV | SRAV | LB | LBU |
                 LH | LHU | SB | SH | |SLTI | SLTIU | JALR => return true;
            when others =>                                    return false;
        end case;
    end WriteRegisterFile;

    -- Retorna verdadeiro se a instrucao carrega algum dado da memoria
    function LoadInstruction(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when LW | LB | LBU | LH | LHU => return true;
            when others =>                   return false;
        end case;
    end LoadInstruction;

    -- Retorna verdadeiro se a instrucao guarda algum dado na memoria
    function StoreInstruction(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when SW | SB | SH => return true;
            when others =>       return false;
        end case;
    end StoreInstruction;

    -- Retorna verdadeiro se a instrucao realiza branch
    function BranchInstruction(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when BEQ | BNE | BGEZ | BLEZ => return true;
            when others =>                  return false;
        end case;
    end BranchInstruction;

    -- Retorna verdadeiro se a instrucao realiza jump
    function JumpInstruction(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when J | JAL | JR | JALR => return true;
            when others =>              return false;
        end case;
    end JumpInstruction;


end MIPS_pkg;
