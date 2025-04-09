-------------------------------------------------------------------------
-- Design unit: MIPS monocycle test bench
-- Description: Connects MIPS to instruction and data memories
--              Generates clk and rst
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MIPS_monocycle_tb is
end MIPS_monocycle_tb;

architecture structural of MIPS_monocycle_tb is

    signal clk: std_logic := '0';
    signal rst, ce, clk_n: std_logic;
    signal wbe: std_logic_vector(3 downto 0);
    signal instructionAddress, dataAddress, instruction, data_in, data_out: std_logic_vector(31 downto 0);

    constant MARS_INSTRUCTION_OFFSET    : UNSIGNED(31 downto 0) := x"00400000";
    constant MARS_DATA_OFFSET           : UNSIGNED(31 downto 0) := x"10010000";
    
begin

    clk <= not clk after 5 ns;
    
    clk_n <= not clk;
        
    rst <= '1', '0' after 2 ns;
                
        
    MIPS_MONOCYCLE: entity work.MIPS_monocycle(behavioral) 
        generic map (
            PC_START_ADDRESS => MARS_INSTRUCTION_OFFSET
        )
        port map (
            clk                 => clk,
            rst                 => rst,
            
            -- Instruction memory interface
            instructionAddress  => instructionAddress,    
            instruction         => instruction,        
                 
             -- Data memory interface
            dataAddress         => dataAddress,
            data_in             => data_in,
            data_out            => data_out,
            ce                  => ce,
            wbe                 => wbe
        );
    
    
    INSTRUCTION_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 1024,  -- Memory depth in words
            ADDR_WIDTH      => 30,
            COL_WIDTH       => 8,
            NB_COL          => 4,   
            OFFSET          => MARS_INSTRUCTION_OFFSET,   -- MARS initial address (mapped to memory address 0x00000000)
            imageFileName   => "t1p3_code.txt"
        )
        port map (
            clk             => clk,
            ce              => '1',
            wbe             => "0000",
            address         => instructionAddress(31 downto 2), -- Converts byte address to word address     
            data_in         => (others=>'0'),
            data_out        => instruction
        );
        
    -- Data memory operates in clk falling edges
    -- in order to support monocycle execution by MIPS
    DATA_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 1024,  -- Memory depth in words
            ADDR_WIDTH      => 30,
            COL_WIDTH       => 8,
            NB_COL          => 4,           
            OFFSET          => MARS_DATA_OFFSET,  -- MARS initial address (mapped to memory address 0x00000000)
            imageFileName   => "t1p3_data.txt"
        )
        port map (
            clk             => clk_n,
            wbe             => wbe,
            ce              => ce,
            address         => dataAddress(31 downto 2),    -- Converts byte address to word address 
            data_in         => data_out,
            data_out        => data_in
        );    
    
end structural;


