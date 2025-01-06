library ieee;
use ieee.std_logic_1164.all;

entity test_BUTTERFLY_UNIT is
end entity test_BUTTERFLY_UNIT;

architecture testbench of test_BUTTERFLY_UNIT is

    -- Import the entity and architecture of the BUTTERFLY_UNIT module
    component BUTTERFLY_UNIT
        port (
            clk : in std_logic;
            mode : in std_logic;
            reset : in std_logic;
            enable : in std_logic;
            u_in : in std_logic_vector(11 downto 0);
            v_in : in std_logic_vector(11 downto 0);
            twiddle : in std_logic_vector(11 downto 0);
            u_out : out std_logic_vector(11 downto 0);
            v_out : out std_logic_vector(11 downto 0);
            -- debug outs
            u_v_debug : out std_logic_vector(11 downto 0)

        );
    end component BUTTERFLY_UNIT;

    -- Declare signals for testbench
    signal clk : std_logic := '0';
    signal mode : std_logic := '0';
    signal reset : std_logic := '0';
    signal enable : std_logic := '1';
    signal u_in : std_logic_vector(11 downto 0) := (others => '0');
    signal v_in : std_logic_vector(11 downto 0) := (others => '0');
    signal twiddle : std_logic_vector(11 downto 0) := (others => '0');
    signal u_out : std_logic_vector(11 downto 0);
    signal v_out, u_v_debug : std_logic_vector(11 downto 0);

begin
    -- Instantiate the BUTTERFLY_UNIT module
    dut: BUTTERFLY_UNIT port map (
            clk => clk,
            mode => mode,
            reset => reset,
            enable => enable,
            u_in => u_in,
            v_in => v_in,
            twiddle => twiddle,
            u_out => u_out,
            v_out => v_out,
            u_v_debug => u_v_debug
        );

    -- Clock process
    process
    begin
        clk <= not clk;
        wait for 5 ns;
    end process;

    process
    begin
        -- reset
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 10 ns;

        -- Test 1: Add/Sub mode
        mode <= '1';
        twiddle <= "100011101101"; -- 2285 (w^0 * k^-2 mod 3329)
        u_in <= "000000000000"; -- 0
        v_in <= "000010000000"; -- 128
        wait for 10 ns;
        u_in <= "000001000000"; -- 64
        v_in <= "000011000000"; -- 192
        wait for 10 ns;
        wait for 70 ns;
        assert u_out = "000001000000" report "Test 2 failed for u_out" severity error; -- 64
        assert v_out = "110011000001" report "Test 2 failed for v_out" severity error; -- 3265
        wait for 10 ns;
        assert u_out = "000010000000" report "Test 1 failed for u_out" severity error; -- 128
        assert v_out = "110011000001" report "Test 1 failed for v_out" severity error; -- 3265
        
        -- -- Test 2: u +/- vw mode 
        mode <= '0';
        twiddle <= "101000001011"; -- 2571 (w^64 * k^-2 mod 3329)
        u_in <= "000000000000"; -- 0
        v_in <= "000010000000"; -- 128
        wait for 10 ns;
        u_in <= "000001000000"; -- 64
        v_in <= "000011000000"; -- 192
        wait for 100 ns; 
        assert u_out = "011000111110" report "Test 2 failed for u_out" severity error; -- 1598
        assert v_out = "011011000011" report "Test 2 failed for v_out" severity error; -- 1731
        wait for 100 ns;
        assert u_out = "100110011101" report "Test 3 failed for u_out" severity error; -- 2461
        assert v_out = "001111100100" report "Test 3 failed for v_out" severity error; -- 996

        wait;

    end process;

end architecture testbench;