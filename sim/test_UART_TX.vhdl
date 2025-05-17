-- filepath: d:/University/Semester_07/FYP/Kyber-PMC-Core/sim/test_UART_TX.vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_UART_TX is
end test_UART_TX;

architecture Behavioral of test_UART_TX is

  -- Constants for simulation
  constant CLK_FREQ   : integer := 100_000_000; -- 100 MHz
  constant BAUD_RATE  : integer := 5000000; -- Standard UART baud rate
  constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;

  -- DUT signals
  signal clk       : std_logic                    := '0';
  signal rst       : std_logic                    := '0';
  signal data_in   : std_logic_vector(7 downto 0) := (others => '0');
  signal data_send : std_logic                    := '0';
  signal tx        : std_logic;
  signal busy      : std_logic;

  -- Clock period
  constant CLK_PERIOD : time := 10 ns; -- 100 MHz

begin

  -- Instantiate the UART transmitter
  uut : entity work.uart_tx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map
    (
      clk       => clk,
      rst       => rst,
      data_in   => data_in,
      data_send => data_send,
      tx        => tx,
      busy      => busy
    );

  -- Clock generation
  clk_process : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- Stimulus process
  stim_proc : process
  begin
    -- Reset
    rst <= '1';
    wait for 50 ns;
    rst <= '0';
    wait for 50 ns;

    -- Send first byte
    data_in   <= x"55"; -- 0b01010101
    data_send <= '1';
    wait for CLK_PERIOD;
    data_send <= '0';

    -- Wait for transmission to complete
    wait until busy = '0';
    wait for 100 ns;

    -- Send second byte
    data_in   <= x"A3"; -- 0b10100011
    data_send <= '1';
    wait for CLK_PERIOD;
    data_send <= '0';

    -- Wait for transmission to complete
    wait until busy = '0';
    wait for 100 ns;

    -- Send third byte
    data_in   <= x"FF";
    data_send <= '1';
    wait for CLK_PERIOD;
    data_send <= '0';

    -- Wait for transmission to complete
    wait until busy = '0';
    wait for 200 ns;

    -- End simulation
    wait;
  end process;

end Behavioral;