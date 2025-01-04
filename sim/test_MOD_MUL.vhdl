library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity test_MOD_MUL is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        enable : in  std_logic;
        a      : in  std_logic_vector(11 downto 0);
        b      : in  std_logic_vector(11 downto 0);
        mult   : out std_logic_vector(11 downto 0)
    );
end test_MOD_MUL ; 

architecture testbench of test_MOD_MUL is
    component MUL
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            mult   : out std_logic_vector(11 downto 0)
        );
    end component;

    signal a, b, mult : std_logic_vector(11 downto 0) := (others => '0');
    signal clk, reset : std_logic := '0';
    signal enable : std_logic := '1';

begin

    UUT : MUL
    port map(
        clk => clk,
        reset => reset,
        enable => enable,
        a => a,
        b => b,
        mult => mult
    );

    clk_process : process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process ; -- clk_process

    main_test : process
    
    begin

    -- Reset time
    a_in <= "000000000000"; -- 0
    b_in <= "000000000000"; -- 0
    wait for 10 ns;

    -- Test case 1: Multiplication of two positive numbers
    a_in <= "000000000001"; -- 1
    b_in <= "000000000010"; -- 2
    wait for 10 ns;

    -- Test case 2: Multiplication of zero and a positive number
    a_in <= "000000000000"; -- 0
    b_in <= "000000000010"; -- 2
    wait for 10 ns;
    
    -- Test case 3: Multiplication of two large positive numbers
    a_in <= "011111111111"; -- 2047
    b_in <= "011111111111"; -- 2047
    assert mult = "000000000000" report "Test case 1 failed" severity error;
    wait for 10 ns;
    
    -- Test case 4: Multiplication of specific test case
    a_in <= "101011011111"; -- 2783
    b_in <= "000000010001"; -- 17
    wait for 10 ns;
    assert mult = "000000000010" report "Test case 2 failed" severity error;
    
    wait for 10 ns;
    assert mult = "000000000000" report "Test case 3 failed" severity error;
    
    wait for 10 ns;
    assert mult = "100100010111" report "Test case 4 failed" severity error;
       
    wait for 10 ns;
    assert mult = "001011000001" report "Test case 5 failed" severity error;
    wait;
        
    end process ; -- main_test

end architecture ;