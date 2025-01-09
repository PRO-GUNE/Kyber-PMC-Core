library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MOD_SUB is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        enable : in  std_logic;
        a      : in  std_logic_vector(11 downto 0);
        b      : in  std_logic_vector(11 downto 0);
        diff   : out std_logic_vector(11 downto 0)
    );
end entity MOD_SUB;

architecture behavioral of MOD_SUB is
    -- Constants
    constant MODULUS : unsigned(11 downto 0) := to_unsigned(3329, 12);
        
    -- Attribute to guide DSP inference
    attribute use_dsp : string;
    attribute use_dsp of behavioral : architecture is "yes";
    
    -- Extended signal registers
    signal a_extended : unsigned(17 downto 0);
    signal b_extended : unsigned(47 downto 0);
    signal mult_one : unsigned(17 downto 0);
    signal mod_extended : unsigned(47 downto 0);
    
    -- DSP output registers
    signal temp_diff_reg : unsigned(47 downto 0);
    signal signed_diff : signed(47 downto 0);
    signal corrected_diff_reg : unsigned(47 downto 0);

begin
    -- Pipeline registers process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then

                temp_diff_reg <= (others => '0');
                corrected_diff_reg <= (others => '0');
                a_extended <= (others => '0');
                b_extended <= (others => '0');

            elsif enable = '1' then

                -- Stage 2: Extended registers
                a_extended <= resize(unsigned(a), 18);
                b_extended <= resize(unsigned(b), 48);
                
                -- Stage 3: DSP operation registers
                temp_diff_reg <= a_extended - b_extended;

                -- Stage 4: Final result register with comparison
                if signed_diff < 0 then
                    corrected_diff_reg <= temp_diff_reg + mod_extended;
                else
                    corrected_diff_reg <= temp_diff_reg;
                end if;

            end if;
        end if;
    end process;

    -- Constants and static signals
    mult_one <= "000000" & x"001";
    mod_extended <= resize(MODULUS, 48);
    signed_diff <= signed(temp_diff_reg);

    -- Output assignment
    diff <= std_logic_vector(corrected_diff_reg(11 downto 0));
end architecture behavioral;