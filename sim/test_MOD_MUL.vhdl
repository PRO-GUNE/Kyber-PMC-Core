library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity test_MOD_MUL is
end test_MOD_MUL ; 

architecture testbench of test_MOD_MUL is
    component MOD_MUL
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            enable : in  std_logic;
            a      : in  std_logic_vector(11 downto 0);
            b      : in  std_logic_vector(11 downto 0);
            mult   : out std_logic_vector(11 downto 0)
        );
    end component;

    signal a_in, b_in, mult : std_logic_vector(11 downto 0) := (others => '0');
    signal clk, reset : std_logic := '0';
    signal enable : std_logic := '1';

begin

    UUT : MOD_MUL
    port map(
        clk => clk,
        reset => reset,
        enable => enable,
        a => a_in,
        b => b_in,
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
    reset <= '1';
    wait for 10 ns;
    reset <= '0';
    wait for 10 ns;

    -- Reset time
    a_in <= "000000000000"; -- 0
    b_in <= "000000000000"; -- 0
    wait for 10 ns;

    -- Test case 1: Multiplication of two positive numbers
    a_in <= "000000000001"; -- 1
    b_in <= "000000000001"; -- 1
    wait for 10 ns;
    
    -- Test case 2: Multiplication of zero and a positive number
    a_in <= "000000000001"; -- 0
    b_in <= "000000000010"; -- 2
    wait for 10 ns;
    
    -- Test case 3: Multiplication of two large positive numbers
    a_in <= "011111111111"; -- 2047
    b_in <= "011111111111"; -- 2047
    wait for 10 ns;
    assert mult = "000000000000" report "Test case 1 failed" severity error; -- 0

    -- Test case 3: post scaling by half (1665)
    a_in <= "110010000001"; -- 3201
    b_in <= "101011110111"; -- 2807
    wait for 10 ns;
    assert mult = "000010101001" report "Test case 2 failed" severity error; -- 169
    
    wait for 10 ns;
    assert mult = "000101010010" report "Test case 3 failed" severity error; -- 338
    
    wait for 10 ns;
    assert mult = "000110111001" report "Test case 4 failed" severity error; -- 441
    
    wait for 10 ns;
    assert mult = "110011000001" report "Test case 5 failed" severity error; -- 3265
    
    wait;
        
    end process ; -- main_test

end architecture ;