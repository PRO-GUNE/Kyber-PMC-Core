library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUL is
    port (
        clk     : in  std_logic;                      -- Added clock for M register
        enable  : in  std_logic;
        a       : in  std_logic_vector(11 downto 0);
        b       : in  std_logic_vector(11 downto 0);
        result  : out std_logic_vector(23 downto 0)
    );
end entity MUL;

architecture rtl of MUL is
    -- Attribute to ensure DSP inference
    attribute use_dsp : string;
    attribute use_dsp of rtl : architecture is "yes";
    
    -- Pipeline registers for DSP M register usage
    signal a_reg : std_logic_vector(11 downto 0);
    signal b_reg : std_logic_vector(11 downto 0);
    signal mult_result : std_logic_vector(23 downto 0);

begin
    -- Register inputs for DSP M register inference
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                -- Input registers
                a_reg <= a;
                b_reg <= b;
                -- M register will be inferred here
                mult_result <= std_logic_vector(unsigned(a_reg) * unsigned(b_reg));
            end if;
        end if;
    end process;
    
    -- Output assignment
    result <= mult_result;

end architecture rtl;