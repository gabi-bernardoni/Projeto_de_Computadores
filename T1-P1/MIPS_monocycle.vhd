-------------------------------------------------------------------------
-- Design unit: MIPS_monocycle
-- Description: Behavioural processor description
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MIPS_pkg.all;

entity MIPS_monocycle is
    generic (
        PC_START_ADDRESS    : UNSIGNED(31 downto 0) := (others=>'0') -- First instruction address
    );
    port ( 
        clk, rst            : in std_logic;
        
        -- Instruction memory interface
        instructionAddress  : out std_logic_vector(31 downto 0);
        instruction         : in  std_logic_vector(31 downto 0);
        
        -- Data memory interface
        dataAddress         : out std_logic_vector(31 downto 0);
        data_in             : in  std_logic_vector(31 downto 0);      
        data_out            : out std_logic_vector(31 downto 0);
        ce                  : out std_logic;
        wbe                 : out std_logic_vector(3 downto 0)
    );
end MIPS_monocycle;

architecture behavioral of MIPS_monocycle is

    signal pc, readData2, writeData, instructionFetchAddress: UNSIGNED(31 downto 0);
    signal signExtended, zeroExtended : UNSIGNED(31 downto 0);
    signal ALUoperand1, ALUoperand2, result: UNSIGNED(31 downto 0);
    signal branchOffset, branchTarget, jumpTarget: UNSIGNED(31 downto 0);
    signal writeRegister   : UNSIGNED(4 downto 0);
    signal regWrite : std_logic;
    
    -- Register file
    type RegisterArray is array (natural range <>) of UNSIGNED(31 downto 0);
    signal registerFile: RegisterArray(0 to 31);
    
    -- Alias to the instruction fields
    alias instruction_rs    : std_logic_vector(4 downto 0) is instruction(25 downto 21); 
    alias instruction_rt    : std_logic_vector(4 downto 0) is instruction(20 downto 16);        
    alias instruction_rd    : std_logic_vector(4 downto 0) is instruction(15 downto 11);
    alias instruction_shamt : std_logic_vector(4 downto 0) is instruction(10 downto 6);
    alias instruction_imm   : std_logic_vector(15 downto 0) is instruction(15 downto 0);
       
    -- ALU zero flag
    signal zero : std_logic;
    
    -- Locks the processor until the first clk rising edge
    signal lock: boolean;
    
    signal decodedInstruction: Instruction_type;
       
begin

    -- Instruction decoding
    decodedInstruction <=   NOP when lock else
                            Decode(instruction);
            
    assert not (decodedInstruction = UNIMPLEMENTED_INSTRUCTION and rst = '0')    
        report "******************* UNIMPLEMENTED INSTRUCTION *************"
        --severity error;   -- Produces only an error message in simulator
        severity failure;  -- Stops the simulation  
    
    
    -- Register PC and adder --
    REG_PC: process(clk,rst)
    begin
        if rst = '1' then
            pc <= PC_START_ADDRESS;
            lock <= true; -- Locks the processor until the first clk rising edge
        
        elsif rising_edge(clk) then
            pc <= instructionFetchAddress + 4;
            
            if lock then -- Unlocks the processor
                lock <= false;
            end if;
            
        end if;
    end process;
        
    -- Selects the instruction field which contains the register to be written
    -- In R-type instructions the destination register is in the 'instruction_rd' field
    -- MUX at the register file input (datapath diagram)
    MUX_RF: writeRegister <= UNSIGNED(instruction_rd) when R_Type(instruction) else -- R-type instructions
                             "11111" when decodedInstruction = JAL else    -- $ra ($31)
                             UNSIGNED(instruction_rt); -- Load instructions
      
    -- Sign extends the low 16 bits of instruction (I-Type immediate constant)
    -- Below the register file (datapath diagram)
    SIGN_EXT: signExtended <= UNSIGNED(RESIZE(SIGNED(instruction_imm), signExtended'length));
                           
    -- Zero extends the low 16 bits of instruction (I-Type immediate constant)
    -- Not present in datapath diagram
    ZERO_EXT: zeroExtended <= RESIZE(UNSIGNED(instruction_imm), zeroExtended'length);
                                
    -- Converts the branch offset from words to bytes (multiply by 4) 
    -- Hardware at the second Branch ADDER input (datapath diagram)
    SHIFT_L: branchOffset <= signExtended(29 downto 0) & "00";
    
    -- Branch target address
    -- Branch ADDER above the ALU (datapath diagram)
    ADDER_BRANCH: branchTarget <= pc + branchOffset;
    
    -- Builds the jump target address
    -- Top of datapath diagram
    jumpTarget <= (pc(31 downto 28) & UNSIGNED(instruction(25 downto 0)) & "00");
      
      
    -- MUX which selects the source address of the next instruction 
    -- Not present in datapath diagram
    -- In case of jump/branch, PC must be bypassed due to synchronous memory read
    instructionFetchAddress <= branchTarget when decodedInstruction = BEQ and zero = '1' else 
                               jumpTarget when decodedInstruction = J or decodedInstruction = JAL else
                               ALUoperand1 when decodedInstruction = JR else
                               pc;
                    
    -- Instruction memory addressing
    instructionAddress <= STD_LOGIC_VECTOR(instructionFetchAddress);
                
    
    -------------------------------
    -- Behavioural register file --
    -------------------------------
    readData2 <= registerFile(TO_INTEGER(UNSIGNED(instruction_rt)));
         
    -- Selects the data to be written in the register file
    -- In load instructions the data comes from the data memory
    -- MUX at the data memory output
    MUX_DATA_MEM: writeData <= UNSIGNED(data_in) when LoadInstruction(decodedInstruction) else 
                               pc when decodedInstruction = JAL else
                               result;
    
    -- R-type, ADDIU, ORI and load instructions, store the result in the register file
    regWrite <= '1' when WriteRegisterFile(decodedInstruction) else '0';
    
    -- Register $0 is read-only (constant 0)
    REGISTER_FILE: process(clk, rst)
    begin
    
        if rst = '1' then
            registerFile(0) <= (others=>'0');
            --for i in 0 to 31 loop   
            --    registerFile(i) <= (others=>'0');  
            --end loop;
               
        elsif rising_edge(clk) then
            if regWrite = '1' and writeRegister /= 0 then
                registerFile(TO_INTEGER(writeRegister)) <= writeData;
            end if;
        end if;
    end process;
    
       
    -- The first ALU operand always comes from the register file
    ALUoperand1 <= registerFile(TO_INTEGER(UNSIGNED(instruction_rs)));
    
    -- Selects the second ALU operand
    -- In R-type or BEQ instructions, the second ALU operand comes from the register file
    -- In ORI instruction the second ALU operand is zeroExtended
    -- MUX at the ALU second input
    MUX_ALU: ALUoperand2 <= readData2 when R_Type(instruction) or decodedInstruction = BEQ else 
                            zeroExtended when decodedInstruction = ORI or
                                              decodedInstruction = XORI or
                                              decodedInstruction = ANDI else
                            signExtended;
    
    ---------------------
    -- Behavioural ALU --
    ---------------------
    result <=   ALUoperand1 - ALUoperand2   when decodedInstruction = SUBU or decodedInstruction = BEQ  else
                ALUoperand1 and ALUoperand2 when decodedInstruction = AAND or decodedInstruction = ANDI else 
                ALUoperand1 or  ALUoperand2 when decodedInstruction = OOR  or decodedInstruction = ORI  else 
                ALUoperand1 xor ALUoperand2 when decodedInstruction = XOOR or decodedInstruction = XORI else
                ALUoperand1 nor ALUoperand2 when decodedInstruction = NOOR else
                (0=>'1', others=>'0') when decodedInstruction = SLT and SIGNED(ALUoperand1) < SIGNED(ALUoperand2) else
                (others=>'0') when decodedInstruction = SLT and not (SIGNED(ALUoperand1) < SIGNED(ALUoperand2)) else
                ALUoperand2(15 downto 0) & x"0000" when decodedInstruction = LUI else
                ALUoperand1 + ALUoperand2;    -- default for ADDU, ADDIU, SW, LW   


    -- Generates the zero flag
    zero <= '1' when result = 0 else '0';
      


      
    ---------------------------
    -- Data memory interface --
    ---------------------------
    
    -- ALU output address the data memory
    dataAddress <= STD_LOGIC_VECTOR(result);
    
    -- Data to data memory comes from the second read register at register file
    data_out <= STD_LOGIC_VECTOR(readData2);
    
    wbe <= "1111" when decodedInstruction = SW else "0000";
    
    ce <= '1' when LoadInstruction(decodedInstruction) or StoreInstruction(decodedInstruction) else '0';
    
end behavioral;
