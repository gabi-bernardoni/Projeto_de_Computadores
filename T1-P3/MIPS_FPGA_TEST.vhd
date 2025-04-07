library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MIPS_FPGA_TEST is
    port (
        clk_100MHz      : in  std_logic;  -- 100 MHz board clock
        rst_n           : in  std_logic;  -- Active low reset (push-button)
        
        -- Display interface
        display_en_n    : out std_logic_vector(3 downto 0);  -- Display enable (active low)
        segments        : out std_logic_vector(7 downto 0)   -- Segment control
    );
end MIPS_FPGA_TEST;

architecture structural of MIPS_FPGA_TEST is
    -- Clock signals
    signal clk_50MHz    : std_logic;
    signal clk_div2     : std_logic := '0';
    
    -- Reset signals
    signal rst_sync     : std_logic;
    signal rst          : std_logic;
    
    -- MIPS signals
    signal instructionAddress  : std_logic_vector(31 downto 0);
    signal instruction         : std_logic_vector(31 downto 0);
    signal dataAddress         : std_logic_vector(31 downto 0);
    signal data_in            : std_logic_vector(31 downto 0);
    signal data_out           : std_logic_vector(31 downto 0);
    signal ce                 : std_logic;
    signal wbe                : std_logic_vector(3 downto 0);
    
    -- Display signals
    signal reg_disp_in        : std_logic_vector(31 downto 0);
    signal reg_disp_out       : std_logic_vector(31 downto 0);
    signal bcd0, bcd1, bcd2, bcd3 : std_logic_vector(3 downto 0);
    signal display0, display1, display2, display3 : std_logic_vector(7 downto 0);
    
begin
    -- Convert active-low reset to active-high
    rst <= not rst_n;
    
    -- Clock Manager (100MHz to 50MHz)
    CLK_MANAGER: entity work.ClockManager
    port map (
        clk_100MHz  => clk_100MHz,
        clk_50MHz   => clk_50MHz,
        clk_25MHz   => open,
        clk_10MHz   => open,
        clk_5MHz    => open
    );
    
    -- Clock divider (50MHz to 25MHz)
    process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            clk_div2 <= not clk_div2;
        end if;
    end process;
    
    -- Reset Synchronizer
    RST_SYNC: entity work.ResetSynchonizer
    port map (
        clk     => clk_50MHz,
        rst_in  => rst,
        rst_out => rst_sync
    );
    
    -- MIPS Processor
    MIPS: entity work.MIPS_monocycle
    generic map (
        PC_START_ADDRESS => x"00400000"
    )
    port map (
        clk                 => clk_div2,  -- 25MHz clock
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
        SIZE            => 64,
        ADDR_WIDTH      => 30,
        COL_WIDTH       => 8,
        NB_COL          => 4,
        OFFSET          => x"00400000",
        imageFileName   => "t1_code.txt"
    )
    port map (
        clk         => clk_div2,
        ce          => '1',
        wbe         => "0000",
        address     => instructionAddress(31 downto 2),
        data_in     => (others => '0'),
        data_out    => instruction
    );
    
    -- Data Memory
    DATA_MEM: entity work.Memory
    generic map (
        SIZE            => 10,
        ADDR_WIDTH      => 30,
        COL_WIDTH       => 8,
        NB_COL          => 4,
        OFFSET          => x"10010000",
        imageFileName   => "t1_data.txt"
    )
    port map (
        clk         => clk_div2,
        wbe         => wbe,
        ce          => ce,
        address     => dataAddress(31 downto 2),
        data_in     => data_out,
        data_out    => data_in
    );
    
    -- Register to hold display value (dataAddress)
    reg_disp_in <= dataAddress;
    
    REG_DISP: process(clk_div2, rst_sync)
    begin
        if rst_sync = '1' then
            reg_disp_out <= (others => '0');
        elsif rising_edge(clk_div2) then
            if ce = '1' then
                reg_disp_out <= reg_disp_in;
            end if;
        end if;
    end process;
    
    -- Split 32-bit dataAddress into 4 BCD digits (8 hex digits)
    -- For simplicity, we'll just show the hex value without BCD conversion
    bcd3 <= reg_disp_out(31 downto 28);
    bcd2 <= reg_disp_out(27 downto 24);
    bcd1 <= reg_disp_out(23 downto 20);
    bcd0 <= reg_disp_out(19 downto 16);
    
    -- Hex to 7-segment converters
    HEX0: entity work.BCD7seg
    port map (
        bcd     => bcd0,
        segments => display0
    );
    
    HEX1: entity work.BCD7seg
    port map (
        bcd     => bcd1,
        segments => display1
    );
    
    HEX2: entity work.BCD7seg
    port map (
        bcd     => bcd2,
        segments => display2
    );
    
    HEX3: entity work.BCD7seg
    port map (
        bcd     => bcd3,
        segments => display3
    );
    
    -- Display Controller
    DISP_CTRL: entity work.DisplayCtrl
    port map (
        clk         => clk_50MHz,
        rst         => rst_sync,
        segments    => segments,
        display_en_n => display_en_n,
        display0    => display0,
        display1    => display1,
        display2    => display2,
        display3    => display3
    );
    
end structural;
