-- filepath: d:/University/Semester_07/FYP/Kyber-PMC-Core/src/TEST_BUFF_UART.vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TEST_BUFF_UART is
  generic (
    CLK_FREQ  : integer := 100000000; -- System clock frequency (e.g., 100 MHz)
    BAUD_RATE : integer := 5000000 -- UART baud rate
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    rx  : in std_logic; -- UART receive line
    tx  : out std_logic; -- UART transmit line
    SW  : in std_logic_vector(15 downto 0); -- Switch input for testing
    LED : out std_logic_vector(7 downto 0) -- LED output for debugging
  );
end TEST_BUFF_UART;

architecture Behavioral of TEST_BUFF_UART is
  -- Signals for RX_MAP
  signal rx_data_out0 : std_logic_vector(23 downto 0);
  signal rx_data_out1 : std_logic_vector(23 downto 0);
  signal rx_data_out2 : std_logic_vector(23 downto 0);
  signal rx_data_out3 : std_logic_vector(23 downto 0);
  signal rx_ready     : std_logic;

  signal sw_data   : std_logic_vector(23 downto 0);
  signal ram_ready : std_logic;
  signal ram_valid : std_logic;

  -- Signals for TX_MAP
  signal tx_data_out : std_logic_vector(7 downto 0);
  signal tx_ready    : std_logic;

  -- Signals for UART RX and TX
  signal uart_rx_data  : std_logic_vector(7 downto 0);
  signal uart_rx_valid : std_logic;
  signal uart_tx_busy  : std_logic;
  signal uart_tx_send  : std_logic;

  -- Internal control signals
  signal tx_map_ready : std_logic;
  signal tx_map_valid : std_logic;
begin
  -- UART Receiver
  uart_rx_inst : entity work.uart_rx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map
    (
      clk        => clk,
      rst        => rst,
      rx         => rx,
      data_out   => uart_rx_data,
      data_valid => uart_rx_valid
    );

  -- RX_MAP to convert UART data to 24-bit words
  rx_map_inst : entity work.RX_MAP
    port map
    (
      clk        => clk,
      reset      => rst,
      data_in    => uart_rx_data,
      data_valid => uart_rx_valid,
      data_out0  => rx_data_out0,
      data_out1  => rx_data_out1,
      data_out2  => rx_data_out2,
      data_out3  => rx_data_out3,
      ready      => rx_ready
    );

  -- TX_MAP to convert 24-bit words to UART data
  tx_map_inst : entity work.TX_MAP
    port map
    (
      clk        => clk,
      reset      => rst,
      data_in0   => sw_data, -- Placeholder for actual data
      data_in1 => (others => '0'), -- Placeholder for additional data
      data_in2 => (others => '0'),
      data_in3 => (others => '0'),
      data_valid => ram_valid,
      data_out   => tx_data_out,
      ready      => ram_ready
    );

  -- UART Transmitter
  uart_tx_inst : entity work.uart_tx
    generic map(
      CLK_FREQ  => CLK_FREQ,
      BAUD_RATE => BAUD_RATE
    )
    port map
    (
      clk       => clk,
      rst       => rst,
      data_in   => tx_data_out,
      data_send => tx_map_valid,
      tx        => tx,
      busy      => uart_tx_busy
    );

  -- Control logic for TX_MAP and UART TX
  tx_map_valid <= tx_map_ready and not uart_tx_busy;

  -- LED output logic
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        led <= (others => '0');
      elsif uart_rx_valid = '1' then
        led <= uart_rx_data; -- Output received data to LEDs
      end if;
    end if;
  end process;

  sw_data <= "00000000" & SW(15 downto 0); -- Extend to 24 bits 

end Behavioral;