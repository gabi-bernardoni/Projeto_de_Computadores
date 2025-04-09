library IEEE;
use IEEE.std_logic_1164.all;

entity MIPS_FPGA_TEST_tb is
end MIPS_FPGA_TEST_tb;

architecture behavioral of MIPS_FPGA_TEST_tb is
    -- Sinais de entrada
    signal clk_100MHz : std_logic := '0';
    signal rst_n      : std_logic := '0';

begin
    -- Gerador de clock (100 MHz, período 10 ns)
    clk_100MHz <= not clk_100MHz after 5 ns;

    -- Gerador de reset (inicia em '0', vai para '1' após 100 ns)
    rst_n <= '0', '1' after 100 ns;

    -- Instância do sistema completo
    UUT: entity work.MIPS_FPGA_TEST
    port map (
        clk_100MHz => clk_100MHz,
        rst_n      => rst_n,
        display_en_n    : out std_logic_vector(3 downto 0),  
        segments        : out std_logic_vector(7 downto 0) 
    );
        
end behavioral;
