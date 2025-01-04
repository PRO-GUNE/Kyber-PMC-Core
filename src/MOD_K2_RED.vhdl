library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MOD_K2_RED is
    port (
        clk     : in std_logic;  -- Added clock input
        reset     : in std_logic;  -- Added reset input
        c_in    : in std_logic_vector(23 downto 0);
        c_out   : out std_logic_vector(11 downto 0)
    );
end entity MOD_K2_RED;

architecture behavioral of MOD_K2_RED is
    -- Pipeline registers for intermediate results
    signal stage1_reg : signed(15 downto 0);
    signal stage2_reg : unsigned(11 downto 0);
    
    -- Debug signals (kept from original)
    signal c1_test : signed(15 downto 0);
    signal c2_test : unsigned(11 downto 0);
    
begin
    -- Pipeline Stage 1
    process(clk)
        variable c_l: unsigned(15 downto 0);
        variable c_h: unsigned(23 downto 8);
        variable c1: signed(15 downto 0);
        variable c1_val: integer := 0;
    begin
        if reset = '1' then
            stage1_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Step 1 calculations
            c_l := resize(unsigned(c_in(7 downto 0)), 16);
            c_h := unsigned(c_in(23 downto 8));
            c1_val := to_integer((shift_left(c_l, 3) - c_h) + (shift_left(c_l, 2) + c_l));
            c1 := to_signed(c1_val, 16);
            
            -- Register the result
            stage1_reg <= c1;
        end if;
    end process;

    -- Debug output for stage 1
    c1_test <= stage1_reg;

    -- Pipeline Stage 2
    process(clk)
        variable c_h1: signed(11 downto 0);
        variable c_l1: signed(11 downto 0);
        variable c2: unsigned(11 downto 0);
        variable c2_val: integer := 0;
    begin
        if reset = '1' then
            stage2_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Step 2 calculations using registered value from stage 1
            c_h1 := resize(signed(stage1_reg(15 downto 8)), 12);
            c_l1 := signed(resize(unsigned(stage1_reg(7 downto 0)), 12));
            c2_val := to_integer((shift_left(c_l1, 3) - c_h1) + (shift_left(c_l1, 2) + c_l1));
            c2 := to_unsigned(c2_val, 12);
            
            -- Register the result
            stage2_reg <= c2;
        end if;
    end process;

    -- Debug output for stage 2
    c2_test <= stage2_reg;

    -- Final output assignment
    c_out <= std_logic_vector(stage2_reg);
    
end architecture behavioral;