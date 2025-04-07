library IEEE;
use IEEE.std_logic_1164.all;

entity MIPS_FPGA_TEST is
    port (
        clk_100MHz  : in  std_logic;  -- Clock da Nexys 3 (100 MHz)
        rst_n       : in  std_logic;  -- Reset (ativo baixo)
        pc_debug    : out std_logic_vector(31 downto 0)
    );
end MIPS_FPGA_TEST;

architecture structural of MIPS_FPGA_TEST is
    -- Sinais de clock e reset
    signal clk_25MHz    : std_logic;  
    signal rst_sync     : std_logic;  
    signal rst          : std_logic;  -

    -- Sinais do MIPS
    signal instructionAddress, instruction, dataAddress, data_in, data_out : std_logic_vector(31 downto 0);
    signal ce : std_logic;
    signal wbe : std_logic_vector(3 downto 0);

begin
    -- Conversão do reset (ativo baixo -> ativo alto)
    rst <= not rst_n;

    CLK_MANAGER: entity work.ClockManager
    port map (
        clk_100MHz  => clk_100MHz,
        clk_25MHz   => clk_25MHz,  -- Usaremos apenas 25 MHz
        clk_50MHz   => open,
        clk_10MHz   => open,
        clk_5MHz    => open
    );

    -- Sincronizador de Reset
    RST_SYNC: entity work.ResetSynchonizer
    port map (
        clk     => clk_25MHz,  -- Sincronizado com o clock de 25 MHz
        rst_in  => rst,
        rst_out => rst_sync
    );

    -- MIPS (operando a 25 MHz)
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

    -- Memória de Instruções
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
        clk         => clk_25MHz,
        ce          => '1',
        wbe         => "0000",
        address     => instructionAddress(31 downto 2),
        data_in     => (others => '0'),
        data_out    => instruction
    );

    -- Memória de Dados
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
        clk         => clk_25MHz,
        wbe         => wbe,
        ce          => ce,
        address     => dataAddress(31 downto 2),
        data_in     => data_out,
        data_out    => data_in
    );

    -- Debug: Monitorar o PC
    pc_debug <= instructionAddress;
end structural;
