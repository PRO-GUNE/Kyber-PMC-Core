library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_MOD_K2_RED is
end entity test_MOD_K2_RED;

architecture testbench of test_MOD_K2_RED is
    component MOD_K2_RED is
        port (
            clk     : in std_logic;  -- Added clock input
            reset   : in std_logic;  -- Added reset input
            c_in    : in std_logic_vector(23 downto 0);
            c_out   : out std_logic_vector(11 downto 0);
            c1_test : out signed(19 downto 0);
            c2_test : out signed(11 downto 0)
        );
    end component MOD_K2_RED;
    
    signal clk, reset : std_logic := '0';
    signal c_in : std_logic_vector(23 downto 0) := (others => '0');
    signal c_out : std_logic_vector(11 downto 0);
    signal c1_test : signed(19 downto 0);
    signal c2_test : signed(11 downto 0);
begin
    UUT: MOD_K2_RED
    port map (
        clk => clk,
        reset => reset,
        c_in => c_in,
        c_out => c_out,
        c1_test => c1_test,
        c2_test => c2_test
    );

    clk_process : process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;

    process begin
    -- reset
    reset <= '1';
    wait for 10 ns;
    reset <= '0';
    wait for 10 ns;

    -- Test 1: All zeros
    c_in <= "000000000000000000000000";
    wait for 10 ns;

    -- Test 2: Random values
    c_in <= "001010101010101010101010";
    wait for 10 ns;
    assert c_out = "000000000000" report "Test 1 failed" severity error;
    
    -- Test 3: Random values
    c_in <= "000011001100110011001100";
    wait for 10 ns;
    assert c_out = "110010111011" report "Test 2 failed" severity error;
    
    -- Test 4: Random values
    c_in <= "000000000000011001000110"; -- 1606 -> 1765
    wait for 10 ns;
    assert c_out = "011101010011" report "Test 3 failed" severity error;
    
    c_in <= "100010010001101001110111"; -- 8985207 -> 3265
    wait for 10 ns;
    assert c_out = "011011100101" report "Test 4 failed" severity error;
    
    wait for 10 ns;
    assert c_out = "110011000001" report "Test 5 failed" severity error;
    
    -- End simulation
    wait;
    end process;

end architecture testbench;