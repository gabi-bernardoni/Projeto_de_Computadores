library IEEE;
use IEEE.std_logic_1164.all;

entity MIPS_FPGA_TEST_tb is
end MIPS_FPGA_TEST_tb;

architecture tb of MIPS_FPGA_TEST_tb is

    signal clk_100MHz    : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal display_en_n  : std_logic_vector(3 downto 0);
    signal segments      : std_logic_vector(7 downto 0);

    -- clock de 100MHz
    constant clk_period : time := 10 ns;

begin

    -- Instancia a unidade 
    uut: entity work.MIPS_FPGA_TEST
        port map (
            clk_100MHz     => clk_100MHz,
            rst_n          => rst_n,
            display_en_n   => display_en_n,
            segments       => segments
        );

    -- Geração do clock de 100MHz
    clk_process : process
    begin
        while now < 1 ms loop  
            clk_100MHz <= '0';
            wait for clk_period / 2;
            clk_100MHz <= '1';
            wait for clk_period / 2;
        end loop;
        wait;  -- termina simulação
    end process;

    -- Geração do reset
    rst_process : process
    begin
        rst_n <= '0';          -- reset ativo
        wait for 100 ns;
        rst_n <= '1';          -- libera reset
        wait;
    end process;

end tb;

