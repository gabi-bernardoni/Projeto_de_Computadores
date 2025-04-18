library IEEE;
use IEEE.std_logic_1164.all;

entity BCD7seg is
    port (
        bcd      : in  std_logic_vector(3 downto 0);
        segments : out std_logic_vector(7 downto 0)  
    );
end BCD7seg;

architecture behavioral of BCD7seg is
begin
    with bcd select
        segments <= 
            "11000000" when "0000",  -- 0
            "11111001" when "0001",  -- 1
            "10100100" when "0010",  -- 2
            "10110000" when "0011",  -- 3
            "10011001" when "0100",  -- 4
            "10010010" when "0101",  -- 5
            "10000010" when "0110",  -- 6
            "11111000" when "0111",  -- 7
            "10000000" when "1000",  -- 8
            "10010000" when "1001",  -- 9
            "10001000" when "1010",  -- A
            "10000011" when "1011",  -- b
            "11000110" when "1100",  -- C
            "10100001" when "1101",  -- d
            "10000110" when "1110",  -- E
            "10001110" when "1111",  -- F
            "11111111" when others;  
end behavioral;