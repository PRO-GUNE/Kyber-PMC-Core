library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_MOD_ADD is
end entity test_MOD_ADD;

architecture testbench of test_MOD_ADD is
    component MOD_ADD is
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            sum    : out std_logic_vector(11 downto 0)
        );
    end component MOD_ADD;

    signal clk, reset : std_logic := '0';
    signal enable : std_logic := '1';
    signal a, b : std_logic_vector(11 downto 0) := (others => '0');
    signal sum : std_logic_vector(11 downto 0);
begin
    UUT: MOD_ADD 
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            a => a, 
            b => b, 
            sum => sum
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

    -- Test 1: a = 0, b = 0
    a <= "000000000000";
    b <= "000000000000";
    wait for 10 ns;
    -- Test 3: a = 100, b = 0
    a <= "000000110010";
    b <= "000000000000";
    wait for 10 ns;

    -- Test 3: a = 100, b = 200
    a <= "000000110010";
    b <= "000001100100";
    wait for 10 ns;
    assert sum = "000000000000" report "Test 1 failed" severity error;

    -- Test 4: a = 3328, b = 1
    a <= "110100000000";
    b <= "000000000001";
    wait for 10 ns;
    assert sum = "000000110010" report "Test 2 failed" severity error;

    -- Test 5: a = 3328, b = 3328
    a <= "110100000000";
    b <= "110100000000";
    wait for 10 ns;
    assert sum = "000010010110" report "Test 3 failed" severity error;
    
    wait for 10 ns;
    assert sum = "000000000000" report "Test 4 failed" severity error;
    
    wait for 10 ns;
    assert sum = "110011111111" report "Test 5 failed" severity error;

    wait;
    end process;

end architecture testbench;