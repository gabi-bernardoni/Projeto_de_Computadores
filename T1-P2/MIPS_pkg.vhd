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
                case(instruction(5 downto 0)) is
                    when "100001" => decodedInstruction := ADDU;
                    when "100011" => decodedInstruction := SUBU;
                    when "100100" => decodedInstruction := AAND;
                    when "100101" => decodedInstruction := OOR;
                    when "101010" => decodedInstruction := SLT;
                    when "001000" => decodedInstruction := JR;
                    when "001001" => decodedInstruction := JALR;
                    when "100110" => decodedInstruction := XOOR;
                    when "100111" => decodedInstruction := NOOR;
                    when "000000" => decodedInstruction := SHIFT_LL;
                    when "000010" => decodedInstruction := SHIFT_RL;
                    when "000011" => decodedInstruction := SHIFT_RA;
                    when "000100" => decodedInstruction := SLLV;
                    when "000110" => decodedInstruction := SRLV;
                    when "000111" => decodedInstruction := SRAV;
                end case;
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
            when "000001" =>
                if instruction(20 downto 16) = "00001" then
                    decodedInstruction := BGEZ;
                end if;
            when "000110" =>
                if instruction(20 downto 16) = "00000" then
                    decodedInstruction := BLEZ;
                end if;
            when others => decodedInstruction := UNIMPLEMENTED_INSTRUCTION;
        end case;
            
        return decodedInstruction;
    
    end Decode;

    -- Retorna verdadeiro se a instrucao escreve algum dado em registerFile
    function WriteRegisterFile(instruction: Instruction_type) return boolean is
    begin
        case instruction is
            when ADDU | SUBU | AAND | OOR | SLT | LW | ADDIU | ORI | LUI | JAL | XOOR | XORI |
                 NOOR | ANDI | SHIFT_LL | SHIFT_RL | SHIFT_RA | SLLV | SRLV | SRAV | LB | LBU |
                 LH | LHU | SB | SH | SLTI | SLTIU | JALR => return true;
            when others =>                                   return false;
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
