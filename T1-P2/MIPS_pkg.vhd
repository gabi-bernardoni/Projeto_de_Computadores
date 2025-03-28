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
        SHIFT_RL, SHIFT_RA, SLLV, SRLV, SRAV, LB, LBU, LH, LHU, SB, SH,
        SLTI, SLTIU, BGEZ, BLEZ, JALR
    );
    
    -- Functions used to facilitate the processor description
    function Decode(instruction: std_logic_vector(31 downto 0)) return Instruction_type;
    function R_Type(instruction: std_logic_vector(31 downto 0)) return boolean;
    function WriteRegisterFile(instruction: Instruction_type)   return boolean;
    function LoadInstruction(instruction: Instruction_type)     return boolean;
    function StoreInstruction(instruction: Instruction_type)    return boolean;    
  
         
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
                    
                elsif instruction(5 downto 0) = "001001" then
                    decodedInstruction := JALR;
                end if;
        
            when "100000" => -- LB
                decodedInstruction := LB;
                
            when "100100" => -- LBU
                decodedInstruction := LBU;
                
            when "100001" => -- LH
                decodedInstruction := LH;
                
            when "100101" => -- LHU
                decodedInstruction := LHU;
                
            when "101011" => -- SW
                decodedInstruction := SW;
            
            when "100011" => -- LW
                decodedInstruction := LW;
            
            when "001001" => -- ADDIU
                decodedInstruction := ADDIU;
            
            when "001101" => -- ORI
                decodedInstruction := ORI;
            
            when "000100"  => -- BEQ
                decodedInstruction := BEQ;
            
            when "000010" => -- J
                decodedInstruction := J;
            
            when "000011" => -- JAL
                decodedInstruction := JAL;
            
            when "001111" => -- LUI
                if instruction(25 downto 21) = "00000" then
                    decodedInstruction := LUI;
                end if;

            when "001110" => -- XORI
                decodedInstruction := XORI;

            when "001100" => -- ANDI
                decodedInstruction := ANDI;

            when "000101" => -- BNE
                decodedInstruction := BNE;
                
            when "101000" => -- SB
                decodedInstruction := SB;
                
            when "101001" => -- SH
                decodedInstruction := SH;
                
            when "001010" => -- SLTI
                decodedInstruction := SLTI;
                
            when "001011" => -- SLTIU
                decodedInstruction := SLTIU;
                
            when "000001" => -- BGEZ/BLEZ
                if instruction(20 downto 16) = "00001" then -- BGEZ
                    decodedInstruction := BGEZ;
                elsif instruction(20 downto 16) = "00000" then -- BLEZ
                    decodedInstruction := BLEZ;
                end if;
            
            when others=>    
                decodedInstruction := UNIMPLEMENTED_INSTRUCTION;
        end case;
        
        return decodedInstruction;
    
    end Decode;

    -- Returns 
    --      true, if the instruction writes to the register file
    --      false, otherwise
    function WriteRegisterFile(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        
        case (instruction) is
            when ADDU | SUBU | AAND | OOR | SLT | LW | ADDIU | ORI | LUI | JAL | XOOR | XORI |
                 NOOR | ANDI | SHIFT_LL | SHIFT_RL | SHIFT_RA | SLLV | SRLV | SRAV | LB | LBU | 
                 LH | LHU | SLTI | SLTIU | JALR =>
                result := true;
            
            when others =>
                result := false;
        end case;
        
        return result;
    
    end WriteRegisterFile;
    
    -- Returns 
    --      true, if the instruction is load
    --      false, otherwise
    function LoadInstruction(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        
        case (instruction) is
            when LW | LB | LBU | LH | LHU =>
                result := true;
            
            when others =>
                result := false;
        end case;
        
        return result;
        
    end LoadInstruction;
    
    -- Returns 
    --      true, if the instruction is store
    --      false, otherwise    
    function StoreInstruction(instruction: Instruction_type) return boolean is
        variable result : boolean;
    begin
        
        case (instruction) is
            when SW | SB | SH =>
                result := true;
            
            when others =>
                result := false;
        end case;
        
        return result;
    
    end StoreInstruction;
    
    
end MIPS_pkg;
