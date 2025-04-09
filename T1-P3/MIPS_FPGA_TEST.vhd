library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MIPS_FPGA_TEST is
    port (
        clk_100MHz      : in  std_logic;  
        rst_n           : in  std_logic; 
        
        -- Display interface
        display_en_n    : out std_logic_vector(3 downto 0);  
        segments        : out std_logic_vector(7 downto 0)   
    );
end MIPS_FPGA_TEST;

architecture structural of MIPS_FPGA_TEST is
    signal clk_25MHz    : std_logic;
    signal rst_sync     : std_logic;
    signal rst          : std_logic;
    
    -- MIPS signals
    signal instructionAddress  : std_logic_vector(31 downto 0);
    signal instruction         : std_logic_vector(31 downto 0);
    signal dataAddress         : std_logic_vector(31 downto 0);
    signal data_in             : std_logic_vector(31 downto 0);
    signal data_out            : std_logic_vector(31 downto 0);
    signal ce                  : std_logic;
    signal wbe                 : std_logic_vector(3 downto 0);
    
    -- Display signals
    signal reg_disp_out       : std_logic_vector(31 downto 0);
    signal hex0, hex1, hex2, hex3 : std_logic_vector(3 downto 0);
    signal display0, display1, display2, display3 : std_logic_vector(7 downto 0);
    
begin
    rst <= not rst_n;
    
    -- Clock Manager (100MHz to 25MHz)
    CLK_MANAGER: entity work.ClockManager
    port map (
        clk_100MHz  => clk_100MHz,
        clk_25MHz   => clk_25MHz,
        clk_50MHz   => open,
        clk_10MHz   => open,
        clk_5MHz    => open
    );
    
    -- Reset Synchronizer
    RESET_SYNC: entity work.ResetSynchonizer
    port map (
        clk     => clk_25MHz,
        rst_in  => rst,
        rst_out => rst_sync
    );
    
    -- MIPS Processor
    MIPS: entity work.MIPS_monocycle
    generic map (
        PC_START_ADDRESS => x"00400000"
    )
    port map (
        clk                 => clk_25MHz,
        rst                 => rst_sync,
        instructionAddress  => instructionAddress,
        instruction         => instruction,
        dataAddress         => dataAddress,
        data_in             => data_in,
        data_out            => data_out,
        ce                  => ce,
        wbe                 => wbe
    );
    
    -- Instruction Memory
    INSTR_MEM: entity work.Memory
    generic map (
        SIZE            => 1024,
        ADDR_WIDTH      => 30,
        COL_WIDTH       => 8,
        NB_COL          => 4,
        OFFSET          => x"00400000",
        imageFileName   => "t1p3_code.txt"
    )
    port map (
        clk         => clk_25MHz,
        ce          => '1',
        wbe         => "0000",
        address     => instructionAddress(31 downto 2),
        data_in     => (others => '0'),
        data_out    => instruction
    );
    
    -- Data Memory
    DATA_MEM: entity work.Memory
    generic map (
        SIZE            => 1024,
        ADDR_WIDTH      => 30,
        COL_WIDTH       => 8,
        NB_COL          => 4,
        OFFSET          => x"10010000",
        imageFileName   => "t1p3_data.txt"
    )
    port map (
        clk         => clk_25MHz,
        wbe         => wbe,
        ce          => ce,
        address     => dataAddress(31 downto 2),
        data_in     => data_out,
        data_out    => data_in
    );
    
    -- Register dataout
process(clk_25MHz, rst_sync)
begin
    if rst_sync = '1' then
        reg_disp_out <= (others => '0');
    elsif rising_edge(clk_25MHz) then
        if ce = '1' and dataAddress(31) = '1' then
            reg_disp_out <= data_out;
        end if;
    end if;
end process;
    
    -- Split 32-bit dataAddress into 4 hex digits
    hex3 <= reg_disp_out(31 downto 28);
    hex2 <= reg_disp_out(27 downto 24);
    hex1 <= reg_disp_out(23 downto 20);
    hex0 <= reg_disp_out(19 downto 16);
    
    -- Hex to 7-segment converters
    HEX00: entity work.BCD7seg
    port map (
        bcd     => hex0,
        segments => display0
    );
    
    HEX11: entity work.BCD7seg
    port map (
        bcd     => hex1,
        segments => display1
    );
    
    HEX22: entity work.BCD7seg
    port map (
        bcd     => hex2,
        segments => display2
    );
    
    HEX33: entity work.BCD7seg
    port map (
        bcd     => hex3,
        segments => display3
    );
    
    -- Display Controller
    DISP_CTRL: entity work.DisplayCtrl
    port map (
        clk         => clk_25MHz,
        rst         => rst_sync,
        segments    => segments,
        display_en_n => display_en_n,
        display0    => display0,
        display1    => display1,
        display2    => display2,
        display3    => display3
    );
    
end structural;
