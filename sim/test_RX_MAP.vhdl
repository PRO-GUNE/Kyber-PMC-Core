library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_RX_MAP is
-- Testbench has no ports
end test_RX_MAP;

architecture Behavioral of test_RX_MAP is

    -- Component declaration for the Unit Under Test (UUT)
    component RX_MAP
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
            data_valid: in  STD_LOGIC;
            data_out0 : out STD_LOGIC_VECTOR(23 downto 0);
            data_out1 : out STD_LOGIC_VECTOR(23 downto 0);
            data_out2 : out STD_LOGIC_VECTOR(23 downto 0);
            data_out3 : out STD_LOGIC_VECTOR(23 downto 0);
            ready     : out STD_LOGIC
        );
    end component;

    -- Signals to connect to the UUT
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '0';
    signal data_in   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_valid: STD_LOGIC := '0';
    signal data_out0 : STD_LOGIC_VECTOR(23 downto 0);
    signal data_out1 : STD_LOGIC_VECTOR(23 downto 0);
    signal data_out2 : STD_LOGIC_VECTOR(23 downto 0);
    signal data_out3 : STD_LOGIC_VECTOR(23 downto 0);
    signal ready     : STD_LOGIC;

    -- Clock generation
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: RX_MAP
        Port map (
            clk       => clk,
            reset     => reset,
            data_in   => data_in,
            data_valid=> data_valid,
            data_out0 => data_out0,
            data_out1 => data_out1,
            data_out2 => data_out2,
            data_out3 => data_out3,
            ready     => ready
        );

    -- Clock process
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;
    
    -- Stimulus process
    stimulus_process : process
    begin
        -- Test case 1: Reset the system
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Test case 2: Feed 12 bytes of data
        for i in 0 to 11 loop
            data_in <= std_logic_vector(to_unsigned(i, 8));
            data_valid <= '1';
            wait for clk_period;
        end loop;
        data_valid <= '0';
        wait for clk_period;

        -- Wait for ready signal
        wait until ready = '1';
        assert data_out0 = "0000000100000010" & "00000011" report "Test case 2 failed: data_out0 mismatch" severity error;
        assert data_out1 = "00000100" & "00000101" & "00000110" report "Test case 2 failed: data_out1 mismatch" severity error;
        assert data_out2 = "00000111" & "00001000" & "00001001" report "Test case 2 failed: data_out2 mismatch" severity error;
        assert data_out3 = "00001010" & "00001011" & "00001100" report "Test case 2 failed: data_out3 mismatch" severity error;

        -- Test case 3: Check behavior with no data_valid
        wait for 20 ns;
        assert ready = '0' report "Test case 3 failed: ready signal should be '0'" severity error;

        -- Test case 4: Reset during operation
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;
        assert ready = '0' report "Test case 4 failed: ready signal should be '0' after reset" severity error;

        -- End simulation
        wait;
    end process;

end Behavioral;