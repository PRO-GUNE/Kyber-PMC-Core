-- Testbench for serial_buf_tx

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity test_SERIAL_BUF_TX is
end test_SERIAL_BUF_TX;

architecture tb of test_SERIAL_BUF_TX is

  -- Component Declaration
  component serial_buf_tx
    port (
      clk        : in std_logic;
      rst        : in std_logic;
      busy       : in std_logic;
      data_in    : in std_logic_vector(23 downto 0);
      data_valid : in std_logic;
      data_send  : out std_logic;
      data_out   : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Signals for DUT
  signal clk        : std_logic                     := '0';
  signal rst        : std_logic                     := '0';
  signal busy       : std_logic                     := '0';
  signal data_in    : std_logic_vector(23 downto 0) := (others => '0');
  signal data_valid : std_logic                     := '0';
  signal data_send  : std_logic;
  signal data_out   : std_logic_vector(7 downto 0);

  -- Clock period
  constant clk_period : time := 10 ns;

begin

  -- Instantiate DUT
  uut : serial_buf_tx
  port map
  (
    clk        => clk,
    rst        => rst,
    busy       => busy,
    data_in    => data_in,
    data_valid => data_valid,
    data_send  => data_send,
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
  stim_proc : process
  begin
    -- Reset
    rst <= '1';
    wait for 2 * clk_period;
    rst <= '0';
    wait for clk_period;

    -- Send first data word
    data_in    <= x"123456";
    data_valid <= '1';
    wait for clk_period;
    data_valid <= '0';
    wait for clk_period;

    -- Simulate busy low (ready to transmit)
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;

    -- Wait for transmission to complete
    wait for 5 * clk_period;

    -- Send second data word
    data_in    <= x"ABCDEF";
    data_valid <= '1';
    wait for clk_period;
    data_valid <= '0';
    wait for clk_period;

    -- Simulate busy low (ready to transmit)
    -- Simulate busy low (ready to transmit)
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;
    busy <= '1';
    wait for 5 * clk_period;
    busy <= '0';
    wait for clk_period;

    -- Wait for transmission to complete
    wait for 5 * clk_period;

    -- End simulation
    wait;
  end process;

end tb;