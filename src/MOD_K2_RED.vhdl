library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MOD_K2_RED is
    port (
        clk     : in std_logic;  -- Added clock input
        reset   : in std_logic;  -- Added reset input
        c_in    : in std_logic_vector(23 downto 0);
        c_out   : out std_logic_vector(11 downto 0);
        c1_test : out signed(19 downto 0);
        c2_test : out signed(11 downto 0)
    );
end entity MOD_K2_RED;

architecture behavioral of MOD_K2_RED is
    -- Pipeline registers for intermediate results
    signal stage1_reg : signed(19 downto 0);
    signal stage2_reg : signed(11 downto 0);
    
    -- Debug signals (kept from original)
    signal c1_test_val : signed(19 downto 0);
    signal c2_test_val : signed(11 downto 0);

    
    
begin
    -- Pipeline Stage 1
    process(clk, reset)
        variable c_l, c_h : signed(19 downto 0);
        variable c_h1: signed(11 downto 0);
        variable c_l1: signed(11 downto 0);      
    begin
        if reset = '1' then
            stage1_reg <= (others => '0');
            stage2_reg <= (others => '0');
            c_l := (others => '0');
            c_h := (others => '0');
            c_l1 := (others => '0');
            c_h1 := (others => '0');

        elsif rising_edge(clk) then
            -- Step 1 calculations
            c_l := signed(resize(unsigned(c_in(7 downto 0)), 20));
            c_h := signed(resize(unsigned(c_in(23 downto 8)), 20));
            
            -- Register the result
            stage1_reg  <= (shift_left(c_l, 3) - c_h) + (shift_left(c_l, 2) + c_l);

            -- Step 2 calculations using registered value from stage 1
            c_h1 := stage1_reg(19 downto 8);
            c_l1 := signed(resize(unsigned(stage1_reg(7 downto 0)), 12));
            
            -- Register the result
            stage2_reg <= (shift_left(c_l1, 3) - c_h1) + (shift_left(c_l1, 2) + c_l1);

        end if;
    end process;

    -- Debug output for stage 1
    c1_test_val <= stage1_reg;

    -- Debug output for stage 2
    c2_test_val <= stage2_reg;

    -- Final output assignment
    c_out <= std_logic_vector(stage2_reg);

    c1_test <= c1_test_val;
    c2_test <= c2_test_val;
    
end architecture behavioral;