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

    signal pc, readData2, writeData, instructionFetchAddress,
           signExtended, zeroExtended,
           ALUoperand1, ALUoperand2, result,
           branchOffset, branchTarget, jumpTarget               : UNSIGNED(31 downto 0);
    signal writeRegister                                        : UNSIGNED(4 downto 0);
    signal memSelecionada                                       : std_logic_vector(31 downto 0);
    signal regWrite                                             : std_logic;
    signal byteExtended: std_logic_vector(31 downto 0); -- byte with its signal extended for LB instruction
    signal halfExtended: std_logic_vector(31 downto 0); -- half world for LH and LHU instructions
    
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
     -- ALU negative flag
    signal negative : std_logic;
				
    signal byteSelect <= std_logic_vector(result(1 downto 0));
     -- Seleção de byte/halfword
    
    -- Locks the processor until the first clk rising edge
    signal lock: boolean;
    
    signal decodedInstruction: Instruction_type;
       
begin

    -- Instruction decoding
    decodedInstruction <= NOP when lock else Decode(instruction);
            
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
    MUX_RF: writeRegister <=
        UNSIGNED(instruction_rd) when R_Type(instruction) else -- R-type instructions
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
                               branchTarget when decodedInstruction = BNE and zero = '0' else
                               branchTarget when decodedInstruction = BGEZ and negative = '0' else
                               branchTarget when decodedInstruction = BLEZ and (negative = '1' or zero = '1') else
                               branchTarget when decodedInstruction = BGTZ and (negative = '0' and zero = '0') else
                               branchTarget when decodedInstruction = BLTZ and (negative = '1') else
                               jumpTarget when decodedInstruction = J or decodedInstruction = JAL else
                               ALUoperand1 when decodedInstruction = JR else
                               ALUoperand1 when decodedInstruction = JALR else
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
  MUX_DATA_MEM: writeData <= UNSIGNED(byteExtended) when decodedInstruction = LB or decodedInstruction = LBU else
                               UNSIGNED(halfExtended) when decodedInstruction = LH or decodedInstruction = LHU else
                               UNSIGNED(data_in) when LoadInstruction(decodedInstruction) and (decodedInstruction /= LB and decodedInstruction /= LBU and decodedInstruction /= LH and decodedInstruction /= LHU) else
                               pc when decodedInstruction = JAL else
                               pc when decodedInstruction = JALR else
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
    
       
    -- Pega o primeiro operador a ser usado na ULA, que normalmente vem do banco de registradores
    -- No caso de operações de shift, o campo rs da instrução tipo-R é nulo, então ao invés disso
    -- pegamos o campo shamt
    ALUoperand1 <=
        RESIZE(UNSIGNED(instruction_shamt), ALUoperand1'length) when (decodedInstruction = SHIFT_LL  or 
                                                                      decodedInstruction = SHIFT_RL  or 
                                                                      decodedInstruction = SHIFT_RA) else
        registerFile(TO_INTEGER(UNSIGNED(instruction_rs)));
    
    -- Selects the second ALU operand
    -- In R-type or BEQ instructions, the second ALU operand comes from the register file
    -- In ORI instruction the second ALU operand is zeroExtended
    -- MUX at the ALU second input
MUX_ALU: ALUoperand2 <= readData2 when R_Type(instruction) or decodedInstruction = BEQ or decodedInstruction = BNE else
                        readData2 when decodedInstruction = BLEZ else
                        readData2 when decodedInstruction = BGTZ else
                        UNSIGNED(zeroExtended) when decodedInstruction = ORI else
                        UNSIGNED(zeroExtended) when decodedInstruction = ANDI else
                        UNSIGNED(zeroExtended) when decodedInstruction = XORI else
                        signExtended when decodedInstruction = SLTI or decodedInstruction = SLTIU else
                        signExtended when decodedInstruction = ADDIU else
                        signExtended;
    
    ---------------------
    -- Behavioural ALU --
    ---------------------
    result <=   ALUoperand1 - ALUoperand2 when decodedInstruction = SUBU else
                ALUoperand1 - ALUoperand2 when decodedInstruction = BEQ else
                ALUoperand1 - ALUoperand2 when decodedInstruction = BNE else
                ALUoperand1 when decodedInstruction = BGEZ else -- pass ALUoperand1 (rs)
                ALUoperand1 when decodedInstruction = BLEZ else -- pass ALUoperand1 (rs)
                ALUoperand1 when decodedInstruction = BGTZ else -- pass ALUoperand1 (rs)
                ALUoperand1 and ALUoperand2 when decodedInstruction = AAND     else 
                ALUoperand1 or  ALUoperand2 when decodedInstruction = OOR or decodedInstruction = ORI else 
                ALUoperand1 xor ALUoperand2 when decodedInstruction = XOOR else
                ALUoperand1 nor ALUoperand2 when decodedInstruction = NOOR else
                ALUoperand1 and ALUoperand2 when decodedInstruction = ANDI else
                ALUoperand1 xor ALUoperand2 when decodedInstruction = XORI else
                ALUoperand2 sll TO_INTEGER(ALUoperand1) when decodedInstruction = SHIFT_LL else
                ALUoperand2 srl TO_INTEGER(ALUoperand1) when decodedInstruction = SHIFT_RL else
                UNSIGNED(shift_right(SIGNED(ALUoperand2), TO_INTEGER(ALUoperand1))) when decodedInstruction = SHIFT_RA else
                ALUoperand2 sll TO_INTEGER(ALUoperand1(4 downto 0)) when decodedInstruction = SLLV else
                ALUoperand2 srl TO_INTEGER(ALUoperand1(4 downto 0)) when decodedInstruction = SRLV else
                UNSIGNED(shift_right(SIGNED(ALUoperand2), TO_INTEGER(ALUoperand1(4 downto 0)))) when decodedInstruction = SRAV else
                (0=>'1', others=>'0') when decodedInstruction = SLT and SIGNED(ALUoperand1) < SIGNED(ALUoperand2) else
                (others=>'0') when decodedInstruction = SLT and not (SIGNED(ALUoperand1) < SIGNED(ALUoperand2)) else
                (0=>'1', others=>'0') when decodedInstruction = SLTU and UNSIGNED(ALUoperand1) < UNSIGNED(ALUoperand2) else -- SLTU
                (others=>'0') when decodedInstruction = SLTU and not (UNSIGNED(ALUoperand1) < UNSIGNED(ALUoperand2)) else   -- SLTU
                (0=>'1', others=>'0') when decodedInstruction = SLTI and SIGNED(ALUoperand1) < SIGNED(ALUoperand2) else     -- SLTI
                (others=>'0') when decodedInstruction = SLTI and not (SIGNED(ALUoperand1) < SIGNED(ALUoperand2)) else       -- SLTI
                (0=>'1', others=>'0') when decodedInstruction = SLTIU and UNSIGNED(ALUoperand1) < UNSIGNED(ALUoperand2) else     -- SLTI
                (others=>'0') when decodedInstruction = SLTIU and not (UNSIGNED(ALUoperand1) < UNSIGNED(ALUoperand2)) else       -- SLTI
                ALUoperand2(15 downto 0) & x"0000" when decodedInstruction = LUI else
                ALUoperand1 + ALUoperand2;    -- default for ADDU, ADDIU, SW, LW   


    -- Generates the zero flag
    zero <= '1' when result = 0 else '0';
    -- Generates the negative flag
    negative <= result(31);

 -- Adding suport for LB and LBU instructions: --
    byteExtended <= std_logic_vector(RESIZE(SIGNED(data_in(7  downto  0)), 32)) when byteSelect = "00" and decodedInstruction = LB else
                    std_logic_vector(RESIZE(SIGNED(data_in(15 downto  8)), 32)) when byteSelect = "01" and decodedInstruction = LB else
                    std_logic_vector(RESIZE(SIGNED(data_in(23 downto 16)), 32)) when byteSelect = "10" and decodedInstruction = LB else
                    std_logic_vector(RESIZE(SIGNED(data_in(31 downto 24)), 32)) when byteSelect = "11" and decodedInstruction = LB else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(7  downto  0)), 32)) when byteSelect = "00" and decodedInstruction = LBU else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(15 downto  8)), 32)) when byteSelect = "01" and decodedInstruction = LBU else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(23 downto 16)), 32)) when byteSelect = "10" and decodedInstruction = LBU else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(31 downto 24)), 32));

    -- Adding support for LH and LHU instructions
    halfExtended <= std_logic_vector(RESIZE(SIGNED(data_in(15 downto  0)), 32)) when byteSelect = "00" and decodedInstruction = LH else
                    std_logic_vector(RESIZE(SIGNED(data_in(31 downto 16)), 32)) when byteSelect = "10" and decodedInstruction = LH else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(15 downto  0)), 32)) when byteSelect = "00" and decodedInstruction = LHU else
                    std_logic_vector(RESIZE(UNSIGNED(data_in(31 downto  16)), 32)) when byteSelect = "10" and decodedInstruction = LHU else
                    (others => '0');
				     
   
				     ---------------------------
    -- Data memory interface --
    ---------------------------
    
    -- ALU output address the data memory
    dataAddress <= STD_LOGIC_VECTOR(result);
    
    -- Data to data memory comes from the second read register at register file
    -- Assigns a byte from readData2 to the corrent position in data_o based on byteSelect for SB instruction
    -- For SW, takes the value from readData2 directly
    data_out <= STD_LOGIC_VECTOR(RESIZE(UNSIGNED(readData2(7 downto 0)), 32) sll TO_INTEGER(byteSelect)*8) when decodedInstruction = SB else
              STD_LOGIC_VECTOR(RESIZE(UNSIGNED(readData2(15 downto 0)), data_out length) sll TO_INTEGER(byteSelect) * 8) when decodedInstruction = SH else
              STD_LOGIC_VECTOR(readData2);
              
    
    wbe <= "0001" when decodedInstruction = SB and byteSelect = "00" else
           "0010" when decodedInstruction = SB and byteSelect = "01" else
           "0100" when decodedInstruction = SB and byteSelect = "10" else
           "1000" when decodedInstruction = SB and byteSelect = "11" else
           "0011" when decodedInstruction = SH and byteSelect = "00" else -- lower half word
           "1100" when decodedInstruction = SH and byteSelect = "10" else -- upper half word
           "1111" when decodedInstruction = SW else
           "0000";
    
    ce <= '1' when LoadInstruction(decodedInstruction) or StoreInstruction(decodedInstruction) else '0';
    
end behavioral;
