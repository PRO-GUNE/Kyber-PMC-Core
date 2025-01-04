library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_MOD_SUB is
end entity test_MOD_SUB;

architecture testbench of test_MOD_SUB is
    component MOD_SUB is
        port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        enable : in  std_logic;
        a      : in  std_logic_vector(11 downto 0);
        b      : in  std_logic_vector(11 downto 0);
        diff   : out std_logic_vector(11 downto 0)
    );
    end component MOD_SUB;
    
    signal clk, reset : std_logic := '0';
    signal enable : std_logic := '1';

    signal a, b : std_logic_vector(11 downto 0) := (others => '0');
    signal diff : std_logic_vector(11 downto 0);

begin
    UUT: MOD_SUB
        port map (
            clk => clk,
            reset => reset,
            enable => enable,
            a => a,
            b => b,
            diff => diff
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

    -- Test case 1: a = 0, b = 0
    a <= "000000000000";
    b <= "000000000000";
    wait for 10 ns;
    -- Test case 2: a = 100, b = 50 -> 50
    a <= "000001100100";
    b <= "000000110010";
    wait for 10 ns;
    -- Test case 3: a = 500, b = 1000 -> 2829
    a <= "000111110100";
    b <= "001111101000";
    wait for 10 ns;
    assert diff = "000000000000" report "Test case 1 failed" severity error;
    -- Test case 4: a = 3328, b = 0 -> 3328
    a <= "110100000000";
    b <= "000000000000";
    wait for 10 ns;
    assert diff = "000000110010" report "Test case 2 failed" severity error;
    
    -- Test case 5: a = 0, b = 3328 -> 1
    a <= "000000000000";
    b <= "110100000000";
    wait for 10 ns;
    assert diff = "101100001101" report "Test case 3 failed" severity error;
    
    -- Test case 6: a = 3276, b = 705 -> 2571
    a <= "110011001100";
    b <= "001011000001";
    wait for 10 ns;
    assert diff = "110100000000" report "Test case 4 failed" severity error;
    
    wait for 10 ns;
    assert diff = "000000000001" report "Test case 5 failed" severity error;
    
    wait for 10 ns;
    assert diff = "101000001011" report "Test case 6 failed" severity error;
        
    -- End simulation
    wait;
    end process;
    
end architecture testbench;