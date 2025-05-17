library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_TX_MAP is
-- Testbench has no ports
end test_TX_MAP;

architecture Behavioral of test_TX_MAP is

    -- Component declaration for the Unit Under Test (UUT)
    component TX_MAP
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            data_in0   : in  STD_LOGIC_VECTOR(23 downto 0);
            data_in1   : in  STD_LOGIC_VECTOR(23 downto 0);
            data_in2   : in  STD_LOGIC_VECTOR(23 downto 0);
            data_in3   : in  STD_LOGIC_VECTOR(23 downto 0);
            data_valid : in  STD_LOGIC;
            data_out   : out STD_LOGIC_VECTOR(7 downto 0);
            ready      : out STD_LOGIC
        );
    end component;

    -- Signals for connecting to the UUT
    signal clk        : STD_LOGIC := '0';
    signal reset      : STD_LOGIC := '0';
    signal data_in0   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal data_in1   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal data_in2   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal data_in3   : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
    signal data_valid : STD_LOGIC := '0';
    signal data_out   : STD_LOGIC_VECTOR(7 downto 0);
    signal ready      : STD_LOGIC;

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: TX_MAP
        Port map (
            clk        => clk,
            reset      => reset,
            data_in0   => data_in0,
            data_in1   => data_in1,
            data_in2   => data_in2,
            data_in3   => data_in3,
            data_valid => data_valid,
            data_out   => data_out,
            ready      => ready
        );

    -- Clock generation process
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Test Case 1: Reset the system
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;

        -- Test Case 2: Send valid data and check output
        data_in0 <= x"123456";
        data_in1 <= x"789ABC";
        data_in2 <= x"DEF012";
        data_in3 <= x"345678";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';

        -- Wait for all data to be transmitted
        wait for clk_period * 12;

        -- Test Case 3: Check ready signal when idle
        assert ready = '1' report "Ready signal failed when idle" severity error;

        -- Test Case 4: Send another set of data
        data_in0 <= x"ABCDEF";
        data_in1 <= x"123456";
        data_in2 <= x"789ABC";
        data_in3 <= x"DEF012";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';

        -- Wait for all data to be transmitted
        wait for clk_period * 12;

        -- Test Case 5: Reset during transmission
        data_in0 <= x"111111";
        data_in1 <= x"222222";
        data_in2 <= x"333333";
        data_in3 <= x"444444";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period * 5;
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';

        -- Wait for a few clock cycles
        wait for clk_period * 10;

        -- End simulation
        wait;
    end process;

end Behavioral;