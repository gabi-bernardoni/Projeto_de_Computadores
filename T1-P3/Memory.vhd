--
-- Single-Port BRAM with Byte-wide Write Enable
-- 2x8-bit write
-- Read-First mode
-- Single-process description
-- Compact description of the write with a for-loop statement
-- Column width and number of columns easily configurable
--
-- 
-- Download: http://www.xilinx.com/txpatches/pub/documentation/misc/xstug_examples.zip
-- File: HDL_Coding_Techniques/rams/bytewrite_ram_1b.vhd
--
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all; 
use std.textio.all;
use work.Util_pkg.all;

entity Memory is
    generic (
        SIZE            : integer := 1024;
        ADDR_WIDTH      : integer := 10;
        COL_WIDTH       : integer := 8;
        NB_COL          : integer := 2;
        imageFileName   : string := "UNUSED";        -- Memory content to be loaded
        OFFSET          : UNSIGNED(31 downto 0) := x"00000000"
    );
    port (
        clk         : in std_logic;
        wbe         : in std_logic_vector(NB_COL - 1 downto 0);
        ce          : in std_logic;
        address     : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_in     : in std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0);
        data_out    : out std_logic_vector(NB_COL * COL_WIDTH - 1 downto 0)
    );
end Memory;

architecture behavioral of Memory is
    type Memory is array (0 to SIZE - 1) of std_logic_vector (NB_COL * COL_WIDTH - 1 downto 0);
    
    constant HEX_DIGITS: integer := (NB_COL * COL_WIDTH ) / 4;
    
    impure function MemoryLoad (imageFileName : in string) return Memory is
        FILE imageFile : text open READ_MODE is imageFileName;
        variable fileLine : line;
        variable memoryArray : Memory;
        variable data: string(1 to HEX_DIGITS);
        
        variable i : natural := 0;
    begin   
        while NOT (endfile(imageFile)) loop
            readline (imageFile, fileLine);
            read (fileLine, data(1 to HEX_DIGITS));
            --report "address: " & integer'image(i);
            --report "data: " & data;
            --report "data to int: " & integer'image(integer'value(data(1 to HEX_DIGITS)));
                       
            memoryArray(i) := HexStringToStdLogicVector(data, HEX_DIGITS);
            i := i + 1;
        end loop;
        
        return memoryArray;
    end function;
    
    signal memoryArray : Memory := MemoryLoad(imageFileName);
    
    signal arrayAddress : integer;
    
begin
    
    arrayAddress <= TO_INTEGER(UNSIGNED(address) - OFFSET(31 downto 2));
    
    process (clk)
    begin
        if rising_edge(clk) then
            if ce = '1' then
                data_out <= memoryArray(arrayAddress);
                for i in 0 to NB_COL-1 loop
                    if wbe(i) = '1' then
                        memoryArray(arrayAddress)((i+1)*COL_WIDTH-1 downto i*COL_WIDTH) <= data_in((i+1)*COL_WIDTH-1 downto i*COL_WIDTH);
                    end if;
                end loop;
            end if;
        end if;
    end process;
end behavioral;
