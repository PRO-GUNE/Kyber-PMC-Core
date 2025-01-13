library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_BUTTERFLY_CORE is
end entity test_BUTTERFLY_CORE;

architecture testbench of test_BUTTERFLY_CORE is

    -- Component declaration for BUTTERFLY_CORE
    component BUTTERFLY_CORE
        port (
            clk       : in std_logic;
            mode      : in std_logic;
            reset     : in std_logic;
            enable    : in std_logic;
            u_in      : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
            v_in      : in std_logic_vector(47 downto 0); -- 4x 12-bit inputs
            tw_addr_0 : in std_logic_vector(6 downto 0);  -- twiddle address 0
            tw_addr_1 : in std_logic_vector(6 downto 0);  -- twiddle address 1
            u_out     : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs
            v_out     : out std_logic_vector(47 downto 0); -- 4x 12-bit outputs

            debug_out : out std_logic_vector(47 downto 0); -- Debug outputs
            u0        : out std_logic_vector(11 downto 0);
            u1        : out std_logic_vector(11 downto 0);
            u2        : out std_logic_vector(11 downto 0);
            u3        : out std_logic_vector(11 downto 0);
            v0        : out std_logic_vector(11 downto 0);
            v1        : out std_logic_vector(11 downto 0);
            v2        : out std_logic_vector(11 downto 0);
            v3        : out std_logic_vector(11 downto 0)
        );
    end component BUTTERFLY_CORE;

    -- Testbench signals
    signal clk       : std_logic := '0';
    signal mode      : std_logic := '0';
    signal reset     : std_logic := '0';
    signal enable    : std_logic := '1';
    signal u_in      : std_logic_vector(47 downto 0) := (others => '0');
    signal v_in      : std_logic_vector(47 downto 0) := (others => '0');
    signal tw_addr_0 : std_logic_vector(6 downto 0) := (others => '0');
    signal tw_addr_1 : std_logic_vector(6 downto 0) := (others => '0');
    signal u_out     : std_logic_vector(47 downto 0);
    signal v_out     : std_logic_vector(47 downto 0);
    signal debug_out : std_logic_vector(47 downto 0);

    signal u0        : std_logic_vector(11 downto 0);
    signal u1        : std_logic_vector(11 downto 0);
    signal u2        : std_logic_vector(11 downto 0);
    signal u3        : std_logic_vector(11 downto 0);
    signal v0        : std_logic_vector(11 downto 0);
    signal v1        : std_logic_vector(11 downto 0);
    signal v2        : std_logic_vector(11 downto 0);
    signal v3        : std_logic_vector(11 downto 0);

begin

    -- Instantiate the BUTTERFLY_CORE
    dut: BUTTERFLY_CORE
        port map (
            clk       => clk,
            mode      => mode,
            reset     => reset,
            enable    => enable,
            u_in      => u_in,
            v_in      => v_in,
            tw_addr_0 => tw_addr_0,
            tw_addr_1 => tw_addr_1,
            u_out     => u_out,
            v_out     => v_out,
            debug_out => debug_out,
            u0 => u0,
            u1 => u1,
            u2 => u2,
            u3 => u3,
            v0 => v0,
            v1 => v1,
            v2 => v2,
            v3 => v3
        );

    -- Clock generation
    clk_process: process
    begin
        clk <= not clk;
        wait for 5 ns; -- 10 ns clock period
    end process;

    -- Test process
    process
    begin
        -- Apply reset
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 10 ns;

        -- Test 1: Add/Sub mode (mode = '1')
        mode <= '1';
        tw_addr_0 <= "0000000"; -- Twiddle address for first set
        tw_addr_1 <= "0000000"; -- Twiddle address for second set
        u_in <= "000100000000" & "000010000000" & "000001000000" & "000000000000"; -- 4x u_in
        v_in <= "000110000000" & "000100000000" & "000011000000" & "000010000000"; -- 4x v_in
        wait for 90 ns;

        -- Verify outputs (example assertions, expected values need updating based on logic)
        assert u_out(11 downto 0) = "000010000000" report "Test 1 failed for u_out[0]" severity error;
        assert v_out(11 downto 0) = "110011000001" report "Test 1 failed for v_out[0]" severity error;

        assert u_out(23 downto 12) = "000100000000" report "Test 1 failed for u_out[1]" severity error;
        assert v_out(23 downto 12) = "110001000001" report "Test 1 failed for v_out[1]" severity error;

        assert u_out(35 downto 24) = "000110000000" report "Test 1 failed for u_out[2]" severity error;
        assert v_out(35 downto 24) = "110011000001" report "Test 1 failed for v_out[2]" severity error;

        assert u_out(47 downto 36) = "010010000000" report "Test 1 failed for u_out[3]" severity error;
        assert v_out(47 downto 36) = "110001000001" report "Test 1 failed for v_out[3]" severity error;

        -- Apply reset
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 10 ns;
        
        -- Test 2: u +/- vw mode (mode = '0')
        mode <= '0';
        wait for 40 ns;
        tw_addr_0 <= "0000001"; -- Twiddle address for first set
        tw_addr_1 <= "0000001"; -- Twiddle address for second set
        u_in <= "000000001000" & "000000000100" & "000000000010" & "000000000000"; -- 4x u_in
        v_in <= "000010001000" & "000010000100" & "000010000010" & "000010000000"; -- 4x v_in
        wait for 20 ns;

        assert u_out(11 downto 0) = "000010000000" report "Test 1 failed for u_out[0]" severity error; -- 1598
        assert v_out(11 downto 0) = "110011000001" report "Test 1 failed for v_out[0]" severity error; -- 1731

        assert u_out(23 downto 12) = "011011000001" report "Test 1 failed for u_out[1]" severity error; -- 1729
        assert v_out(23 downto 12) = "011001000100" report "Test 1 failed for v_out[1]" severity error; -- 1604

        assert u_out(35 downto 24) = "011101000100" report "Test 1 failed for u_out[2]" severity error; -- 1860
        assert v_out(35 downto 24) = "010111000101" report "Test 1 failed for v_out[2]" severity error; -- 1477

        assert u_out(47 downto 36) = "011111001001" report "Test 1 failed for u_out[3]" severity error; -- 1993
        assert v_out(47 downto 36) = "010101001000" report "Test 1 failed for v_out[3]" severity error; -- 1352

        -- End simulation
        wait;
    end process;

end architecture testbench;
