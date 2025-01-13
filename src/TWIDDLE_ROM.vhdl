-- ROM Inference on array
-- File: TWIDDLE_ROM.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TWIDDLE_ROM is
    port(
        clk : in std_logic;
        en : in std_logic;
        addr_0 : in std_logic_vector(6 downto 0);
        addr_1 : in std_logic_vector(6 downto 0);
        data_0 : out std_logic_vector(11 downto 0);
        data_1 : out std_logic_vector(11 downto 0)
    );
end TWIDDLE_ROM;

architecture behavioral of TWIDDLE_ROM is
    type rom_type is array (0 to 127) of std_logic_vector(11 downto 0);
    signal ROM : rom_type := (
        X"8ed", X"a0b", X"b9a", X"714", X"5d5", X"58e", X"11f", X"0ca", 
        X"c56", X"26e", X"629", X"0b6", X"3c2", X"84f", X"73f", X"5bc", 
        X"23d", X"7d4", X"108", X"17f", X"9c4", X"5b2", X"6bf", X"c7f", 
        X"a58", X"3f9", X"2dc", X"260", X"6fb", X"19b", X"c34", X"6de", 
        X"4c7", X"28c", X"ad9", X"3f7", X"7f4", X"5d3", X"be7", X"6f9", 
        X"204", X"cf9", X"bc1", X"a67", X"6af", X"877", X"07e", X"5bd", 
        X"9ac", X"ca7", X"bf2", X"33e", X"06b", X"774", X"c0a", X"94a", 
        X"b73", X"3c1", X"71d", X"a2c", X"1c0", X"8d8", X"2a5", X"806", 
        X"8b2", X"1ae", X"22b", X"34b", X"81e", X"367", X"60e", X"069", 
        X"1a6", X"24b", X"0b1", X"c16", X"bde", X"b35", X"626", X"675", 
        X"c0b", X"30a", X"487", X"c6e", X"9f8", X"5cb", X"aa7", X"45f", 
        X"6cb", X"284", X"999", X"15d", X"1a2", X"149", X"c65", X"cb6", 
        X"331", X"449", X"25b", X"262", X"52a", X"7fc", X"748", X"180", 
        X"842", X"c79", X"4c2", X"7ca", X"997", X"0dc", X"85e", X"686", 
        X"860", X"707", X"803", X"31a", X"71b", X"9ab", X"99b", X"1de", 
        X"c95", X"bcd", X"3e4", X"3df", X"3be", X"74d", X"5f2", X"cb3"  
    );
    attribute rom_style : string;
    attribute rom_style of ROM : signal is "block";

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if (en = '1') then
                data_0 <= ROM(to_integer(unsigned(addr_0)));
                data_1 <= ROM(to_integer(unsigned(addr_1)));
            end if;
        end if;
    end process;

end behavioral;