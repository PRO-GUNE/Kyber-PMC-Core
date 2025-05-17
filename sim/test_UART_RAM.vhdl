library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity test_UART_RAM is
  -- Testbench has no ports
end test_UART_RAM;

architecture Behavioral of test_UART_RAM is
  -- Component declaration for the Unit Under Test (UUT)
  component UART_RAM
    generic (
      CLK_FREQ  : integer := 100_000_000; -- 100 MHz clock
      BAUD_RATE : integer := 115200 -- UART baud rate
    );
    port (
      clk         : in std_logic;
      rst         : in std_logic;
      rx          : in std_logic; -- UART RX line
      tx          : out std_logic; -- UART TX line
      deb_wr_out  : out std_logic_vector(23 downto 0);
      deb_rd_out  : out std_logic_vector(23 downto 0);
      deb_wr_done : out std_logic
    );
  end component;

  -- Signals for driving the UUT
  signal clk         : std_logic := '0';
  signal rst         : std_logic := '0';
  signal rx          : std_logic := '1'; -- Idle state for UART RX
  signal tx          : std_logic;
  signal deb_wr_out  : std_logic_vector(23 downto 0);
  signal deb_rd_out  : std_logic_vector(23 downto 0);
  signal deb_wr_done : std_logic;

  -- Clock period constant
  constant CLK_PERIOD : time := 10 ns;

begin
  -- Instantiate the Unit Under Test (UUT)
  uut : UART_RAM
  generic map(
    CLK_FREQ  => 100_000_000,
    BAUD_RATE => 115200
  )
  port map
  (
    clk         => clk,
    rst         => rst,
    rx          => rx,
    tx          => tx,
    deb_wr_out  => deb_wr_out,
    deb_rd_out  => deb_rd_out,
    deb_wr_done => deb_wr_done
  );

  -- Clock generation process
  clk_process : process
  begin
    clk <= not clk;
    wait for CLK_PERIOD / 2;
  end process;

  -- Stimulus process
  stimulus_process : process
  begin
    -- Reset the UUT
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait for 20 ns;
    -- Simulate UART RX data reception
    -- Send 12 bytes of data via UART RX
    for i in 0 to 11 loop
      -- Start bit (logic '0')
      rx <= '0';
      wait for 1 sec / 115200;

      -- Send 8 data bits (example: 0x41 for ASCII 'A')
      for bit_index in 0 to 7 loop
        rx <= to_unsigned(i, 8)(bit_index);
        wait for 1 sec / 115200;
      end loop;

      -- Stop bit (logic '1')
      rx <= '1';
      wait for 1 sec / 115200;
    end loop;

    -- Wait for some time to observe the behavior
    wait for 1 ms;

    -- End simulation
    wait;
  end process;

end Behavioral;