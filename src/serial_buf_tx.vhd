library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity uart_tx_buffer is
  generic (
    CLK_FREQ  : integer := 100_000_000; -- Default 100 MHz
    BAUD_RATE : integer := 115_200      -- Default baud rate
  );
  port (
    clk        : in std_logic;
    rst        : in std_logic;
    busy       : in std_logic;                     -- Busy signal from uart_tx
    data_in_0  : in std_logic_vector(23 downto 0); -- First 24-bit input
    data_in_1  : in std_logic_vector(23 downto 0); -- Second 24-bit input
    data_in_2  : in std_logic_vector(23 downto 0); -- Third 24-bit input
    data_in_3  : in std_logic_vector(23 downto 0); -- Fourth 24-bit input
    data_valid : in std_logic;                     -- Signal to latch input data
    data_send  : out std_logic;                    -- Signal to start uart_tx transmission
    data_out   : out std_logic_vector(7 downto 0)  -- Byte to transmit
  );
end uart_tx_buffer;

architecture Behavioral of uart_tx_buffer is
  -- Internal buffer to store 4 * 24 bits = 96 bits (12 bytes)
  signal buff : std_logic_vector(95 downto 0) := (others => '0');

  -- State machine states
  type state_type is (IDLE, LOAD_BUFFER, SEND_BYTE, WAIT_BUSY);
  signal state : state_type := IDLE;

  -- Internal signals
  signal byte_counter : integer range 0 to 11 := 0; -- Tracks current byte index
  signal data_send_int : std_logic := '0';         -- Internal data_send signal

begin
  -- Output assignments
  data_send <= data_send_int;

  -- Process to manage buffer loading and byte transmission
  process (clk, rst)
  begin
    if rst = '1' then
      state         <= IDLE;
      byte_counter  <= 0;
      data_send_int <= '0';
      data_out      <= (others => '0');
      buff          <= (others => '0');
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          data_send_int <= '0';
          byte_counter  <= 0;

          if data_valid = '1' then
            state <= LOAD_BUFFER;
          end if;

        when LOAD_BUFFER =>
          -- Load the four 24-bit inputs into the buffer
          buff(23 downto 0)   <= data_in_0; -- Bytes 0-2
          buff(47 downto 24)  <= data_in_1; -- Bytes 3-5
          buff(71 downto 48)  <= data_in_2; -- Bytes 6-8
          buff(95 downto 72)  <= data_in_3; -- Bytes 9-11
          state <= SEND_BYTE;

        when SEND_BYTE =>
          -- Output the current byte (LSB first within each 24-bit value)
          data_out      <= buff((byte_counter + 1) * 8 - 1 downto byte_counter * 8);
          data_send_int <= '1'; -- Trigger transmission
          state         <= WAIT_BUSY;

        when WAIT_BUSY =>
          data_send_int <= '0'; -- Clear data_send after one cycle

          if busy = '0' then -- Wait until uart_tx is not busy
            if byte_counter = 11 then
              state <= IDLE; -- All bytes sent
            else
              byte_counter <= byte_counter + 1;
              state        <= SEND_BYTE; -- Send next byte
            end if;
          end if;
      end case;
    end if;
  end process;

end Behavioral;