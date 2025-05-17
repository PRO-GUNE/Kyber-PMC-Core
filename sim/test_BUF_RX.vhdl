-- Testbench for serial_buf_rx

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_BUF_RX is
end test_BUF_RX;

architecture tb of test_BUF_RX is

    -- Component Declaration
    component serial_buf_rx
        Port (
            clk        : in std_logic;
            rst        : in std_logic;
            data_in    : in std_logic_vector(7 downto 0);
            data_valid : in std_logic;
            buf_full   : out std_logic;
            data_out   : out std_logic_vector(23 downto 0)
        );
    end component;

    -- Signals for DUT
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal data_in    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid : std_logic := '0';
    signal buf_full   : std_logic;
    signal data_out   : std_logic_vector(23 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: serial_buf_rx
        port map (
            clk        => clk,
            rst        => rst,
            data_in    => data_in,
            data_valid => data_valid,
            buf_full   => buf_full,
            data_out   => data_out
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;

        -- Send first byte
        data_in    <= x"AA";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period;

        -- Send second byte
        data_in    <= x"BB";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period;

        -- Send third byte (should trigger buf_full and data_out)
        data_in    <= x"CC";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period;

        -- Wait and observe outputs
        wait for 3*clk_period;

        -- Send another set
        data_in    <= x"11";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period;

        data_in    <= x"22";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for clk_period;

        data_in    <= x"33";
        data_valid <= '1';
        wait for clk_period;
        data_valid <= '0';
        wait for 3*clk_period;

        -- End simulation
        wait;
    end process;

end tb;