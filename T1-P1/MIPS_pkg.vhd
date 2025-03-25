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
        ORI, SLT, BEQ, J, JR, JAL, LUI, XOR_OP, XORI, ANDI, NOR_OP, BNE, SLL_OP, SRL_OP, SRA_OP, SLLV, SRLV, SRAV
    );
    
    -- Functions used to facilitate the processor description
    function Decode(instruction: std_logic_vector(31 downto 0)) return Instruction_type;
    function R_Type(instruction: std_logic_vector(31 downto 0)) return boolean;
    function WriteRegisterFile(instruction: Instruction_type) return boolean;
    function LoadInstruction(instruction: Instruction_type) return boolean;
    function StoreInstruction(instruction: Instruction_type) return boolean;    
  
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
                    when "100110" => decodedInstruction := XOR_OP;  -- XOR
                    when "100111" => decodedInstruction := NOR_OP;  -- NOR
                    when "101010" => decodedInstruction := SLT;
                    when "000000" => decodedInstruction := SLL_OP;  -- SLL
                    when "000010" => decodedInstruction := SRL_OP;  -- SRL
                    when "000011" => decodedInstruction := SRA_OP;  -- SRA
                    when "000100" => decodedInstruction := SLLV;    -- SLLV
                    when "000110" => decodedInstruction := SRLV;    -- SRLV
                    when "000111" => decodedInstruction := SRAV;    -- SRAV
                    when "001000" => decodedInstruction := JR;
                    when others => decodedInstruction := UNIMPLEMENTED_INSTRUCTION;
                end case;
            when "001110" => decodedInstruction := XORI;  -- XORI
            when "001100" => decodedInstruction := ANDI;  -- ANDI
            when "000101" => decodedInstruction := BNE;   -- BNE
            when others => decodedInstruction := UNIMPLEMENTED_INSTRUCTION;
        end case;

        return decodedInstruction;
    end Decode;

    -- Returns true if the instruction writes to the register file
    function WriteRegisterFile(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        case (instruction) is
            when ADDU | SUBU | AAND | OOR | XOR_OP | NOR_OP | SLT | LW | ADDIU | ORI | XORI | ANDI | LUI | JAL | SLL_OP | SRL_OP | SRA_OP | SLLV | SRLV | SRAV =>
                result := true;
            when others =>
                result := false;
        end case;
        return result;
    end WriteRegisterFile;
    
    -- Returns true if the instruction is a load instruction
    function LoadInstruction(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        case (instruction) is
            when LW => result := true;
            when others => result := false;
        end case;
        return result;
    end LoadInstruction;
    
    -- Returns true if the instruction is a store instruction
    function StoreInstruction(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        case (instruction) is
            when SW => result := true;
            when others => result := false;
        end case;
        return result;
    end StoreInstruction;
    
end MIPS_pkg;
